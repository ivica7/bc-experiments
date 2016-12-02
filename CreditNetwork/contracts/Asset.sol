pragma solidity ^0.4.0;

contract Asset {
    string public description;  // e.g.: this Asset representes EUR
    string public id;           // e.g.: EUR
    uint public decimalUnits;   // for making this a Token Interface later(?)
    
    mapping (address => bool) accepted;
    
    function Asset(string _description, string _id, uint _decimalUnits) {
        description = _description;
        id = _id;
        decimalUnits = _decimalUnits;
    }
    
    // agree on this asset
    function accept() {
        accepted[msg.sender] = true;
    }
    
    function reject() {
        delete accepted[msg.sender];
    }
    
    function isAcceptedBy(address a) public constant returns (bool) {
        return accepted[a];
    }
    
    function () {
        throw;
    }
}
