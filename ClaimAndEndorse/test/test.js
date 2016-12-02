var assert = require('assert');
var helper = require('ethereum-sandbox-helper');
var Workbench = require('ethereum-sandbox-workbench');

var workbench = new Workbench({
  contractsDirectory: 'contracts',
  solcVersion: '0.4.2',
  defaults: {
    from: '0xdedb49385ad5b94a16f236a6890cf9e0b1e30392'
  }
});

var john = '0xdedb49385ad5b94a16f236a6890cf9e0b1e30392';
var andy = '0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826';
var alex = '0x084f6a99003dae6d3906664fdbf43dd09930d0e3';

var contract;

workbench.startTesting('CreditNetwork', function(contracts) {
  it('Deploy AssetEUR', function() {
    return contracts.ClaimAndEndorse.new()
      .then(function(result) {
        if (result.address) {
          contract = result;
          //console.log("assetEur");
          //console.log(assetEur);
        }
        else throw new Error('Contract is not deployed');
        return true;
      });
  });
  
  it('claim', function() {
    return contract.setClaim(1000, 1)
      .then(function(txHash) {
        return workbench.waitForReceipt(txHash);
      })
      .then(function (receipt) {
        return true;
      });
  });

  it('endorse', function() {
    //workbench.defaults.from = andy;
    return contract.setEndorsement.sendTransaction(john, 1000, 1, {from: andy})
      .then(function(txHash) {
        return workbench.waitForReceipt(txHash);
      })
      .then(function (receipt) {
        return true;
      });
  });

  it('unsetClaim', function() {
    //workbench.defaults.from = andy;
    return contract.unsetClaim(1000)
      .then(function(txHash) {
        return workbench.waitForReceipt(txHash);
      })
      .then(function (receipt) {
        return true;
      });
  });
  
});
