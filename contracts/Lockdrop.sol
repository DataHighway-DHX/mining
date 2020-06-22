// Original Source: https://github.com/hicommonwealth/edgeware-lockdrop
pragma solidity >=0.5.16 <0.7.0;
// pragma experimental ABIEncoderV2;

// import "./lib/StandardToken.sol";
import "./interface/ERC20.sol";

/**
 * @title Lockdrop Wallet
 */
contract Lock {
    address public lockdropCreator;
    address public lockAddress;
    address public lockOwner;
    ERC20 token;
    address public tokenContractAddress;
    uint256 public lockContractCreatedAt; // when Lock contract was created
    uint256 public lockContractTokenCapacity;
    bytes public dataHighwayPublicKey;
    bool public isValidator;

    uint256 public lockContractDepositedLastAt;
    uint256 public lockContractBalance;
    uint256 public lockContractWithdrewLastAt;
    uint256 public unlockTime;

    modifier onlyOwner {
        require(msg.sender == lockOwner, "Sender must be contract owner");
        _;
    }

    constructor (
        address _lockdropCreator, address _owner, uint256 _unlockTime, uint256 _tokenERC20Amount, bytes memory _dataHighwayPublicKey,
        address _tokenContractAddress, bool _isValidator
    ) public {
        lockdropCreator = _lockdropCreator;
        lockOwner = _owner;
        lockContractCreatedAt = now;
        tokenContractAddress = _tokenContractAddress;
        token = ERC20(_tokenContractAddress);
        lockAddress = address(this);
        unlockTime = _unlockTime;
        lockContractTokenCapacity = _tokenERC20Amount;
        dataHighwayPublicKey = _dataHighwayPublicKey;
        isValidator = _isValidator;
        // Transfer the amount of ERC20 tokens to the Lockdrop Wallet of the owner
        // FIXME - returns `Error: Returned error: VM Exception while processing transaction: revert`
        // token.transfer(address(this), _tokenERC20Amount);
        // Try to send to itself
        // require(token.transferFrom(address(this), address(this), uint256(_tokenERC20Amount)) == true, "Could not send tokens");
        // // Ensure the Lockdrop Wallet contract has at least all the ERC20 tokens transferred, or fail
        // assert(token.balanceOf(address(this)) >= _tokenERC20Amount);

        emit Created(msg.sender, unlockTime, lockAddress, tokenContractAddress, lockContractTokenCapacity, dataHighwayPublicKey, isValidator, lockContractCreatedAt);
    }

    // Prior to executing this function ensure that you have called the `approve` function
    // of the ERC20 token stored in this Lock contract with at least the amount you wish to deposit (e.g. lockContractTokenCapacity).
    function depositTokens() public onlyOwner {
        require(now < unlockTime, "Deposit of tokens only allowed before the unlock timestamp");
        require(token.balanceOf(msg.sender) >= lockContractTokenCapacity, "Lock owner address must have at least the amount ERC20 tokens they want to deposit");
        require(token.transferFrom(msg.sender, address(this), lockContractTokenCapacity), "Unable to deposit ERC20 tokens from Lock owner to Lock contract");
        require(token.balanceOf(address(this)) == lockContractTokenCapacity, "Lock contract deposit of ERC20 tokens should equal the Lock contract ERC20 token capacity");
        lockContractBalance = token.balanceOf(address(this));
        lockContractDepositedLastAt = now;
        emit DepositedTokens(msg.sender, unlockTime, tokenContractAddress, lockContractTokenCapacity, lockContractBalance, dataHighwayPublicKey, isValidator, lockContractDepositedLastAt);
    }

    // // FIXME - unable to use since generates error `Error: Returned error: VM Exception while processing transaction: revert Fallback function prevented accidental sending of Ether to the contract -- Reason given: Fallback function prevented accidental sending of Ether to the contract.`
    // // Fallback function prevent accidental sending of Ether to the contract
    // function() external {
    //     revert("Fallback function prevented accidental sending of Ether to the contract");
    // }

    /**
     * @dev        Withdraw only tokens implementing ERC20 after unlock timestamp. Callable only by owner
     */
    function withdrawTokens() public onlyOwner {
        require(now >= unlockTime, "Withdrawal of tokens only allowed after the unlock timestamp");
        uint256 lockContractBalanceExisting = token.balanceOf(address(this));
        require(lockContractBalanceExisting > 0, "Lock address must have at least some ERC20 tokens to withdraw");
        // Send the token balance of the ERC20 contract
        require(token.transfer(msg.sender, lockContractBalance), "Unable to withdraw ERC20 tokens from Lock contract");
        lockContractBalance = token.balanceOf(address(this));
        require(lockContractBalance == 0, "Lock address should have been depleted of all ERC20 tokens after withdrawal");
        lockContractWithdrewLastAt = now;
        emit WithdrewTokens(msg.sender, unlockTime, tokenContractAddress, lockContractBalance, lockContractBalance, dataHighwayPublicKey, isValidator, lockContractWithdrewLastAt);
    }

    /**
     * @dev        Info returns Lock contract creator, address and owner, the ERC20 token address, timestamp of unlock time, Lock contract created timestamp,
     *             capacity of ERC20 tokens that may be locked, DataHighway public key, whether user wants to be a validator on the DataHighway, and when
     *             the Lock contract was created, and the timestamp of when the last deposit and withdrawal occured.
     */
   function info() public view returns(address, address, address, address, uint256, uint256, bytes memory, bool, uint256, uint256, uint256) {
        uint256 tokenBalance = token.balanceOf(address(this));
        return (lockdropCreator, lockAddress, lockOwner, tokenContractAddress, unlockTime, lockContractTokenCapacity,
            dataHighwayPublicKey, isValidator, lockContractCreatedAt, lockContractDepositedLastAt, lockContractWithdrewLastAt);
    }

    event Created(address sender, uint256 unlockTime, address lockAddress, address tokenContractAddress, uint256 lockContractTokenCapacity, bytes dataHighwayPublicKey, bool isValidator, uint256 lockContractCreatedAt);
    event DepositedTokens(address sender, uint256 unlockTime, address tokenContractAddress, uint256 lockContractTokenCapacity, uint256 lockContractBalance, bytes dataHighwayPublicKey, bool isValidator, uint256 lockContractDepositedLastAt);
    event WithdrewTokens(address sender, uint256 unlockTime, address tokenContractAddress, uint256 lockContractWithdrewAmount, uint256 lockContractBalance, bytes dataHighwayPublicKey, bool isValidator, uint256 lockContractWithdrewLastAt);
}

