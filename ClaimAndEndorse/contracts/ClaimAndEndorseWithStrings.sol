pragma solidity ^0.4.2;

contract ClaimAndEndorseWithStrings {
 
 mapping (address => string) nameOf;
    mapping (string => address) addressOf;
    
    function registerName(string name) {
        nameOf[msg.sender] = name;
        addressOf[name] = msg.sender;
    }

 
 
 struct ENDORSEMENT {
  uint creationTime;
 }
 
 struct CLAIM {
  uint creationTime;
  string fact;
  mapping (bytes32 => ENDORSEMENT) endorsements;
 }
 
 mapping (bytes32 => mapping (bytes32 /* CLAIM GUID */ => CLAIM)) claims;
 
 function setClaim(string claimGuid, string fact) {
  CLAIM c = claims[sha3(nameOf[msg.sender])][sha3(claimGuid)];
  if(bytes(c.fact).length > 0) throw; // unset first!
  c.creationTime = now;
  c.fact = fact;
 }
 
 function unsetClaim(string claimGuid) {
  delete claims[sha3(nameOf[msg.sender])][sha3(claimGuid)];
 }
 
 function setEndorsement(string claimer, string claimGuid, string fact) {
  CLAIM c = claims[sha3(claimer)][sha3(claimGuid)];
  if(sha3(c.fact) != sha3(fact)) throw;
  
  ENDORSEMENT e = c.endorsements[sha3(nameOf[msg.sender])];
  e.creationTime = now;
 }
 
 function unsetEndorsement(string claimer, string claimGuid) {
  delete claims[sha3(claimer)][sha3(claimGuid)].endorsements[sha3(nameOf[msg.sender])];
 }
 
 function getClaim(string claimer, string claimGuid) returns (string) {
     return claims[sha3(claimer)][sha3(claimGuid)].fact;
 }
 
 function checkClaim(
  string claimer, string claimGuid, string expectedFact
 ) constant returns (bool) {
  return sha3(claims[sha3(claimer)][sha3(claimGuid)].fact) == sha3(expectedFact);
 }
 
 function checkEndorsement(
  string claimer, string claimGuid, string endorsedBy
 ) constant returns (bool) {
  return claims[sha3(claimer)][sha3(claimGuid)]
         .endorsements[sha3(endorsedBy)].creationTime > 0;
 }
 
 function checkClaimAndEndorsement(
  string claimer, string endorsedBy, string claimGuid, string fact
 ) constant returns (bool) {
  CLAIM c = claims[sha3(claimer)][sha3(claimGuid)];
  return sha3(c.fact) == sha3(fact) 
            && c.endorsements[sha3(endorsedBy)].creationTime > 0;
 }
 
}
