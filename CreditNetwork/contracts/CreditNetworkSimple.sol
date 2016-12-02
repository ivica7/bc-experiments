pragma solidity ^0.4.0;

/**
 * Simple Web Of Trust for IOUs
 */
contract CreditNetworkSimple {
    // IOU - I owe you
    struct IOU {
        uint amountOwed;    // current amount owed by the counterparty
        uint creditLine;    // max. amount that I trust the counterparty will pay back
    }
    
    mapping (address /* CREDITOR */ => mapping (address /* DEBTOR */ => IOU)) ious;
    mapping (address /* BEVOLLMÄCHTIGETER */ => mapping (address => bool)) allowances; 

	function setIOU(address debtor, uint creditLine) {
		ious[msg.sender][debtor].creditLine = creditLine;
	}

    function setAllowance(address allowedAddr, bool allowed) {
    	allowances[msg.sender][allowedAddr] = allowed;
    }
    
    /** Creditor receives an offchain payment from debtor, he confirms this with this call */
    function creditorOffchainPaymentReceived(address debtor, uint amount) {
        IOU iou = ious[msg.sender][debtor];
        assert(iou.amountOwed >= amount);
        iou.amountOwed -= amount;        
    }
    
    /** Creditor gives money offchain to debtor, debtor confirms this with this call */
    function debtorOffchainLoanReceived(address creditor, uint amount) {
        IOU iou = ious[creditor][msg.sender];
        assert(iou.creditLine > 0); 
        iou.amountOwed = safeAdd(iou.amountOwed, amount);
    }
    
    // @param chain - the chain depends on the web of  trust and is calculated off-chain [this(sender), ..., receiver]
    //                if correctly calculated the ious will be recalculated accordingly
    function transfer(address[] chain, uint amount) {
       assert(
           chain.length >= 2
           && (chain[0] == msg.sender || allowances[msg.sender][chain[0]])
           && amount > 0);

        for(uint i=1; i<chain.length; i++) {
            uint a = amount;
            
            ACCOUNT prev = accounts[chain[i-1]];
            ACCOUNT current = accounts[chain[i]];
            
            // assetFlow[i-1] -> Asset transfered from prev to current
            // assetFlow[i]   -> Asset transfered from current to next

            // money owed by current to previous
            IOU iouCurrentToPrev = ious[chain[i-1]][chain[i]];
            // money owed by previous to current
            IOU iouPrevToCurrent = ious[chain[i]][chain[i-1]];

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
            }

            // if not settled above, prev increases his debit at current
            if(a > 0) {
                uint newSum = safeAdd(iouPrevToCurrent.amountOwed, a);
                
                if(newSum <= iouPrevToCurrent.creditLine && iouPrevToCurrent.acceptedByDebtor) {
                    iouPrevToCurrent.amountOwed = newSum;
                }
                else {
                    throw;
                }
            }            
        }
    }

	function queryAllowance(address owner, address allowed) constant returns (bool) {
		return allowances[owner][allowed];
	}

    function queryIOUs(address a1, address a2) public constant returns (string, uint, uint, string, uint, uint) {
        IOU a1a2 = ious[a1][a2];
        IOU a2a1 = ious[a2][a1];

        return ("a2 owes a1", a1a2.amountOwed, a1a2.creditLine, "a1 owes a2", a2a1.amountOwed, a2a1.creditLine);
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