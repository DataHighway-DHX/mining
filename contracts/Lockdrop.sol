pragma solidity >=0.5.16 <0.7.0;
// pragma experimental ABIEncoderV2;

import "./interface/ERC20.sol";

/**
 * @title           Lockdrop Wallet
 */
contract Lock {
    /* State */
    address public lockdropContractCreator;
    address public lockContractAddress;
    address public lockOwner;
    uint256 public lockContractTokenCapacity;
    ERC20 token;
    uint256 public lockContractTokenBalance;
    address public tokenContractAddress;
    uint256 public lockContractCreatedAt;
    uint256 public depositedLastAt;
    uint256 public withdrewLastAt;
    uint256 public unlockTime;
    bytes public dataHighwayPublicKey;
    bool public isValidator;

    /* Modifiers */
    modifier onlyOwner {
        require(msg.sender == lockOwner, "Sender must be contract owner");
        _;
    }

    /* Constructor */
    constructor (
        address _lockdropContractCreator, address _lockContractOwner, uint256 _unlockTime,
        uint256 _tokenERC20Amount, bytes memory _dataHighwayPublicKey,
        address _tokenContractAddress, bool _isValidator
    ) public {
        lockdropContractCreator = _lockdropContractCreator;
        lockOwner = _lockContractOwner;
        lockContractCreatedAt = now;
        tokenContractAddress = _tokenContractAddress;
        token = ERC20(_tokenContractAddress);
        lockContractAddress = address(this);
        unlockTime = _unlockTime;
        lockContractTokenCapacity = _tokenERC20Amount;
        dataHighwayPublicKey = _dataHighwayPublicKey;
        isValidator = _isValidator;

        emit Created(
            msg.sender, unlockTime, lockContractAddress, tokenContractAddress,
            lockContractTokenCapacity, dataHighwayPublicKey, isValidator,
            lockContractCreatedAt
        );
    }

    /* Fallback Function */

    function() external {
        revert("Fallback function prevented accidental sending of Ether to the contract");
    }

    /* Public Functions */

    /**
    * @notice       Prior to executing this function ensure that you have called the `approve` function of the
    *               ERC20 token that is stored in this Lock contract with at least the amount you wish to deposit.
    */
    function depositTokens() public onlyOwner {
        require(now < unlockTime,
            "Deposit tokens allowed only before the unlock timestamp");
        require(token.balanceOf(msg.sender) >= lockContractTokenCapacity,
            "Lock owner address must have the ERC20 tokens they want to deposit");
        require(token.transferFrom(msg.sender, address(this), lockContractTokenCapacity),
            "Unable to deposit ERC20 tokens from Lock contract owner to Lock contract");
        require(token.balanceOf(address(this)) == lockContractTokenCapacity,
            "Lock contract deposit of ERC20 tokens should equal the Lock contract ERC20 token capacity");

        lockContractTokenBalance = token.balanceOf(address(this));
        depositedLastAt = now;

        emit DepositedTokens(
            msg.sender, unlockTime, tokenContractAddress, lockContractTokenCapacity,
            lockContractTokenBalance, dataHighwayPublicKey, isValidator, depositedLastAt
        );
    }

    /**
     * @dev        Withdraw only tokens implementing ERC20 after unlock timestamp. Callable only by owner
     *             In development environment comment out the assertion that requires the current time to be
     *             the `unlockTime` or after it, or otherwise set the unlock time to match the time you
     *             created Lockdrop contract
     */
    function withdrawTokens() public onlyOwner {
        require(now >= unlockTime, "Withdrawal of tokens only allowed after the unlock timestamp");
        uint256 lockContractTokenBalanceExisting = token.balanceOf(address(this));
        require(lockContractTokenBalanceExisting > 0,
            "Lock address must have at least some ERC20 tokens to withdraw");
        require(token.transfer(msg.sender, lockContractTokenBalance),
            "Unable to withdraw ERC20 tokens from Lock contract");
        lockContractTokenBalance = token.balanceOf(address(this));
        require(lockContractTokenBalance == 0,
            "Lock address should have been depleted of all ERC20 tokens after withdrawal");
        withdrewLastAt = now;

        emit WithdrewTokens(
            msg.sender, unlockTime, tokenContractAddress, lockContractTokenBalance, lockContractTokenBalance,
            dataHighwayPublicKey, isValidator, withdrewLastAt
        );
    }

    /**
     * @dev        Info returns Lock contract creator, address and owner, the ERC20 token address, timestamp of unlock time, Lock contract created timestamp,
     *             capacity of ERC20 tokens that may be locked, DataHighway public key, whether user wants to be a validator on the DataHighway, and when
     *             the Lock contract was created, and the timestamp of when the last deposit and withdrawal occured.
     */
    function info() public view returns(
        address, address, address, address, uint256, uint256, bytes memory, bool, uint256, uint256, uint256
    ) {
        return (
            lockdropContractCreator, lockContractAddress, lockOwner, tokenContractAddress, unlockTime,
            lockContractTokenCapacity, dataHighwayPublicKey, isValidator, lockContractCreatedAt, depositedLastAt,
            withdrewLastAt
        );
    }

    /* Events */
    event Created(
        address sender, uint256 unlockTime, address lockContractAddress, address tokenContractAddress,
        uint256 lockContractTokenCapacity, bytes dataHighwayPublicKey, bool isValidator,
        uint256 lockContractCreatedAt
    );
    event DepositedTokens(
        address sender, uint256 unlockTime, address tokenContractAddress, uint256 lockContractTokenCapacity,
        uint256 lockContractTokenBalance, bytes dataHighwayPublicKey, bool isValidator, uint256 depositedLastAt
    );
    event WithdrewTokens(
        address sender, uint256 unlockTime, address tokenContractAddress, uint256 lockContractWithdrewAmount,
        uint256 lockContractTokenBalance, bytes dataHighwayPublicKey, bool isValidator, uint256 withdrewLastAt
    );
}

