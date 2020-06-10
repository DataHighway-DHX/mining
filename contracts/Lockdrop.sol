// Original Source: https://github.com/hicommonwealth/edgeware-lockdrop
pragma solidity >=0.5.16 <0.7.0;

import "./lib/StandardToken.sol";

/**
 * @title Lockdrop Wallet
 */
contract Lock {
    address public lockdropCreator;
    address public owner;
    uint256 public unlockTime;
    uint256 public createdAt;
    address public tokenContractAddress;

    modifier onlyOwner {
        require(msg.sender == owner, "Sender must be contract owner");
        _;
    }

    constructor (
        address _lockdropCreator, address _owner, uint256 _unlockTime, uint256 tokenERC20Amount, address _tokenContractAddress
    ) public {
        lockdropCreator = _lockdropCreator;
        owner = _owner;
        unlockTime = _unlockTime;
        createdAt = now;
        tokenContractAddress = _tokenContractAddress;

        StandardToken token = StandardToken(_tokenContractAddress);
        // Transfer the amount of ERC20 tokens to the Lockdrop Wallet of the owner
        // FIXME - returns `Error: Returned error: VM Exception while processing transaction: revert`
        // token.transfer(address(this), tokenERC20Amount);
        // // Ensure the Lockdrop Wallet contract has at least all the ERC20 tokens transferred, or fail
        // assert(token.balanceOf(address(this)) >= tokenERC20Amount);

        // emit Received(owner, tokenERC20Amount, _tokenContractAddress);
    }

    // // FIXME - unable to use since generates error `Error: Returned error: VM Exception while processing transaction: revert Fallback function prevented accidental sending of Ether to the contract -- Reason given: Fallback function prevented accidental sending of Ether to the contract.`
    // // Fallback function prevent accidental sending of Ether to the contract
    // function() external {
    //     revert("Fallback function prevented accidental sending of Ether to the contract");
    // }

    /**
     * @dev        Withdraw only tokens implementing ERC20 after unlock timestamp. Callable only by owner
     */
    function withdrawTokens(address _tokenContractAddress) public onlyOwner {
        require(now >= unlockTime, "Withdrawal of tokens only allowed after the unlock timestamp");
        StandardToken token = StandardToken(_tokenContractAddress);
        // FIXME - unable to use since generates error `Error: Returned error: VM Exception while processing transaction: revert`
        uint256 tokenBalance = token.balanceOf(address(this));
        // // Send the token balance of the ERC20 contract
        // token.transfer(owner, tokenBalance);
        // emit WithdrewTokens(_tokenContractAddress, msg.sender, tokenBalance);
    }

    /**
     * @dev        Info returns owner, timestamp of unlock time, contract created timestamp,
     *             and locked MXCToken balance
     */
   function info() public view returns(address, address, uint256, uint256, uint256) {
        StandardToken token = StandardToken(address(this.tokenContractAddress));
        uint256 tokenBalance = token.balanceOf(address(this));
        return (lockdropCreator, owner, unlockTime, createdAt, tokenBalance);
    }

    event Received(address from, uint256 amount, address tokenContractAddress);
    // event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContractAddress, address to, uint256 amount);
}

/**
 * @title Lockdrop Wallet Factory
 */
