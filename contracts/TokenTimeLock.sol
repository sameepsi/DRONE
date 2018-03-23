pragma solidity 0.4.19;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface Token {
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function decimals()public view returns (uint8);
}

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock is Ownable {
    using SafeMath for uint256;

  // ERC20 basic token contract being held
  Token public token;

  // beneficiary of tokens after they are released
  address[] public beneficiaries;
  
  //vesting percentage for each beneficiary
  mapping(address=>uint256)public tokensVested;
  
  //tokens released by each beneficiary
  mapping (address => uint256) public released;
  
  
  // timestamp when token release is enabled
  uint256 public releaseTime;

    /**
    *@dev constructor method- It will set all the required configuration parameters
    * @param _token Address of the token to be used
    * @param _beneficiaries List of beneficiaries
    * @param _tokensVested Tokens to be vested for each beneficiary
    * @param _releaseTime Time after which tokens will be released
    */
  function TokenTimelock(address _token, address[] _beneficiaries, uint256[]_tokensVested, uint256 _releaseTime) public {
      
    require(_releaseTime > now);
    require(_token != address(0));
    require(_beneficiaries.length == _tokensVested.length);
    
    token = Token(_token);
    
    beneficiaries = _beneficiaries;
    
    for(uint8 i=0;i<beneficiaries.length;i++) {
        tokensVested[beneficiaries[i]] = _tokensVested[i];
    }
    
    releaseTime = _releaseTime;
  }

  /**
   * @dev function using which valid beneficiaries can release their tokens after release time has elapsed
   * 
   */
  function release() public {
      
    require(now >= releaseTime);
    require(validBeneficiary(msg.sender));

    uint256 amount = releasableAmount(msg.sender);
    
    assert(amount > 0);
    
    released[msg.sender] = released[msg.sender].add(amount);
    
    token.transfer(msg.sender, amount);
  }
  
  /**
  * @dev Method to check whether the beneficiary is a valid beneficiary or not
  * @param _beneficiary The address of the beneficiary whose validity has to be checked
  */
  function validBeneficiary(address _beneficiary)public view returns (bool) {
      
      require(_beneficiary != address(0));
      
      for(uint8 i=0;i<beneficiaries.length;i++){
          if(beneficiaries[i] == _beneficiary){
              return true;
          }
          
      }
      return false;
  }
  
   /**
   * @dev Method to allow owner of the contract to remove any beneficiary from the list
   * It will remove beneficiary from the list and divide his/her tokens to other beneficiaries
   * @param _beneficiary The address of beneficiary to be removed
   * 
   */
  function revokeBeneficiary(address _beneficiary) onlyOwner public {
        
        require(_beneficiary != address(0));
        require(validBeneficiary(_beneficiary));
        
        uint256 tokensVestedForAddress = tokensVested[_beneficiary];
        uint256 tokensReleasedToAddress = released[_beneficiary];
        uint256 remainingAmount = tokensVestedForAddress.sub(tokensReleasedToAddress);
        
        tokensVested[_beneficiary] = 0;
        
        for(uint8 i=0;i<beneficiaries.length;i++){
            if(beneficiaries[i] == _beneficiary){
                beneficiaries[i] = beneficiaries[beneficiaries.length -1];
                delete beneficiaries[beneficiaries.length -1];
                beneficiaries.length --;
            }
        }
        
        for(uint8 j = 0;j<beneficiaries.length;j++) {
            tokensVested[beneficiaries[j]] = tokensVested[beneficiaries[j]].add(remainingAmount.div(beneficiaries.length - j));
            remainingAmount = remainingAmount.sub(remainingAmount.div(beneficiaries.length - j));
        }

        
  }
  
  /**
  * @dev Method to check releasable token for the beneficiary
  * @param _beneficiary The address of the beneficiary whose balance has to be checked
  */
  
  function releasableAmount(address _beneficiary)public view returns(uint256) {
      
      require(_beneficiary != address(0));

      require(now >= releaseTime);

      uint256 currentBalance = token.balanceOf(this);
      
      uint256 tokensVestedForAddress = tokensVested[_beneficiary];
      
      uint256 tokensReleasedToAddress = released[_beneficiary];
      
      assert(tokensVestedForAddress.sub(tokensReleasedToAddress)<=currentBalance);
      
      return tokensVestedForAddress.sub(tokensReleasedToAddress);
      
      
  }
}
