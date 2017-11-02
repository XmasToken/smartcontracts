/**
 *  Crowdsale for Xmas Tokens.
 *  Author: Christmas Elf
 *  Audit: Rudolf the red nose Reindear
 **/

pragma solidity ^0.4.15;

/**
 * Defines the contract and functions of Xmas Token needed in Crowdsale contract. 
 */
interface Token {

	function transferFrom(address sender, address receiver, uint amount) returns(bool success);
	
	function registerToSantaGiftList(address xmasHolder);

	function burn();
}

/**
 * Defines functions that provide safe mathematical operations.
 */
contract SafeMath {

	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeSub(uint a, uint b) internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

}

/**
 * Defines the contract for managing Xmas Token crowdsale.
 */
contract Crowdsale is SafeMath {

	/**
	 * tokens will be transfered from this address 
	 */
	address public fundsWallet;
	
	/**
	 * the maximum amount of tokens to be sold 
	 */
	uint constant public maxTokenSupply = 3000000 * (10 ** uint256(18));

	/**
	 * how much has been raised by crowdale (in ETH) 
	 */
	uint public amountRaised;
	
	/**
	 * the start date of the crowdsale 
	 */
	uint constant public start = 1510401600;
	
	/**
	 * the end date of the crowdsale 
	 */
	uint constant public end = 1512820800;

	/**
	 * the number of tokens already sold 
	 */
	uint public tokensSold = 0;

	/**
	 * the price in ether of one token
	 */
	uint constant public price = 1000000000000000;

	/**
	 * the address of the token contract 
	 */
	Token public token;

	/**
	 * the balances (in ETH) of all investors 
	 */
	mapping(address => uint) public balanceOf;

	/**
	 * indicates if the crowdsale has been closed already 
	 */
	bool public crowdsaleClosed = false;

	/**
	 * the wallet on which the funds will be stored 
	 */
	address storageWallet;

	// public events on the blockchain that will notify listeners
	event GoalReached(address _fundsWallet, uint _amountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);

	/**
	 * Constructor function.
	 * Setup the owner. 
	 */
	function Crowdsale(
		address _tokenAddr, 
		address _storageWallet, 
		address _fundsWallet) {

		token = Token(_tokenAddr);
		storageWallet = _storageWallet;
		fundsWallet = _fundsWallet;
	}

	/**
	 * Default function called whenever anyone sends funds to this contract.
	 * Only callable if the crowdsale started and hasn't been closed already and the maxTokenSupply wasn't reached yet.
	 * The current token price is looked up and the corresponding number of tokens is transfered to the receiver.
	 * The sent value is directly forwarded to a safe wallet.
	 * This method allows to purchase tokens in behalf of another address.
	 */
	function() payable {
		token.registerToSantaGiftList(msg.sender);
			
		uint amount = msg.value;
		uint numTokens = amount / price; 
		require(numTokens>0);
		require(!crowdsaleClosed && now >= start && now <= end && safeAdd(tokensSold, numTokens) <= maxTokenSupply);

		storageWallet.transfer(amount);
		assert(token.transferFrom(fundsWallet, msg.sender, numTokens));

		// update status
		balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);
		amountRaised = safeAdd(amountRaised, amount);
		tokensSold += numTokens;

		FundTransfer(msg.sender, amount, true, amountRaised);
	}

	modifier afterDeadline() {
		if (now > end) 
			_;
	}

	/**
	 * Checks if the total amount of ico tokens have been sold or time limit has been reached and ends the campaign.
	 * Burns the unsold tokens, if any.
	 */
	function checkGoalReached() afterDeadline {
		require(msg.sender == fundsWallet);

		if (tokensSold >= maxTokenSupply) {
			GoalReached(fundsWallet, amountRaised);
		}

		token.burn(); 
		crowdsaleClosed = true;
	}
}