/**
 * @title Lockdrop Wallet Factory
 */
contract Lockdrop {
    address public lockdropCreator;

    enum ClaimType { Lock, Signal }
    // 0: pending, 1: approved, 2: rejected
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

    // mapping owner to a mapping of tokenContractAddress and LockWalletStruct
    mapping(address => mapping(address => LockWalletStruct)) public lockWalletStructs;
    // Retrieve list of all lock wallet user addresses
    address[2][] public lockWallets;

    // mapping owner to a mapping of tokenContractAddress and SignalWalletStruct
    mapping(address => mapping(address => SignalWalletStruct)) public signalWalletStructs;

    modifier onlyLockdropCreator {
        require(msg.sender == lockdropCreator, "Sender must be lockdrop contract creator");
        _;
    }

    // Time constants
    uint256 constant public LOCK_DROP_PERIOD = 1 days * 92; // 3 months
    uint256 public LOCK_START_TIME;
    uint256 public LOCK_END_TIME;

    // MXCToken locking events
    event Locked(
        address indexed sender, address indexed owner, Term term, uint256 tokenERC20Amount, bytes dataHighwayPublicKey,
        address tokenContractAddress, Lock lockAddr, bool isValidator, uint time
    );
    event Signaled(address indexed sender, address indexed contractAddr, uint nonce, Term term, uint256 tokenERC20Amount,
        bytes dataHighwayPublicKey, address tokenContractAddress, uint time);
    event ClaimStatusUpdated(
        address user, ClaimType claimType, address tokenContractAddress, ClaimStatus claimStatus, uint256 approvedTokenERC20Amount, uint time
    );

    constructor(uint startTime) public {
        lockdropCreator = msg.sender;
        LOCK_START_TIME = startTime; // Unix epoch time
        LOCK_END_TIME = startTime + LOCK_DROP_PERIOD;
    }

    // // FIXME - unable to use since generates error `Error: Returned error: VM Exception while processing transaction: revert Fallback function prevented accidental sending of Ether to the contract -- Reason given: Fallback function prevented accidental sending of Ether to the contract.`
    // // Fallback function prevent accidental sending of Ether to the contract
    // function() external {
    //     revert("Fallback function prevented accidental sending of Ether to the contract");
    // }

    /**
     * @dev        Locks up the value sent to contract in a new Lock
     * @param      _owner        Owner of a Lock contract (differs from the Lockdrop contract creator)
     * @param      _term         The length of the lock up
     * @param      _dataHighwayPublicKey The bytes representation of the target DataHighway key
     * @param      _tokenERC20Amount The ERC20 token amount to be locked
     * @param      _tokenContractAddress The ERC20 token contract (MXCToken)
     * @param      _isValidator  Indicates if sender wishes to be a validator
     */
    function lock(
        address _owner, Term _term, uint256 _tokenERC20Amount, bytes calldata _dataHighwayPublicKey,
        address _tokenContractAddress, bool _isValidator
    )
        external
        didStart
        didNotEnd
        returns(address lockWallet)
    {
        // Since it is not a `payable` function it cannot receive Ether
        ERC20 token = ERC20(_tokenContractAddress);
        // Send the token balance of the ERC20 contract

        // FIXME - same issue as in `setClaimStatus` function, where value of `tokenBalance` is incorrect,
        // so the assertions don't work
        uint256 tokenBalance = token.balanceOf(_owner);
        // FIXME - returns error `Error: Returned error: VM Exception while processing transaction: invalid opcode`.
        // should this be `require` instead of `assert`?
        // require(tokenBalance > 0);
        // require(_tokenERC20Amount > 0);
        // require(_tokenERC20Amount <= tokenBalance);
        // TODO - consider replacing with uint48
        uint256 unlockTime = unlockTimeForTerm(_term);

        // Create MXC lock contract
        Lock _lockAddr = new Lock(lockdropCreator, _owner, unlockTime, _tokenERC20Amount, _dataHighwayPublicKey, _tokenContractAddress, _isValidator);

        lockWalletStructs[_owner][_tokenContractAddress] = LockWalletStruct(
            {
                claimStatus: ClaimStatus.Pending, // pending (default)
                approvedTokenERC20Amount: 0,
                term: _term,
                tokenERC20Amount: _tokenERC20Amount,
                dataHighwayPublicKey: _dataHighwayPublicKey,
                lockAddr: _lockAddr,
                isValidator: _isValidator,
                createdAt: now
            }
        );
        // FIXME - this doesn't work
        // // Add wallet to sender's wallets.
        // lockWallets[_owner][_tokenContractAddress].push(address(_lockAddr));

        emit Locked(
            msg.sender, _owner, _term, _tokenERC20Amount, _dataHighwayPublicKey, _tokenContractAddress, _lockAddr,
            _isValidator, now
        );
    }

    /**
     * @dev        Signals an address's balance decided after lock period
     * @param      _dataHighwayPublicKey   The bytes representation of the target DataHighway key
     */
    function signal(
        Term _term, uint256 _tokenERC20Amount,
        bytes calldata _dataHighwayPublicKey, address _tokenContractAddress
    )
        external
        didStart
        didNotEnd
    {
        address fakeContractAddr = address(0x0);
        uint32 fakeNonce = 0;
        signalWalletStructs[msg.sender][_tokenContractAddress] = SignalWalletStruct(
            {
                claimStatus: ClaimStatus.Pending, // pending (default)
                approvedTokenERC20Amount: 0,
                term: _term,
                tokenERC20Amount: _tokenERC20Amount,
                dataHighwayPublicKey: _dataHighwayPublicKey,
                contractAddr: fakeContractAddr, // only for signalFromContract
                nonce: fakeNonce, // only for signalFromContract
                createdAt: now
            }
        );

        emit Signaled(msg.sender, fakeContractAddr, fakeNonce, _term, _tokenERC20Amount, _dataHighwayPublicKey, _tokenContractAddress, now);
    }

    /**
     * @dev        Signals a contract's balance decided after lock period
     * @param      _contractAddr  The contract address from which to signal the balance of
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
                claimStatus: ClaimStatus.Pending, // pending (default)
                approvedTokenERC20Amount: 0,
                term: _term,
                tokenERC20Amount: _tokenERC20Amount,
                dataHighwayPublicKey: _dataHighwayPublicKey,
                contractAddr: _contractAddr, // only for signalFromContract
                nonce: _nonce, // only for signalFromContract
                createdAt: now
            }
        );

        emit Signaled(msg.sender, _contractAddr, _nonce, _term, _tokenERC20Amount, _dataHighwayPublicKey, _tokenContractAddress, now);
    }

    // // TODO - not required, can retrieve direct from mapping. See https://medium.com/coinmonks/solidity-tutorial-returning-structs-from-public-functions-e78e48efb378
    // // Retrieve lock wallet info for specific user address and token
    // function getLockWalletInfo(address _user, address _tokenContractAddress)
    //     public
    //     view
    //     returns(LockWalletStruct memory lockWalletStructs)
    // {
    //     return lockWalletStructs[_user][_tokenContractAddress];
    // }

    // // TODO - not required, can retrieve direct from mapping
    // // Retrieve signal info for specific user address and token
    // function getSignalWalletInfo(address _user, address _tokenContractAddress)
    //     public
    //     view
    //     returns(SignalWalletStruct memory signalWalletStructs)
    // {
    //     return signalWalletStructs[_user][_tokenContractAddress];
    // }

    // Set claim status and partially or fully approve claim. By lockdrop creator only
    function setClaimStatus(address _user, ClaimType _claimType, address _tokenContractAddress,
        ClaimStatus _claimStatus, uint256 _approvedTokenERC20Amount)
        public onlyLockdropCreator
    {
        ERC20 token = ERC20(_tokenContractAddress);
        // FIXME - when I run this in Remix, why is the value of `tokenBalance` here equal to the value of
        // `tokenERC20Amount` that provide to the `signal(..)` function (i.e. 100), instead of 2664965800 where
        // this user deployed the MXCToken contract???
        uint256 tokenBalance = token.balanceOf(_user);

        // Lock
        if(_claimType == ClaimType.Lock) {
            require(_approvedTokenERC20Amount <= tokenBalance,
                "Cannot approve lock value greater than token balance");
            require(signalWalletStructs[_user][_tokenContractAddress].approvedTokenERC20Amount < _approvedTokenERC20Amount,
                "Cannot set approved amount for lock that is greater that approved amount for signal");
            require(lockWalletStructs[_user][_tokenContractAddress].tokenERC20Amount >= _approvedTokenERC20Amount,
                "Cannot set approved amount for lock that is greater that locked amount");
            lockWalletStructs[_user][_tokenContractAddress].claimStatus = _claimStatus;
            lockWalletStructs[_user][_tokenContractAddress].approvedTokenERC20Amount = _approvedTokenERC20Amount;
        // Signal
        } else if(_claimType == ClaimType.Signal) {
            // FIXME - this doesn't work. If use account that deployed Lockdrop that has balance of 2664965800 MXC,
            // and I enter 2664965801 for `_approvedTokenERC20Amount`, this still runs without triggering the assertion
            require(_approvedTokenERC20Amount <= tokenBalance,
                "Cannot approve signal value greater than token balance");
            require(lockWalletStructs[_user][_tokenContractAddress].approvedTokenERC20Amount < _approvedTokenERC20Amount,
                "Cannot set approved amount for lock that is greater that approved amount for signal");
            require(signalWalletStructs[_user][_tokenContractAddress].tokenERC20Amount >= _approvedTokenERC20Amount,
                "Cannot set approved amount for signal that is greater that signaled amount");
            signalWalletStructs[_user][_tokenContractAddress].claimStatus = _claimStatus;
            signalWalletStructs[_user][_tokenContractAddress].approvedTokenERC20Amount = _approvedTokenERC20Amount;
            // FIXME - remove below line as was used for debugging to see what the value of `tokenBalance` is in the UI
            signalWalletStructs[_user][_tokenContractAddress].tokenERC20Amount = tokenBalance;
        }
        emit ClaimStatusUpdated(
            _user, _claimType, _tokenContractAddress, _claimStatus, _approvedTokenERC20Amount, now
        );
    }

    function unlockTimeForTerm(Term _term) internal view returns (uint256) {
        if (_term == Term.ThreeMo) return now + 92 days;
        if (_term == Term.SixMo) return now + 183 days;
        if (_term == Term.NineMo) return now + 275 days;
        if (_term == Term.TwelveMo) return now + 365 days;
        if (_term == Term.TwentyFourMo) return now + 730 days;
        if (_term == Term.ThirtySixMo) return now + 1095 days;

        revert("Unlock time for term provided is not supported");
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
}
