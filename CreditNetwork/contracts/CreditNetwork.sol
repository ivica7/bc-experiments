pragma solidity ^0.4.0;

import "./Asset.sol";

contract CreditNetwork {
    // IOU - I owe you
    struct IOU {
        bool acceptedByDebtor;  // debtor accepts the limit offer
        uint amountOwed;    // current amount owed by the counterparty
        uint creditLine;    // max. amount that I trust the counterparty will pay back
    }

    // XCHG - exchange offer
    struct XCHG {
        uint validUntil;          
        uint exchangeRateInMillionth;       // exchangeRate = exchangeRateInMillionth / 1000000
    }

    // a generic asset, could be a currency, but it could be also worktime or anything else 
    struct ASSET {
        // exchange offers (asset addr of Asset -> XCHG)
        mapping (address => XCHG) xchgs;
        // debitors
        mapping (address => IOU) ious;
    }

    // ACCOUNT
    struct ACCOUNT {
        uint etherAmount;
        // addr of an Asset contract to ASSET struct
        mapping (address => ASSET) assets;
    }
    
    mapping (address => ACCOUNT) accounts;


    event EventUpdateIOU(address lender, address debitor, address asset, uint newCurrent, uint newMax);
    event EventDeleteIOU(address lender, address debitor, address asset);
    event EventUpdateXCHG(address xchgAddr, Asset fromAsset, Asset toAsset, uint exchangeRateInMillionth, uint validUntil);
    event EventDeleteXCHG(address xchgAddr, Asset fromAsset, Asset toAsset);
    event EventExecuteXCHG(address xchgAddr, Asset fromAsset, Asset toAsset, uint exchangeRateInMillionth);

    function depositEther() payable {
        assert(msg.value > 0);
        ACCOUNT a = accounts[msg.sender];
        a.etherAmount = safeAdd(a.etherAmount, msg.value);
    }
    
    function withdrawEther(uint amount) {
        ACCOUNT a = accounts[msg.sender];
        assert(a.etherAmount >= amount);
        // TODO correct like this?? Who pays for Gas?
        if(msg.sender.send(amount)) {
            a.etherAmount -= amount;
        }
    }

    /** called by debtor to accept a credit line */
    function debtorCreditLineAccept(address creditor, address asset) {
        IOU iou = accounts[creditor].assets[asset].ious[msg.sender];        
        assert(iou.creditLine > 0);
        iou.acceptedByDebtor = true;
    }
    
    /** called by debtor to reject a credit line */
    function debtorCreditLineReject(address creditor, address asset) {
        IOU iou = accounts[creditor].assets[asset].ious[msg.sender];        
        assert(iou.acceptedByDebtor = true);
        iou.acceptedByDebtor = false;
    }
    
    /** called by creditor to offer a credit line to a debtor */
    function creditorCreditLineOffer(address debtor, address asset, uint creditLine) {
        IOU iou = accounts[msg.sender].assets[asset].ious[debtor];
        iou.creditLine = creditLine;
        EventUpdateIOU(msg.sender, debtor, asset, iou.amountOwed, creditLine);
    }
    
    /** called by creditor to revoke a credit line */
    function creditorCreditLineRevoke(address debtor, address asset, uint creditLine) {
        IOU iou = accounts[msg.sender].assets[asset].ious[debtor];
        assert(iou.creditLine > 0);
        iou.creditLine = creditLine;
    }
    
    /** Creditor receives an offchain payment from debtor, he confirms this with this call */
    function creditorOffchainPaymentReceived(address debtor, address asset, uint amount) {
        IOU iou = accounts[msg.sender].assets[asset].ious[debtor];
        assert(iou.amountOwed >= amount);
        iou.amountOwed -= amount;
        
        // cleanup
        if(iou.amountOwed == 0 && iou.creditLine == 0) {
            delete accounts[msg.sender].assets[asset].ious[debtor];
        }
    }
    
    /** Creditor gives money offchain to debtor, debtor confirms this with this call */
    function debtorOffchainLoanReceived(address creditor, address asset, uint amount) {
        IOU iou = accounts[creditor].assets[asset].ious[msg.sender];
        assert(iou.creditLine > 0); 
        iou.amountOwed = safeAdd(iou.amountOwed, amount);
        iou.acceptedByDebtor = true;
    }
    
    function xchgOfferPlace(Asset fromAsset, Asset toAsset, uint exchangeRateInMillionth, uint validUntil) {
        //assert(fromAsset.isAcceptedBy(msg.sender) && toAsset.isAcceptedBy(msg.sender));
        
        ACCOUNT a = accounts[msg.sender];
        
        XCHG xchg = a.assets[fromAsset].xchgs[toAsset];
        xchg.validUntil = validUntil;
        xchg.exchangeRateInMillionth = exchangeRateInMillionth;
        
        EventUpdateXCHG(msg.sender, fromAsset, toAsset, exchangeRateInMillionth, validUntil);
    }
    
    function xchgOfferRemove(Asset fromAsset, Asset toAsset) {
        delete accounts[msg.sender].assets[fromAsset].xchgs[toAsset];
        EventDeleteXCHG(msg.sender, fromAsset, toAsset);
    }

    // @param chain - the chain depends on the web of  trust and is calculated off-chain [this(sender), ..., receiver]
    //                if correctly calculated the ious will be recalculated accordingly
    // @param assetFlow - the assets transfered between nodes in the chain
    // @param expectedExchangeRateInMillionth - expected exchange rates every time assets are exchanged
    function transferAsset(address[] chain, Asset[] assetFlow, uint[] expectedExchangeRateInMillionth, uint amount) {
       assert(
           chain.length >= 2
           && chain[0] == msg.sender
           && amount > 0
           && chain.length == assetFlow.length + 1);

        uint expectedExchangeRateInMillionthCurrentIdx = 0; 
        
        for(uint i=1; i<chain.length; i++) {
            uint a = amount;
            
            ACCOUNT prev = accounts[chain[i-1]];
            ACCOUNT current = accounts[chain[i]];
            
            // assetFlow[i-1] -> Asset transfered from prev to current
            // assetFlow[i]   -> Asset transfered from current to next

            // money owed by current to previous
            IOU iouCurrentToPrev = prev.assets[assetFlow[i-1]].ious[chain[i]];
            // money owed by previous to current
            IOU iouPrevToCurrent = current.assets[assetFlow[i-1]].ious[chain[i-1]];

            // current owes money to previous -> settle
            if(iouCurrentToPrev.amountOwed > 0) {
                if(iouCurrentToPrev.amountOwed >= a) {
                    iouCurrentToPrev.amountOwed -= a;
                    a = 0;
                }
                else {
                    // the amount larger than current owes to previous
                    a -= iouCurrentToPrev.amountOwed;
                    iouCurrentToPrev.amountOwed = 0;
                }

                EventUpdateIOU(chain[i-1], chain[i], assetFlow[i-1], iouCurrentToPrev.amountOwed, iouCurrentToPrev.creditLine);
            }

            // if not settled above, prev increases his debit at current
            if(a > 0) {
                uint newSum = safeAdd(iouPrevToCurrent.amountOwed, a);
                
                if(newSum <= iouPrevToCurrent.creditLine && iouPrevToCurrent.acceptedByDebtor) {
                    iouPrevToCurrent.amountOwed = newSum;
                    
                    EventUpdateIOU(chain[i], chain[i-1], assetFlow[i-1], iouPrevToCurrent.amountOwed, iouPrevToCurrent.creditLine);
                }
                else {
                    throw;
                }
            }
            
            // handle FX, when there is a switch in the asset flow
			if(i < assetFlow.length && assetFlow[i-1] != assetFlow[i]) {
				// handle FX
				XCHG xchg = current.assets[assetFlow[i-1]].xchgs[assetFlow[i]];

                // check fxRate offer is still valid
                //assert(xchg.validUntil > now);
				
				// check exchangeRate didn't change meanwhile
				assert(
				    expectedExchangeRateInMillionthCurrentIdx < expectedExchangeRateInMillionth.length
				    && xchg.exchangeRateInMillionth == expectedExchangeRateInMillionth[expectedExchangeRateInMillionthCurrentIdx]);

                expectedExchangeRateInMillionthCurrentIdx++;

				amount = safeMul(amount, xchg.exchangeRateInMillionth) / 1000000;
				
				EventExecuteXCHG(chain[i], assetFlow[i-1], assetFlow[i], xchg.exchangeRateInMillionth);
			}
        }
    }

    function queryIOU(address creditor, Asset asset, address debtor) public constant returns (uint, uint, bool) {
        IOU iou = accounts[creditor].assets[asset].ious[debtor];

        return (iou.amountOwed, iou.creditLine, iou.acceptedByDebtor);
    }

    function queryXCHG(address fxAddr, Asset fromAsset, Asset toAsset) public constant returns (uint, uint) {
        XCHG xchg = accounts[fxAddr].assets[fromAsset].xchgs[toAsset];

        return (xchg.validUntil, xchg.exchangeRateInMillionth);
    }
    
    function queryEther(address account) public constant returns (uint) {
        ACCOUNT a = accounts[account];
        return a.etherAmount;
    }

    /*
     * HELPER
     */
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool cond) internal {
        if(!cond) throw;
    }

    function () {
        throw;
    }

}