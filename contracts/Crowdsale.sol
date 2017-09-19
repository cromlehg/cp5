pragma solidity ^0.4.13;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    
  event Pause();
  
  event Unpause();

  bool public paused = false;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
  
}

contract SGAToken is MintableToken {	
    
  string public constant name = "Instacoin";
   
  string public constant symbol = "SGA";
    
  uint32 public constant decimals = 18;

  bool public transferAllowed = false;

  modifier whenTransferAllowed() {
    require(transferAllowed || msg.sender == owner);
    _;
  }

  function allowTransfer() onlyOwner {
    transferAllowed = true;
  }

  function transfer(address _to, uint256 _value) whenTransferAllowed returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) whenTransferAllowed returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
    
}


contract PurchaseBonusCrowdsale is Pausable {

  using SafeMath for uint;

  struct Bonus {
    uint limit;
    uint bonus;
  }
 
  Bonus[] public bonuses;

  function bonusesCount() constant returns(uint) {
    return bonuses.length;
  }

  function addBonus(uint limit, uint bonus) onlyOwner {
    bonuses.push(Bonus(limit, bonus));
  }

  function removeBonus(uint8 number) onlyOwner {
    require(number < bonuses.length);
    Bonus storage bonus = bonuses[number];

    delete bonuses[number];

    for (uint i = number; i < bonuses.length - 1; i++) {
      bonuses[i] = bonuses[i+1];
    }

    bonuses.length--;
  }

  function changeBonus(uint8 number, uint limit, uint bonusValue) onlyOwner {
    require(number < bonuses.length);
    Bonus storage bonus = bonuses[number];

    bonus.limit = limit;
    bonus.bonus = bonusValue;
  }

  function insertBonus(uint8 numberAfter, uint limit, uint bonus) onlyOwner {
    require(numberAfter < bonuses.length);

    bonuses.length++;

    for (uint i = bonuses.length - 2; i > numberAfter; i--) {
      bonuses[i + 1] = bonuses[i];
    }

    bonuses[numberAfter + 1] = Bonus(limit, bonus);
  }

  function clearBonuses() onlyOwner {
    require(bonuses.length > 0);
    for (uint i = 0; i < bonuses.length; i++) {
      delete bonuses[i];
    }
    bonuses.length -= bonuses.length;
  }

  function getBonus(uint value) constant returns(uint) {
    uint targetBonus = 0;
    for (uint i = bonuses.length; i > 0; i--) {
      Bonus storage bonus = bonuses[i - 1];
      if (value < bonus.limit)
        return bonus.bonus;
      else
        targetBonus = bonus.bonus;
    }
    return targetBonus;
  }

}

contract Crowdsale is PurchaseBonusCrowdsale {

  uint public start;

  uint public period;

  uint public invested;

  uint public hardCap;

  address public multisigWallet;

  address public secondWallet;
  
  address public foundersTokensWallet;
  
  address public bountyTokensWallet;

  uint public secondWalletPercent;

  uint public foundersTokensPercent;
  
  uint public bountyTokensPercent;
 
  uint public price;

  uint public percentRate = 1000;

  SGAToken public token = new SGAToken();

  function Crowdsale() {
    period = 60;
    start = 1505998800;
    hardCap = 186000000000000000000000;
    foundersTokensPercent = 202;
    foundersTokensWallet = 0x839D81F27B870632428fab6ae9c5903936a4E5aE;
    multisigWallet = 0x0CeeD87a6b8ac86938B6c2d1a0fA2B2e9000Cf6c;
    secondWallet = 0x949e62320992D5BD123B4616d2E2769473101AbB;
    secondWalletPercent = 10;
    addBonus(1,5);
    addBonus(2,10);
    addBonus(3,15);
    addBonus(5,20);
    addBonus(7,25);
    addBonus(10,30);
    addBonus(15,35);
    addBonus(20,40);
    addBonus(50,45);
    addBonus(75,50);
    addBonus(100,55);
    addBonus(150,60);
    addBonus(200,70);
    addBonus(300,75);
    addBonus(500,80);
    addBonus(750,90);
    addBonus(1000,100);
    addBonus(1500,110);
    addBonus(2000,125);
    addBonus(3000,140);
  }

  modifier saleIsOn() {
    require(now >= start && now < lastSaleDate());
    _;
  }
  
  modifier isUnderHardCap() {
    require(invested <= hardCap);
    _;
  }
  
  function lastSaleDate() constant returns(uint) {
    return start + period * 1 days;
  }

  function setStart(uint newStart) onlyOwner {
    start = newStart;
  }

  function setHardcap(uint newHardcap) onlyOwner {
    hardCap = newHardcap;
  }

  function setPrice(uint newPrice) onlyOwner {
    price = newPrice;
  }

  function setFoundersTokensPercent(uint newFoundersTokensPercent) onlyOwner {
    foundersTokensPercent = newFoundersTokensPercent;
  }

  function setSecondWallet(address newSecondWallet) onlyOwner {
    secondWallet = newSecondWallet;
  }
  
  function setSecondWalletPercent(uint newSecondWalletPercent) onlyOwner {
    secondWalletPercent = newSecondWalletPercent;
  }

  function setBountyTokensPercent(uint newBountyTokensPercent) onlyOwner {
    bountyTokensPercent = newBountyTokensPercent;
  }
  
  function setMultisigWallet(address newMultisigWallet) onlyOwner {
    multisigWallet = newMultisigWallet;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) onlyOwner {
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

  function createTokens() whenNotPaused isUnderHardCap saleIsOn payable {
    require(msg.value > 0);
    uint secondWalletInvested = msg.value.mul(secondWalletPercent).div(percentRate);
    secondWallet.transfer(secondWalletInvested);
    multisigWallet.transfer(msg.value - secondWalletInvested);
    invested = invested.add(msg.value);
    uint bonusPercent = getBonus(msg.value);
    uint tokens = msg.value.mul(1 ether).div(price);
    uint bonusTokens = tokens.mul(bonusPercent).div(percentRate);
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.mint(this, tokensWithBonus);
    token.transfer(msg.sender, tokensWithBonus);
  }

  function finishMinting() public whenNotPaused onlyOwner {
    uint issuedTokenSupply = token.totalSupply();
    uint summaryTokensPercent = bountyTokensPercent + foundersTokensPercent;
    uint summaryFoundersTokens = issuedTokenSupply.mul(summaryTokensPercent).div(percentRate - summaryTokensPercent);
    uint totalSupply = summaryFoundersTokens + issuedTokenSupply;
    uint foundersTokens = totalSupply.mul(foundersTokensPercent).div(percentRate);
    uint bountyTokens = totalSupply.mul(bountyTokensPercent).div(percentRate);
    token.mint(this, foundersTokens);
    token.transfer(foundersTokensWallet, foundersTokens);
    token.mint(this, bountyTokens);
    token.transfer(bountyTokensWallet, bountyTokens);
    token.finishMinting();
    token.transferOwnership(owner);
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}
