/**
 * The Xmas Token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 * Santa Claus doesn't kepp any shares and all tokens not being sold during the crowdsale (but the 
 * reserved gift shares) are burned by the elves.
 * 
 * Author: Christmas Elf
 * Audit: Rudolf the red nose Reindear
 */

pragma solidity ^0.4.15;

/**
 * Defines functions that provide safe mathematical operations.
 */
contract SafeMath {
	
	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	
	function safeDiv(uint a, uint b) internal returns (uint) {
		assert(b > 0); 
		uint c = a / b;
		assert(a == b * c + a % b);
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
 * Implementation of Xmas Token contract.
 */
contract XmasToken is SafeMath {
	
	// Xmas token basic data
	string constant public standard = "ERC20";
	string constant public symbol = "xmas";
	string constant public name = "XmasToken";
	uint256 constant public decimals = 18;
	
	// Xmas token distribution
	uint256 constant public totalSupply = 4000000 * (10 ** decimals);
	uint256 constant public tokensForIco = 3000000 * (10 ** decimals);
	uint256 constant public tokensForBonus = 1000000 * (10 ** decimals);
	
	uint256 public tokensSold;
	
	/** 
	 * Starting with this time tokens may be transfered.
	 */
	uint public startTransferTime;
	
	/** 
	 * Starting with this time tokens may be transfered.
	 */
	uint public airdropTime;
	
	/**
	 * true if tokens have been burned
	 */
	bool burned;
	
	/**
	 * true if the bonus tokens have been sent to Santa's gift list.
	 */
	bool bonusSent;

	/**
	 * address that stores the initial supply of tokens.
	 */
	address public owner;
	
	/**
	 * address of the ico contract.
	 */
	address public icoAddress;

	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;
	address[] public santaGiftList;
	
	// public events on the blockchain that will notify listeners
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed _owner, address indexed spender, uint value);
	event Burn(uint amount);

	/** 
	 * Initializes contract with initial supply tokens to the creator of the contract 
	 * @param _owner the address which initially stores total supply of tokens.
	 * @param _startTransferTime starting with this time the tokens become transferable.
	 */
	function XmasToken(address _owner, uint _startTransferTime, uint _airdropTime) {
		owner = _owner;
		balanceOf[owner] = totalSupply;
		startTransferTime = _startTransferTime;
		airdropTime = _airdropTime;
	}

	/** 
	 * Sends the specified amount of tokens from msg.sender to a given address.
	 * @param _to the address to transfer to.
	 * @param _value the amount of tokens to be trasferred.
	 * @return true if the trasnfer is successful, false otherwise.
	 */
	function transfer(address _to, uint _value) returns(bool success) {
		require(now >= startTransferTime); 

		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); 
		balanceOf[_to] = safeAdd(balanceOf[_to], _value); 

		Transfer(msg.sender, _to, _value); 

		return true;
	}

	/** 
	 * Allows another contract or person to spend the specified amount of tokens on behalf of msg.sender.
	 * @param _spender the address which will spend the funds.
	 * @param _value the amount of tokens to be spent.
	 * @return true if the approval is successful, false otherwise.
	 */
	function approve(address _spender, uint _value) returns(bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));

		allowance[msg.sender][_spender] = _value;

		Approval(msg.sender, _spender, _value);

		return true;
	}

	/** 
	 * Transfers tokens from one address to another address.
	 * This is only allowed if the token holder approves. 
	 * @param _from the address from which the given _value will be transfer.
	 * @param _to the address to which the given _value will be transfered.
	 * @param _value the amount of tokens which will be transfered from one address to another.
	 * @return true if the transfer was successful, false otherwise. 
	 */
	function transferFrom(address _from, address _to, uint _value) returns(bool success) {
		if (now < startTransferTime) 
			require(_from == owner);
		var _allowance = allowance[_from][msg.sender];
		require(_value <= _allowance);
		
		balanceOf[_from] = safeSub(balanceOf[_from], _value); 
		balanceOf[_to] = safeAdd(balanceOf[_to], _value); 
		allowance[_from][msg.sender] = safeSub(_allowance, _value);

		Transfer(_from, _to, _value);

		return true;
	}
	
	/**
	 * Registers address to Santa's gift list.
	 * @param xmasHolder the address that will be added to santaGiftList.
	 */
	function registerToSantaGiftList(address xmasHolder) {
		require(msg.sender == icoAddress);
		
		santaGiftList[santaGiftList.length] = xmasHolder;
	}
	
	/**
	 * Sets the ico address and gives it allowance to spend the crowdsale tokens. Only callable once.
	 * @param _icoAddress the address of the ico contract.
	 */
	function setIcoAddress(address _icoAddress) {
		require(msg.sender == owner);
		
		icoAddress = _icoAddress;
		assert(approve(icoAddress, tokensForIco));
	}
	
	/**
	 * Sends the bonus tokens to addresses from Santa's list gift.
	 * @return true if the airdrop is successful, false otherwise.
	 */
	function airdrop() returns(bool success)  {
		require(msg.sender == owner);
		require(now >= airdropTime);
		
		uint bonusRate = safeDiv(tokensForBonus, tokensSold); 
		for(uint i = 0; i < santaGiftList.length; i++) {
			if (balanceOf[santaGiftList[i]] > 0) {
				uint bonus = safeMul(balanceOf[santaGiftList[i]], bonusRate);
				transferFrom(owner, santaGiftList[i], bonus);
			}
		}
		
		return true;
	}
	
	/** 
	 * Burns the remaining tokens except the gift share (1000000).
	 * To be called when ICO is closed. Anybody may burn the tokens after ICO ended, but only once.
	 */
	function burn() {
		if (!burned && now > startTransferTime) {
			uint difference = safeSub(balanceOf[owner], tokensForBonus);
			tokensSold = safeSub(tokensForIco, difference);
			balanceOf[owner] = tokensForBonus;
			
			burned = true;

			Burn(difference);
		}
	}
}
