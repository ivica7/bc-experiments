pragma solidity ^0.4.0;

import "./Asset.sol";
import "./CreditNetwork.sol";

contract AssetUSD is Asset("USD Asset", "USD", 2) {
}

contract AssetEUR is Asset("EUR Asset", "EUR", 2) {
}

contract CreditNetworkTest is CreditNetwork {
    function CreditNetworkTest() {
        address EUR = 0x1100000000000000000000000000000000000000;
        address USD = 0x1200000000000000000000000000000000000000;
        
        address JOHN = 0x0100000000000000000000000000000000000000;
        address ANDY = 0x0200000000000000000000000000000000000000;
        address ALEX = 0x0300000000000000000000000000000000000000;
        
        accounts[JOHN].assets[EUR].ious[ANDY].creditLine = 10000;
    }
}