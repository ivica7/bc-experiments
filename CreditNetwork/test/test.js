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

var assetEur;
var assetUsd;
var creditNetwork;

workbench.startTesting('CreditNetwork', function(contracts) {
  it('Deploy AssetEUR', function() {
    return contracts.Asset.new("EUR Asset", "EUR", 2)
      .then(function(result) {
        if (result.address) {
          assetEur = result;
          //console.log("assetEur");
          //console.log(assetEur);
        }
        else throw new Error('Contract is not deployed');
        return true;
      });
  });
  
  it('Deploy AssetUSD', function() {
    return contracts.Asset.new("USD Asset", "USD", 2)
      .then(function(result) {
        if (result.address) assetUsd = result;
        else throw new Error('Contract is not deployed');
        return true;
      });
  });
  
  it('Deploy CreditNetwork', function() {
    return contracts.CreditNetwork.new()
      .then(function(result) {
        if (result.address) {
          creditNetwork = result;
          console.log(creditNetwork);
        }
        else throw new Error('Contract is not deployed');
        return true;
      });
  });

/*
  it('queryIOU', function() {
        console.log(creditNetwork.queryIOU(john, assetEur.address, andy));
        return true;
  });
*/
  it('IOU Andy--1000.00 EUR-->John', function() {
    return creditNetwork.creditorCreditLineOffer(andy, assetEur.address, 10000)
      .then(function(txHash) {
        return workbench.waitForReceipt(txHash);
      })
      .then(function (receipt) {
        console.log(receipt);
        var res = creditNetwork.queryIOU(john, assetEur.address, andy);
        console.log(res);

        return true;
      });
  });

  it('Andy accept offer', function() {
    //workbench.defaults.from = andy;
    return creditNetwork.debtorCreditLineAccept.sendTransaction(john, assetEur.address, {from: andy})
      .then(function(txHash) {
        return workbench.waitForReceipt(txHash);
      })
      .then(function (receipt) {
        console.log(receipt);
        var res = creditNetwork.queryIOU(john, assetEur.address, andy);
        console.log(res);

        assert.equal(res[2], true);

        return true;
      });
  });
  
});
