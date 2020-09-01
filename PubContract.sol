// contracts/PubContract.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract PubContract is Initializable {


    //Roles.Role private _entity; //Hub Service Providers
    mapping(address => bytes) internal entitlements;
    mapping(string => bytes) internal identities;
    // code ==> encrypted identity with user's own keys(offline encryption)

    address private selfId; //Self ID of the contract extracted by web3 or salting.
    address private owner; //Blockchain address of the owner
    //bytes32 private pubId; //Public Key
    event IdentityExchanged(address indexed account);
    event ServiceRequested(address indexed account, address _subId);

    fallback() external payable { }

    function initialize(address _selfId, bytes memory _name) external initializer {
        selfId = _selfId;
        owner = msg.sender;
        identities["NAME"] = _name;//_name can be encrypted
    }

    function addi(string memory code, bytes memory identity) external  { // Ensure unique entitlement
        //Add - Unique
        require(owner == msg.sender);
        identities[code] = identity;
    }

    function remi(string memory code) external { // Remove existing identity
        //Remove
        require(owner == msg.sender);
        delete identities[code];
    }

    function tmi(
      bytes memory privateId,
      bytes32  _salt,
      address  mainId,
      address  _subId,
      address recipient
    ) external  { // Transmit Identity
        //Remove
        require(owner == msg.sender);
        new Identityxch{salt: _salt}(mainId, _subId, recipient, privateId);
        emit IdentityExchanged(recipient);
    }

    function alli(string memory code) external  returns ( bytes memory) { //get an identity
        //read all entitlements
        return identities[code];
    }

    /* Entitlements
      add - Add Entitlement (address, entitlement)

      rem - Remove Entitlement  (address, entitlement)

      req - Request Service

      all - View all entitlements

    */
    function adde(address hubid, bytes memory entitlement) external { // Ensure unique entitlement
        //Add - Unique
        require(owner == msg.sender);
        //require(entitlements[hubid] != entitlement);
        require(keccak256(entitlements[hubid]) != keccak256(entitlement) );
        entitlements[hubid] = entitlement;
    }

    function reme(address hubid, bytes memory entitlement) external { // Remove existing entitlement
        //Remove
        require(owner == msg.sender);
        //require(entitlements[hubid] == entitlement);
        require(keccak256(entitlements[hubid]) == keccak256(entitlement) );
        delete entitlements[hubid];
    }

    function reqe(bytes32  _salt, address  _subId, address hubid, bytes memory request) external { // Request entitlement service
        //request service
        require(owner == msg.sender);
        new Servicereqs{salt: _salt}(hubid, _subId, entitlements[hubid], request);
        emit ServiceRequested(hubid, _subId);
    }

    function alle(address account) external returns(bytes memory){//get  entitlements
        //read all entitlements
        return entitlements[account];
    }

}


//Identity Exchange Contract
contract Identityxch {
    address payable owner;
    address private mainId;
    address private selfId;
    address private recipient;
    bytes private pvtIdentity;
    bool private complete;

    constructor(address _mainId, address _selfId, address _recipient, bytes memory _pvtIdentity) public payable {
        owner = msg.sender;
        mainId = _mainId; //Main ID of contract
        selfId = _selfId; //Self ID of contract
        recipient = _recipient;
        pvtIdentity = _pvtIdentity;
        //send();
        //require(success, "Transfer failed.");
    }

    fallback() external payable {  }

    function ack() external { //Acknowledge
        require(owner == msg.sender || recipient == msg.sender);
        complete = true;
    }

    function end() external {
        require(owner == msg.sender || recipient == msg.sender);
        selfdestruct(owner);
    }
}


//Service Request Contract for Entitlements
contract Servicereqs {
    address payable owner;
    address private provider;
    address private selfId;
    bytes private entitlement;
    bytes private request;
    bool private complete;
    uint256 private bidc;//bidcount - How many bids will be provided for this
    uint256 private bidCount;//bidcount - How many bids will be provided for this
    mapping(uint256 => address) internal bids;// Micro-bids for this service

    constructor(address _provider, address _selfId, bytes memory _entitlement, bytes memory _request) public payable {
        owner = msg.sender;
        provider = _provider;
        selfId = _selfId;
        entitlement = _entitlement;
        request = _request;
        //send();
        //require(success, "Transfer failed.");
    }

    fallback() external payable {}

    function ack(uint256 countofbids) external { //Acknowledge
        require(owner == msg.sender || provider == msg.sender);
        bidc = countofbids;
    }

    function serve(uint256 order, address contractreward) external {
        require(owner == msg.sender || provider == msg.sender);
        //if (bidc < bids.length) {
        bids[order] = contractreward;
        //}
        //if (bidc >= bids.length) {
        complete = true;
        //}
    }

    function end() external {
        require(owner == msg.sender || provider == msg.sender);
        //selfdestruct();
        selfdestruct(owner);
    }
}
