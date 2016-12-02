pragma solidity ^0.4.2;

contract ClaimAndEndorseWithStringsV2 {
 
 mapping (address => string) nameOf;
 mapping (string => address) addressOf;
    
    
    /*
     * HELPER
     */
    function helperRegisterWalletAddressAlias(string name) {
        if(addressOf[name] != address(0)) {
            if(addressOf[name] == msg.sender) {
                // delete the old link
                delete addressOf[nameOf[msg.sender]];
            }
            else {
                // Die Adresse gehört jemand anders
                throw;
            }
        }
        
        // check address empty
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
 
 
 /*
  * PUBLIC INTERFACE
  */
  
  string constant GUID_FIRSTNAME = "FIRSTNAME";
  string constant GUID_SURENAME = "SURENAME";
  string constant GUID_IDNUMBER = "IDNUMBER";
 
 function claimIdentityData(string firstname, string surename, string idNumber) {
     _setClaim(GUID_FIRSTNAME, firstname);
     _setClaim(GUID_SURENAME, surename);
     _setClaim(GUID_IDNUMBER, idNumber);
 }
 
 function endorseIdentityData(string claimer, string firstname, string surename, string idNumber) {
     _setEndorsement(claimer, GUID_FIRSTNAME, firstname);
     _setEndorsement(claimer, GUID_SURENAME, surename);
     _setEndorsement(claimer, GUID_IDNUMBER, idNumber);
 }
 
 // BUG: endorsements werden nicht korrekt gelöscht, das Mapping bleibt erhalten
 function deleteIdentityClaim() {
     _unsetClaim(GUID_FIRSTNAME);
     _unsetClaim(GUID_SURENAME);
     _unsetClaim(GUID_IDNUMBER);
 }
 
 function deleteIdentityEndorsement(string claimer) {
     _unsetEndorsement(claimer, GUID_FIRSTNAME);
     _unsetEndorsement(claimer, GUID_SURENAME);
     _unsetEndorsement(claimer, GUID_IDNUMBER);
 }
 
 function getIdentityData(string claimer) constant returns (string, string, string) {
     return (   _getClaim(claimer, GUID_FIRSTNAME), 
                _getClaim(claimer, GUID_SURENAME), 
                _getClaim(claimer, GUID_IDNUMBER));
 }
 
 function checkIdentityData(string claimedBy, string endorsedBy, string expectedFirstname, string expectedSurename, string expectedIdNumber) constant returns (bool) {
    return
        _checkClaimAndEndorsement(claimedBy, endorsedBy, GUID_FIRSTNAME, expectedFirstname)
        && _checkClaimAndEndorsement(claimedBy, endorsedBy, GUID_SURENAME, expectedSurename)
        && _checkClaimAndEndorsement(claimedBy, endorsedBy, GUID_IDNUMBER, expectedIdNumber);
 }
 
 
 /*
  * INTERNAL
  */
 
 
 function _setClaim(string claimGuid, string fact) internal {
  CLAIM c = claims[sha3(nameOf[msg.sender])][sha3(claimGuid)];
  if(bytes(c.fact).length > 0) throw; // unset first!
  c.creationTime = now;
  c.fact = fact;
 }
 
 function _unsetClaim(string claimGuid) internal {
  delete claims[sha3(nameOf[msg.sender])][sha3(claimGuid)];
 }
 
 function _setEndorsement(string claimer, string claimGuid, string fact) internal {
  CLAIM c = claims[sha3(claimer)][sha3(claimGuid)];
  if(sha3(c.fact) != sha3(fact)) throw;
  
  ENDORSEMENT e = c.endorsements[sha3(nameOf[msg.sender])];
  e.creationTime = now;
 }
 
 function _unsetEndorsement(string claimer, string claimGuid) internal {
  delete claims[sha3(claimer)][sha3(claimGuid)].endorsements[sha3(nameOf[msg.sender])];
 }
 
 function _getClaim(string claimer, string claimGuid) internal constant returns (string) {
     return claims[sha3(claimer)][sha3(claimGuid)].fact;
 }
 
 function _checkClaim(
  string claimer, string claimGuid, string expectedFact
 ) internal constant returns (bool) {
  return sha3(claims[sha3(claimer)][sha3(claimGuid)].fact) == sha3(expectedFact);
 }
 
 function _checkEndorsement(
  string claimer, string claimGuid, string endorsedBy
 ) internal constant returns (bool) {
  return claims[sha3(claimer)][sha3(claimGuid)]
         .endorsements[sha3(endorsedBy)].creationTime > 0;
 }
 
 function _checkClaimAndEndorsement(
  string claimer, string endorsedBy, string claimGuid, string fact
 ) internal constant returns (bool) {
  CLAIM c = claims[sha3(claimer)][sha3(claimGuid)];
  return sha3(c.fact) == sha3(fact) 
            && c.endorsements[sha3(endorsedBy)].creationTime > 0;
 }
 
}