contract Lockdrop {
    address public lockdropCreator;
    mapping(address => address[]) lockWallets;
    mapping(address => address[]) claimsLockedPending;
    mapping(address => address[]) claimsLockedApproved;
    mapping(address => address[]) claimsLockedRejected;
    mapping(address => address[]) claimsSignalledPending;
    mapping(address => address[]) claimsSignalledApproved;
    mapping(address => address[]) claimsSignalledRejected;

    modifier onlyLockdropCreator {
        require(msg.sender == lockdropCreator, "Sender must be lockdrop contract creator");
        _;
    }

    enum Term {
        ThreeMo,
        SixMo,
        NineMo,
        TwelveMo,
        TwentyFourMo,
        ThirtySixMo
    }
    // Time constants
    uint256 constant public LOCK_DROP_PERIOD = 1 days * 92; // 3 months
    uint256 public LOCK_START_TIME;
    uint256 public LOCK_END_TIME;
    // MXCToken locking events
    event Locked(
        address indexed owner, Term term, uint256 tokenERC20Amount, bytes dataHighwayPublicKey,
        address tokenContractAddress, Lock lockAddr, bool isValidator, uint time
    );
    event Signaled(address indexed lockdropCreator, address indexed contractAddr, Term term, uint256 tokenERC20Amount,
        bytes dataHighwayPublicKey, address tokenContractAddress, uint time);
    event ClaimLockedPending(
        address tokenContractAddress, Lock lockAddr, uint time
    );
    event ClaimLockedApproved(
        address tokenContractAddress, Lock lockAddr, Term term, uint256 tokenERC20Amount, bytes dataHighwayPublicKey, uint time
    );
    event ClaimLockedRejected(
        address tokenContractAddress, Lock lockAddr, uint time
    );
    event ClaimSignalledPending(
        address tokenContractAddress, Lock lockAddr, uint time
    );
    event ClaimSignalledApproved(
        address tokenContractAddress, Lock lockAddr, Term term, uint256 tokenERC20Amount, bytes dataHighwayPublicKey, uint time
    );
    event ClaimSignalledRejected(
        address tokenContractAddress, Lock lockAddr, uint time
    );

    constructor(uint startTime) public {
        lockdropCreator = msg.sender;
        LOCK_START_TIME = startTime;
        LOCK_END_TIME = startTime + LOCK_DROP_PERIOD;
    }

    // // FIXME - unable to use since generates error `Error: Returned error: VM Exception while processing transaction: revert Fallback function prevented accidental sending of Ether to the contract -- Reason given: Fallback function prevented accidental sending of Ether to the contract.`
    // // Fallback function prevent accidental sending of Ether to the contract
    // function() external {
    //     revert("Fallback function prevented accidental sending of Ether to the contract");
    // }

    function getLockWallets(address user)
        public
        view
        returns(address[] memory)
    {
        return lockWallets[user];
    }

    /**
     * @dev        Locks up the value sent to contract in a new Lock
     * @param      owner        Owner of a Lock contract (differs from the Lockdrop contract creator)
     * @param      term         The length of the lock up
     * @param      dataHighwayPublicKey The bytes representation of the target DataHighway key
     * @param      tokenERC20Amount The ERC20 token amount to be locked
     * @param      _tokenContractAddress The ERC20 token contract (MXCToken)
     * @param      isValidator  Indicates if sender wishes to be a validator
     */
    function lock(
        address owner, Term term, uint256 tokenERC20Amount, bytes calldata dataHighwayPublicKey,
        address _tokenContractAddress, bool isValidator
    )
        external
        didStart
        didNotEnd
        returns(address lockWallet)
    {
        // Since it is not a `payable` function it cannot receive Ether
        StandardToken token = StandardToken(_tokenContractAddress);
        // Send the token balance of the ERC20 contract
        uint256 tokenBalance = token.balanceOf(owner);
        // FIXME - returns error `Error: Returned error: VM Exception while processing transaction: invalid opcode`.
        // should this be `require` instead of `assert`?
        // assert(tokenBalance > 0);
        // assert(tokenERC20Amount > 0);
        // assert(tokenERC20Amount <= tokenBalance);
        uint256 unlockTime = unlockTimeForTerm(term);

        // Create MXC lock contract
        Lock lockAddr = new Lock(lockdropCreator, owner, unlockTime, tokenERC20Amount, _tokenContractAddress);
        // Add wallet to sender's wallets.
        lockWallets[msg.sender].push(address(lockAddr));
        claimsLockedPending[msg.sender].push(address(lockAddr));
        emit Locked(
            lockdropCreator, owner, term, tokenERC20Amount, dataHighwayPublicKey, _tokenContractAddress, lockAddr,
            isValidator, now
        );
        emit ClaimLockedPending(
            _tokenContractAddress, lockAddr, now
        );
    }

    /**
     * @dev        Signals a contract's (or address's) balance decided after lock period
     * @param      contractAddr  The contract address from which to signal the balance of
     * @param      nonce         The transaction nonce of the creator of the contract
     * @param      dataHighwayPublicKey   The bytes representation of the target DataHighway key
     */
    function signal(
        address contractAddr, uint32 nonce, Term term, uint256 tokenERC20Amount,
        bytes calldata dataHighwayPublicKey, address _tokenContractAddress
    )
        external
        didStart
        didNotEnd
        didCreate(contractAddr, msg.sender, nonce)
    {
        // FIXME - is this enough info to store?
        claimsSignalledPending[msg.sender].push(address(contractAddr));
        emit Signaled(lockdropCreator, contractAddr, term, tokenERC20Amount, dataHighwayPublicKey, _tokenContractAddress, now);
        emit ClaimSignalledPending(
            _tokenContractAddress, contractAddr, term, tokenERC20Amount, dataHighwayPublicKey, now
        );
    }

    function getClaimsLockedPending(address user)
        public
        view
        returns(address[] memory)
    {
        return claimsLockedPending[user];
    }

    function getClaimsLockedApproved(address user)
        public
        view
        returns(address[] memory)
    {
        return claimsLockedApproved[user];
    }

    function getClaimsLockedRejected(address user)
        public
        view
        returns(address[] memory)
    {
        return claimsLockedRejected[user];
    }

    function getClaimsSignalledPending(address user)
        public
        view
        returns(address[] memory)
    {
        return claimsSignalledPending[user];
    }

    function getClaimsSignalledApproved(address user)
        public
        view
        returns(address[] memory)
    {
        return claimsSignalledApproved[user];
    }

    function getClaimsSignalledRejected(address user)
        public
        view
        returns(address[] memory)
    {
        return claimsSignalledRejected[user];
    }

    // FIXME - initially we will only approve or reject. later we will partially approve
    function claimLockedApproved(address _tokenContractAddress, Lock lockAddr, Term term,
        uint256 tokenERC20Amount, bytes calldata dataHighwayPublicKey)
        public onlyLockdropCreator
    {
        uint256 unlockTime = unlockTimeForTerm(term);
        // FIXME - do we need to store the _tokenContractAddress as well as the lockAddr
        // in claimsLockedApproved to allow for tokens stored on MXC and IOTA-E ERC20 tokens?
        // FIXME - how do we store unlockTime as the value of `claimsLockedApproved` too?
        claimsLockedApproved[msg.sender].push(address(lockAddr));
        emit ClaimLockedApproved(
            _tokenContractAddress, lockAddr, term, tokenERC20Amount, dataHighwayPublicKey, now
        );
    }

    function claimLockedRejected(address _tokenContractAddress, Lock lockAddr)
        public onlyLockdropCreator
    {
        claimsLockedRejected[msg.sender].push(address(lockAddr));
        emit ClaimLockedRejected(
            _tokenContractAddress, lockAddr, now
        );
    }

    // FIXME - initially we will only approve or reject. later we will partially approve
    function claimSignalledApproved(address _tokenContractAddress, address contractAddr,
        Term term, uint256 tokenERC20Amount, bytes calldata dataHighwayPublicKey)
        public onlyLockdropCreator
    {
        uint256 unlockTime = unlockTimeForTerm(term);
        // FIXME - do we need to store the _tokenContractAddress as well as the lockAddr
        // in claimsLockedApproved to allow for tokens stored on MXC and IOTA-E ERC20 tokens?
        // FIXME - how do we store unlockTime as the value of `claimsLockedApproved` too?

        // FIXME - is this enough info to store?
        claimsSignalledApproved[msg.sender].push(address(contractAddr));
        emit ClaimSignalledApproved(
            _tokenContractAddress, contractAddr, term, tokenERC20Amount, dataHighwayPublicKey, now
        );
    }

    function claimSignalledRejected(address _tokenContractAddress, address contractAddr)
        public onlyLockdropCreator
    {
        claimsSignalledRejected[msg.sender].push(address(contractAddr));
        emit ClaimSignalledRejected(
            _tokenContractAddress, contractAddr, now
        );
    }

    function unlockTimeForTerm(Term term) internal view returns (uint256) {
        if (term == Term.ThreeMo) return now + 92 days;
        if (term == Term.SixMo) return now + 183 days;
        if (term == Term.NineMo) return now + 275 days;
        if (term == Term.TwelveMo) return now + 365 days;
        if (term == Term.TwentyFourMo) return now + 730 days;
        if (term == Term.ThirtySixMo) return now + 1095 days;

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
     * @param      target  The target contract address (or trivially the parent)
     * @param      parent  The creator of the alleged contract address
     * @param      nonce   The creator's tx nonce at the time of the contract creation
     */
    modifier didCreate(address target, address parent, uint32 nonce) {
        // Trivially let senders "create" themselves
        if (target == parent) {
            _;
        } else {
            require(target == addressFrom(parent, nonce), "Target address must be created by a parent at some nonce");
            _;
        }
    }
}
