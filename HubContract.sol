// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;


//import "@openzeppelin/contracts/GSN/GSNRecipientERC20Fee.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
//import "@openzeppelin/contracts/access/Roles.sol";


contract HubContract is Initializable {
    address private mainContract;
    address private admin;
    bytes32 private encrypted; //If blank, all will be encryoted
    bytes32 private plaintext; //If blank, all will be encrypted

    mapping(address => bool) private _admins;
    //mapping Admin[] public _admins;

    mapping(address => bool) private _providers;
    //Providers are marked from their IAM to service contract.
    //Provider's KPI are managed here.

    event ProviderAdded(address indexed account);
    event ProviderRemoved(address indexed account);
    event OfferRolled(address indexed account, address offer);
    event BidAwarded(address indexed account, address microbid, address account2);
    event BidSubmitted(address indexed account, address microbid);

    function initialize(address _master) public initializer {
        //admin = _admin;//address _admin
        mainContract = _master;
        admin = msg.sender;
        _admins[msg.sender] = true;
        _addProvider(msg.sender);
    }

    /*
    function io(uint256 typex,


        bytes memory bidrequest, //can contain bid or request
        address microbid,
        address provider,
        bytes32 _salt
    ) public {
        if (typex == 1) {
            _offer(_salt, microbid, bidrequest);
        }
        if (typex == 2) {
            _award(microbid, provider);
        }
        if (typex == 3) {
            _bid(microbid, provider, bidrequest);
        }
    }
    */

    fallback() external payable {  }

    function offer(bytes32 _salt, address microbid, bytes memory bidrequest ) public {
        _offer(_salt, microbid, bidrequest);
    }

    function award(address microbid, address provider) public {
        _award(microbid, provider);
    }

    function bid(address microbid, address provider, bytes memory bidrequest) public {
        _bid(microbid, provider, bidrequest);
    }

    //Admin Public Function
    function isAdmin(address adminac) public view returns (bool) {
        return _admins[adminac];
    }

    function renounceAdmin(address account) public {
        require(_admins[msg.sender], "You must be admin");
        _removeAdmin(account);
    }

    function addAdmin(address account) public {
        require(_admins[msg.sender], "You must be admin");
        _addAdmin(account);
    }

    // Provider  Public Functions
    function isProvider(address account) public view returns (bool) {
        return _providers[account];
    }

    function renounceProvider(address spoke) public {
        require(_admins[msg.sender], "You must be admin");
        _removeProvider(spoke);
    }

    function addProvider(address spoke) public {
        require(_admins[msg.sender], "You must be admin");
        _addProvider(spoke);
    }

    //Admin Internal Function
    function _addAdmin(address account) internal {
        require(_admins[msg.sender], "You must be admin");
        require(account != address(0));
        //Admin memory admin = Admin(account, true);
        _admins[admin] = true;
    }

    function _removeAdmin  (address account) internal {
        require(_admins[msg.sender], "You must be admin");
        require(account != address(0));
        _admins[account] = false;
        delete _admins[account];
    }
    /*
    modifier onlyProvider() {
        require(isProvider(msg.sender));
        _;
    }*/

    //Provided Internal Function
    function _addProvider(address account) internal {
        require(_admins[msg.sender], "You must be admin");
        require(account != address(0));
        //Provider memory provider = Provider(account, true);
        _providers[account] = true;
        emit ProviderAdded(account);
    }

    function _removeProvider  (address account) internal {
        require(_admins[msg.sender], "You must be admin");
        require(account != address(0));
        _providers[account] = false;
        delete _providers[account];
        emit ProviderRemoved(account);
    }

    //Create a Micro-Offer to serve the end customer
    function _offer(
    bytes32 _salt,
    address microbid,
    bytes memory request
    ) internal {
        require(_admins[msg.sender], "You must be admin");
        new OfferContract{salt: _salt}(mainContract , microbid, request);
        emit OfferRolled(mainContract, microbid);
    }

    //Reward bid
    function _award(address microbid, address provider) internal {
        require(_admins[msg.sender], "You must be admin");
        // require(microbid.call(bytes4(keccak256("setaward(address)")), provider));
        OfferContract oc = OfferContract(microbid);
        // call method from other contract
        oc.setaward(provider);
        emit BidAwarded(mainContract, microbid, provider);
    }

    //Provider Side Function of Bidding
    function _bid(address microbid, address provider, bytes memory bid) internal {
        require(_providers[msg.sender], "You must be a provider");
        require(provider == msg.sender, "You must submit your own bids");
        //require(microbid.call(bytes4(keccak256("setbid(byte32)")), bid));
        OfferContract oc = OfferContract(microbid);
        // call method from other contract
        oc.setbid(provider, bid);
        emit BidSubmitted(mainContract, microbid);
    }

}


//Offer Contract for providers to send their bids -> Needs Access info of Admins & Providers from the HubContract
contract OfferContract {
    address payable owner;
    //address private recipient;
    address private mainId;
    address private selfId;
    //address private pvtIdentity;
    bytes private request;//Plaintext or Encrypted with Contract's key, so that only participating parties can read it
    //bytes private response;//Encrypted with Hub's Public key, so that only hub can read it
    address private winner;//Offchain Offerid
    //bytes private offernonce;//Offchain Offer Nonce //Comprissing of user id hash
    mapping(address => bytes) public responses;
    mapping(address => bool) public acks;

    constructor(
    address _mainId, //Address of Main Contract
    address _selfId, //Address of Sub Contract(This)
    bytes memory _request
    )public {
        owner = msg.sender;
        mainId = _mainId;
        selfId = _selfId;
        request = _request;
        //providers = _providers;
        //admins = _admins;
        //require(success, "Transfer failed.");
    }

    function ack(address account) public { //Acknowledge
        require(mainId == msg.sender, "Call from Contract Only");
        acks[account] = true;
    }

    function end() public {
        require(mainId == msg.sender, "Call from Contract Only");
        selfdestruct(owner);
    }

    function setaward(address account) public {
        require(mainId == msg.sender, "Call from Contract Only");
        winner = account;
    }

    function setbid(address account, bytes memory bid) public {
        require(mainId == msg.sender, "Call from Contract Only");
        responses[account] = bid;
    }
}