/**
 * @title           Lockdrop Wallet Factory
 */
contract Lockdrop {
    /* State */
    address public lockdropContractCreator;
    // Time constants
    uint256 constant public LOCK_DROP_PERIOD = 1 days * 92; // 3 months
    uint256 public LOCK_START_TIME;
    uint256 public LOCK_END_TIME;

    enum ClaimType { Lock, Signal }
    enum ClaimStatus { Pending, Approved, Rejected }
    enum Term { ThreeMo, SixMo, NineMo, TwelveMo, TwentyFourMo, ThirtySixMo }

    struct LockWalletStruct {
        ClaimStatus claimStatus;
        uint256 approvedTokenERC20Amount;
        Term term;
        uint256 tokenERC20Amount;
        bytes dataHighwayPublicKey;
        Lock lockAddr;
        bool isValidator;
        // TODO - replace all usage of `now` with type `uint48` since uses less memory
        uint256 createdAt;
    }

    struct SignalWalletStruct {
        ClaimStatus claimStatus;
        uint256 approvedTokenERC20Amount;
        Term term;
        uint256 tokenERC20Amount;
        bytes dataHighwayPublicKey;
        address contractAddr; // Signal "Contract" claim type only
        uint32 nonce; // Signal "Contract" claim type only
        uint256 createdAt;
    }

    // Map Lock owner to a mapping of tokenContractAddress and LockWalletStruct
    mapping(address => mapping(address => LockWalletStruct)) public lockWalletStructs;

    // Map Lock owner to a mapping of tokenContractAddress and SignalWalletStruct
    mapping(address => mapping(address => SignalWalletStruct)) public signalWalletStructs;

    /* Events */
    event Locked(
        address indexed sender, address indexed owner, Term term, uint256 tokenERC20Amount, bytes dataHighwayPublicKey,
        address tokenContractAddress, Lock lockAddr, bool isValidator, uint time
    );
    event Signaled(
        address indexed sender, address indexed contractAddr, uint nonce, Term term, uint256 tokenERC20Amount,
        bytes dataHighwayPublicKey, address tokenContractAddress, uint time
    );
    event ClaimStatusUpdated(
        address user, ClaimType claimType, address tokenContractAddress, ClaimStatus claimStatus,
        uint256 approvedTokenERC20Amount, uint time
    );

    /* Modifiers */

    modifier onlylockdropContractCreator() {
        require(msg.sender == lockdropContractCreator, "Sender must be lockdrop contract creator");
        _;
    }

    /**
     * @dev        Ensures the lockdrop has started
     */
    modifier didStart() {
        require(now >= LOCK_START_TIME, "Only callable after the lock start time");
        _;
    }

    /**
     * @dev        Ensures the lockdrop has not ended
     */
    modifier didNotEnd() {
        require(now <= LOCK_END_TIME, "Only callable before the lock end time");
        _;
    }

    /**
     * @dev        Ensures the target address was created by a parent at some nonce
     * @param      _target  The target contract address (or trivially the parent)
     * @param      _parent  The creator of the alleged contract address
     * @param      _nonce   The creator's tx nonce at the time of the contract creation
     */
    modifier didCreate(address _target, address _parent, uint32 _nonce) {
        // Trivially let senders "create" themselves
        if (_target == _parent) {
            _;
        } else {
            require(_target == addressFrom(_parent, _nonce), "Target address must be created by a parent at some nonce");
            _;
        }
    }

    /* Constructor */

    constructor(uint startTime) public {
        lockdropContractCreator = msg.sender;
        LOCK_START_TIME = startTime; // Unix epoch time
        LOCK_END_TIME = startTime + LOCK_DROP_PERIOD;
    }

    /* Fallback Function */

    function() external {
        revert("Fallback function prevented accidental sending of Ether to the contract");
    }

    /* External Functions */

    /**
     * @dev        Locks up the value sent to contract in a new Lock
     * @param      _lockContractOwner Owner of a Lock contract (differs from the Lockdrop contract creator)
     * @param      _term         The time period to lock ERC20 tokens in the Lock contract for. See unlockTimeForTerm.
     * @param      _dataHighwayPublicKey The bytes representation of the target DataHighway public key
     * @param      _tokenERC20Amount The ERC20 token amount to be locked. Check the ERC20 token's decimal places.
     * @param      _tokenContractAddress The contract address of ERC20 token to lock in Lock contract (e.g. MXCToken)
     * @param      _isValidator  Indicates if sender wishes to be a validator
     */
    function lock(
        address _lockContractOwner, Term _term, uint256 _tokenERC20Amount, bytes calldata _dataHighwayPublicKey,
        address _tokenContractAddress, bool _isValidator
    )
        external
        didStart
        didNotEnd
        returns(address)
    {
        ERC20 token = ERC20(_tokenContractAddress);
        uint256 senderTokenBalance = token.balanceOf(_lockContractOwner);
        require(_tokenERC20Amount > 0, "ERC20 tokens to be locked must be greater than zero");
        require(_tokenERC20Amount <= senderTokenBalance,
            "ERC20 token balance of Lock contract owner must be greater than tokens to lock");
        // TODO - consider replacing with uint48
        uint256 unlockTime = unlockTimeForTerm(_term);

        // Create Lock contract
        Lock _lockAddr = new Lock(
            lockdropContractCreator, _lockContractOwner, unlockTime, _tokenERC20Amount, _dataHighwayPublicKey,
            _tokenContractAddress, _isValidator
        );

        lockWalletStructs[_lockContractOwner][_tokenContractAddress] = LockWalletStruct(
            {
                // Set pending as default
                claimStatus: ClaimStatus.Pending,
                approvedTokenERC20Amount: 0,
                term: _term,
                tokenERC20Amount: _tokenERC20Amount,
                dataHighwayPublicKey: _dataHighwayPublicKey,
                lockAddr: _lockAddr,
                isValidator: _isValidator,
                createdAt: now
            }
        );

        emit Locked(
            msg.sender, _lockContractOwner, _term, _tokenERC20Amount, _dataHighwayPublicKey, _tokenContractAddress,
            _lockAddr, _isValidator, now
        );

        return address(_lockAddr);
    }

    /**
     * @dev        Signals an address's balance decided after lock period
     */
    function signal(
        Term _term, uint256 _tokenERC20Amount, bytes calldata _dataHighwayPublicKey, address _tokenContractAddress
    )
        external
        didStart
        didNotEnd
    {
        // Set fake data for properties that are only relevant for `signalFromContract` but not `signal` function
        address fakeContractAddr = address(0x0);
        uint32 fakeNonce = 0;
        signalWalletStructs[msg.sender][_tokenContractAddress] = SignalWalletStruct(
            {
                claimStatus: ClaimStatus.Pending,
                approvedTokenERC20Amount: 0,
                term: _term,
                tokenERC20Amount: _tokenERC20Amount,
                dataHighwayPublicKey: _dataHighwayPublicKey,
                contractAddr: fakeContractAddr,
                nonce: fakeNonce,
                createdAt: now
            }
        );

        emit Signaled(
            msg.sender, fakeContractAddr, fakeNonce, _term, _tokenERC20Amount, _dataHighwayPublicKey,
            _tokenContractAddress, now
        );
    }

    /**
     * @dev        Signals a contract's balance decided after lock period
     * @param      _contractAddr  The contract address from which to signal the balance
     * @param      _nonce         The transaction nonce of the creator of the contract
     * @param      _dataHighwayPublicKey   The bytes representation of the target DataHighway key
     */
    function signalFromContract(
        address _contractAddr, uint32 _nonce, Term _term, uint256 _tokenERC20Amount,
        bytes calldata _dataHighwayPublicKey, address _tokenContractAddress
    )
        external
        didStart
        didNotEnd
        didCreate(_contractAddr, msg.sender, _nonce)
    {
        signalWalletStructs[_contractAddr][_tokenContractAddress] = SignalWalletStruct(
            {
                claimStatus: ClaimStatus.Pending,
                approvedTokenERC20Amount: 0,
                term: _term,
                tokenERC20Amount: _tokenERC20Amount,
                dataHighwayPublicKey: _dataHighwayPublicKey,
                contractAddr: _contractAddr,
                nonce: _nonce,
                createdAt: now
            }
        );

        emit Signaled(
            msg.sender, _contractAddr, _nonce, _term, _tokenERC20Amount, _dataHighwayPublicKey,
            _tokenContractAddress, now
        );
    }

    /* Public Functions */

    /**
     * Set claim status and partially or fully approve claim. By Lockdrop contract creator only
     *
     * @notice      Allow the combined approved amount for lock and signal to be greater than the current
     *              user token balance since setting the claim status may occur after the term is finished when the
     *              user may have already moved the funds that they locked or signaled.
     */
    function setClaimStatus(address _user, ClaimType _claimType, address _tokenContractAddress,
        ClaimStatus _claimStatus, uint256 _approvedTokenERC20Amount
    )
        public onlylockdropContractCreator
    {
        ERC20 token = ERC20(_tokenContractAddress);
        require(_approvedTokenERC20Amount <= token.totalSupply(), "Cannot approve more than the total supply of the token");

        // Lock
        if (_claimType == ClaimType.Lock) {
            require(lockWalletStructs[_user][_tokenContractAddress].tokenERC20Amount >= _approvedTokenERC20Amount,
                "Cannot set approved amount for lock greater than user locked amount");
            lockWalletStructs[_user][_tokenContractAddress].claimStatus = _claimStatus;
            lockWalletStructs[_user][_tokenContractAddress].approvedTokenERC20Amount = _approvedTokenERC20Amount;
        // Signal
        } else if (_claimType == ClaimType.Signal) {
            require(signalWalletStructs[_user][_tokenContractAddress].tokenERC20Amount >= _approvedTokenERC20Amount,
                "Cannot set approved amount for signal greater than user signaled amount");
            signalWalletStructs[_user][_tokenContractAddress].claimStatus = _claimStatus;
            signalWalletStructs[_user][_tokenContractAddress].approvedTokenERC20Amount = _approvedTokenERC20Amount;
        }
        emit ClaimStatusUpdated(
            _user, _claimType, _tokenContractAddress, _claimStatus, _approvedTokenERC20Amount, now
        );
    }

    /**
     * @dev        Rebuilds the contract address from a normal address and transaction nonce
     * @param      _origin  The non-contract address derived from a user's public key
     * @param      _nonce   The transaction nonce from which to generate a contract address
     */
    function addressFrom(address _origin, uint32 _nonce) public pure returns (address) {
        if(_nonce == 0x00)     return address(uint160(uint256(
            keccak256(abi.encodePacked(byte(0xd6), byte(0x94), _origin, byte(0x80))))));
        if(_nonce <= 0x7f)     return address(uint160(uint256(
            keccak256(abi.encodePacked(byte(0xd6), byte(0x94), _origin, uint8(_nonce))))));
        if(_nonce <= 0xff)     return address(uint160(uint256(
            keccak256(abi.encodePacked(byte(0xd7), byte(0x94), _origin, byte(0x81), uint8(_nonce))))));
        if(_nonce <= 0xffff)   return address(uint160(uint256(
            keccak256(abi.encodePacked(byte(0xd8), byte(0x94), _origin, byte(0x82), uint16(_nonce))))));
        if(_nonce <= 0xffffff) return address(uint160(uint256(
            keccak256(abi.encodePacked(byte(0xd9), byte(0x94), _origin, byte(0x83), uint24(_nonce))))));
        return address(uint160(uint256(
            // more than 2^32 nonces not realistic
            keccak256(abi.encodePacked(byte(0xda), byte(0x94), _origin, byte(0x84), uint32(_nonce))))));
    }

    /* Internal Functions */

    function unlockTimeForTerm(Term _term) internal view returns (uint256) {
        if (_term == Term.ThreeMo) return now + 92 days;
        if (_term == Term.SixMo) return now + 183 days;
        if (_term == Term.NineMo) return now + 275 days;
        if (_term == Term.TwelveMo) return now + 365 days;
        if (_term == Term.TwentyFourMo) return now + 730 days;
        if (_term == Term.ThirtySixMo) return now + 1095 days;

        revert("Unlock time for term provided is not supported");
    }
}
