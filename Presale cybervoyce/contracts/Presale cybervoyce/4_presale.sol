//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



interface ERCToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract Presale  {

  // The token being sold
  ERCToken[2] public tokens;

  // enum for tokens
  enum Token{cyber,voyce}
  Token private choice;

  // total Pre sale cap  for Cyber
  uint private cyberCap;
  // total Pre sale cap  for Voyce  
  uint private voyceCap;

  // Address where funds are collected
  address public wallet;

  // Rate of one cyber token in wei
  uint256 public cyberRate=24462803627559;

  // Rate of one voyce token in wei
  uint256 public voyceRate=4234100599407;

  // Amount of token sold
  uint256 public cyberTokenSold;
    // Amount of token sold
  uint256 public voyceTokenSold;

  // Balance of buyer
  function balanceOf(address _account,Token _choice) external view returns (uint256){
    if(_choice==Token.cyber)
      return tokens[0].balanceOf(_account);
    else return tokens[1].balanceOf(_account);
  }

  // Contribution of buyer
  mapping(address =>mapping(Token => uint256) ) public contributions;


  /**
   * Event for token purchase logging
   * @param buyer who got the tokens
   * @param amount weis paid for purchase
   * @param tokens purchased
   * @param choice token 
   */
  event TokenPurchase(
    address indexed buyer,
    uint256 amount,
    uint256 tokens,
    Token choice
  );

  /**
   * @param _wallet Address where collected funds will be forwarded to
   * @param _cyberToken Address of the CYBER token being sold
   * @param _voyceToken Address of the VOYCE token being sold
   * @param _cyberCap Presale total cap for cyber token
   * @param _voyceCap Presale total cap for voyce token
   */
  constructor( address _wallet, ERCToken _cyberToken,ERCToken _voyceToken, uint256 _voyceCap,  uint _cyberCap)  {
    require(_wallet != address(0));
    require(address(_cyberToken) != address(0));
    require(address(_voyceToken) != address(0));
    wallet = _wallet;
    tokens[0] = _cyberToken;
    tokens[1]=_voyceToken;
    voyceCap=_voyceCap;
    cyberCap=_cyberCap;
  }



  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  receive() external payable {
  
  }

  /**
   * @dev cyber token purchase 
   */
  function buyCyber() public payable{
    buyTokens(Token.cyber);
  }

  /**
   * @dev voyce token purchase 
   */
  function buyVoyce() public payable{
    buyTokens(Token.voyce);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   */
  function buyTokens(Token _choice) internal  {

    uint256 amount = msg.value;

    // calculate token amount to be created
    uint256 totalToken = _getTokenAmount(amount,_choice);

    _preValidatePurchase(_choice,msg.sender, amount,totalToken);

  

    // update state
    if(_choice==Token.cyber){
      cyberTokenSold=cyberTokenSold+totalToken;
    }else voyceTokenSold=voyceTokenSold+totalToken; 
    
    _processPurchase(msg.sender, totalToken,_choice);
    emit TokenPurchase(
      msg.sender,
      amount,
      totalToken,
      _choice
    );

    _updatePurchasingState(msg.sender, amount,_choice);

    _forwardFunds();
   // _postValidatePurchase(msg.sender, amount);

  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _buyer Address performing the token purchase
   * @param _amount Value in wei involved in the purchase
   * @param _totalToken total amount of tokens to be purchased
   */
  function _preValidatePurchase(
    Token _choice,
    address _buyer,
    uint256 _amount,
    uint256 _totalToken
  ) view 
    internal 
  {
    require(_buyer != address(0));
    require(_amount != 0);
    if (_choice==Token.cyber){
      require(_amount>=0.7 ether);
      require(cyberTokenSold+_totalToken<=cyberCap);
    } else if(_choice==Token.voyce){
      require(_amount>=0.7 ether);
      require(cyberTokenSold+_totalToken<=voyceCap);
    }
  }

  /*
   * @dev Executed when a purchase has been validated and is ready to be executed.now emits/sends tokens.
   * @param Buyer Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _buyer,
    uint256 _tokenAmount,
    Token _choice
  )
    internal
  {
    tokens[uint(_choice)].transfer(_buyer, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _buyer Address receiving the tokens
   * @param _amount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _buyer,
    uint256 _amount,
    Token _choice
  )
    internal
  {
    // optional override
    contributions[_buyer][_choice]= contributions[_buyer][_choice]+_amount;

  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _amount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _amount
   */
  function _getTokenAmount(uint256 _amount,Token _choice)
    internal view returns (uint256)
  {
    if(_choice==Token.cyber)
    return _amount/cyberRate;
    else return _amount/voyceRate;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    (bool sent,) =payable(wallet).call{value: msg.value}("");
     require(sent, "Failed to send Ether");
  }
}


