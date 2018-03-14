pragma solidity 0.4.21;


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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface Token {
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function decimals()public view returns (uint8);
}

/**
 * @title Vault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Funds will be transferred to owner once sale ends
 */
contract Vault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Withdraw }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Withdraw();
    event RefundsEnabled();
    event withdrawn(address _wallet);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
      
    function Vault(address _wallet) public {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) public onlyOwner  payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function activateWithdrawal() public onlyOwner {
        if(state == State.Active){
        state = State.Withdraw;
      emit Withdraw();
        }
    }
    
    function activateRefund()public onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }
    
    function withdrawToWallet() onlyOwner public{
    require(state == State.Withdraw);
    wallet.transfer(this.balance);
    emit withdrawn(wallet);
  }
  
   function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}


contract DroneTokenSale is Ownable{
      using SafeMath for uint256;
      
      //Token to be used for this sale
      Token public token;
      
      //All funds will go into this vault
      Vault public vault;
  
      //rate of token in ether
      uint256 rate;
      /*
      *There will be 4 phases
      * 1. Pre-sale
      * 2. ICO Phase 1
      * 3. ICO Phase 2
      * 4. ICO Phase 3
      */
      struct PhaseInfo{
          uint256 hardcap;
          uint256 startTime;
          uint256 endTime;
          uint8 [] bonusPercentages;//3 type of bonuses above 100eth, 10-100ether, less than 10ether
          uint256 weiRaised;
      }
      
      //info of each phase
      PhaseInfo[] public phases;
      
      //Total funding
      uint256 public totalFunding;
      
      //total tokesn available for sale
      uint256 tokensAvailableForSale = 10000000000;
      
      
      uint8 public noOfPhases = 4;
      
      
      //Keep track of whether contract is up or not
      bool public contractUp;
      
      //Keep track of whether the sale has ended or not
      bool public saleEnded;
      
      bool public unspentCreditsWithdrawn;
      
      //Event to trigger Sale stop
      event SaleStopped(address _owner, uint256 time);
      
      //Event to trigger normal flow of sale end
      event Finalized(address _owner, uint256 time);
    
     /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
     event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    //modifiers    
    modifier _contractUp(){
        require(contractUp);
        _;
    }
  
     modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }
    
    modifier minEthContribution() {
        require(msg.value > 0.1 ether);
        _;
    }
    
    modifier _saleEnded() {
        require(saleEnded);
        _;
    }
    
    modifier _saleNotEnded() {
        require(!saleEnded);
        _;
    }
  
    
    /**
    *     @dev Check if sale contract has enough tokens on its account balance 
    *     to reward all possible participations within sale period
    */
    function powerUpContract() external onlyOwner {
        // Contract should not be powered up previously
        require(!contractUp);

        // Contract should have enough DRONE credits
        require(token.balanceOf(this) >= tokensAvailableForSale);
        
        
      
        //activate the sale process
        contractUp = true;
    }
    
    //for Emergency/Hard stop of the sale
    function emergencyStop() public onlyOwner _contractUp _saleNotEnded{
        saleEnded = true;    
        
     if(totalFunding > 10 ether){
            vault.activateRefund();
        }
        else{
            vault.activateWithdrawal();
        }
        
      emit SaleStopped(msg.sender, now);
    }
    
    /**
   * @dev Must be called after sale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
    function finalize()public onlyOwner _contractUp _saleNotEnded{
        require(saleTimeOver());
        
        saleEnded = true;
        
        if(totalFunding > 10 ether){
            vault.activateRefund();
        }
        else{
            vault.activateWithdrawal();
        }
       
       emit Finalized(msg.sender, now);
    }
    
      // @return true if all the tiers has been ended
  function saleTimeOver() public view returns (bool) {
    
    return now > phases[noOfPhases-1].endTime;
  }
  
    //if crowdsales is over, the money rasied should be transferred to the wallet address
  function withdrawFunds() public onlyOwner _saleEnded{
  
      vault.withdrawToWallet();
  }
  
  /**
  * @dev Can be called only once. The method to allow owner to set tier information
  * @param _noOfPhases The integer to set number of tiers
  * @param _startTimes The array containing start time of each tier
  * @param _endTimes The array containing end time of each tier
  * @param _hardCaps The array containing hard cap for each tier
  * @param _rates The array containing number of tokens per ether for each tier
  * @param _bonusPercentages The array containing bonus percentage for each tier
  * The arrays should be in sync with each other. For each index 0 for each of the array should contain info about Tier 1, similarly for Tier2, 3,4 and 5.
  * Sales hard cap will be the hard cap of last tier
  */
  function setTiersInfo(uint8 _noOfPhases, uint256[] _startTimes, uint256[] _endTimes, uint256[] _hardCaps, uint8[][] _bonusPercentages)private {
    
    
    require(_noOfPhases==4);
    
    //Each array should contain info about each tier
    require(_startTimes.length == _noOfPhases);
    require(_endTimes.length==_noOfPhases);
    require(_hardCaps.length==_noOfPhases);
    require(_bonusPercentages.length==_noOfPhases);
    
    noOfPhases = _noOfPhases;
    
    for(uint8 i=0;i<_noOfPhases;i++){
        require(_hardCaps[i]>0);
        require(_endTimes[i]>_startTimes[i]);
        if(i>0){
            
        
            
            //start time of this tier should be greater than previous tier
            require(_startTimes[i]>_endTimes[i-1]);
            
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
            //start time of tier1 should be greater than current time
            require(_startTimes[i]>now);
          
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
    }
  }
  
    
    function DroneTokenSale(address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
        uint256[] memory startTimes;
        uint256[] memory endTimes;
        uint256[] memory hardCaps;
        uint8[] [] memory bonusPercentages;
        
        startTimes[0] = 12345;
        endTimes[0] = 12346;
        hardCaps[0] = 10000;
        bonusPercentages[0][0] = 35;
        bonusPercentages[0][1] = 30;
        bonusPercentages[0][2] = 20;
        
        startTimes[1] = 12347;
        endTimes[1] = 12348;
        hardCaps[1] = 10000;
        bonusPercentages[1][0] = 35;
        bonusPercentages[1][1] = 30;
        bonusPercentages[1][2] = 20;
        
        startTimes[2] = 12349;
        endTimes[2] = 12350;
        hardCaps[2] = 10000;
        bonusPercentages[2][0] = 35;
        bonusPercentages[2][1] = 30;
        bonusPercentages[2][2] = 20;
        
        startTimes[3] = 12351;
        endTimes[3] = 12352;
        hardCaps[3] = 10000;
        bonusPercentages[3][0] = 35;
        bonusPercentages[3][1] = 30;
        bonusPercentages[3][2] = 20;

        setTiersInfo(4, startTimes, endTimes, hardCaps, bonusPercentages);
        
    }
    

   //Fallback function used to buytokens
   function()public payable{
       buyTokens(msg.sender);
   }
   
   /**
   * @dev Low level token purchase function
   * @param beneficiary The address who will receive the tokens for this transaction
   */
   function buyTokens(address beneficiary)public _contractUp minEthContribution nonZeroAddress(beneficiary) payable returns(bool){
       
       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       assert(currentPhaseIndex>=0);
       
        // recheck this for storage and memory
       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       
       uint256 weiAmount = msg.value;

       //hard cap for this phase has not been reached
       require(weiAmount.add(currentlyRunningPhase.weiRaised) < currentlyRunningPhase.hardcap);
       
       
       uint256 tokens = weiAmount.mul(rate);//TODO: check this once
       
       uint256 bonusedTokens = applyBonus(tokens, currentlyRunningPhase.bonusPercentages, weiAmount);
       
      
       
      
       totalFunding = totalFunding.add(weiAmount);
       
       currentlyRunningPhase.weiRaised = currentlyRunningPhase.weiRaised.add(weiAmount);
       vault.deposit.value(msg.value)(msg.sender);
       token.transfer(beneficiary, bonusedTokens);
       emit TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);
       
   }
   
     function applyBonus(uint256 tokens, uint8 []percentages, uint256 weiSent) internal pure returns  (uint256 bonusedTokens) {
         uint256 tokensToAdd = 0;
         if(weiSent<10){
             tokensToAdd = tokens.mul(percentages[0]).div(100);
         }
         else if(weiSent>=10 && weiSent<=100){
              tokensToAdd = tokens.mul(percentages[1]).div(100);
         }
         
         else{
              tokensToAdd = tokens.mul(percentages[2]).div(100);
         }
        
        return tokens.add(tokensToAdd);
    }
    
   /**
    * @dev returns the currently running tier index as per time
    * Return -1 if no tier is running currently
    * */
   function getCurrentlyRunningPhase()public view returns(int8){
      for(uint8 i=0;i<noOfPhases;i++){
          if(now>=phases[i].startTime && now<=phases[i].endTime){
              return int8(i);
          }
      }   
      return -1;
   }
   
   /**
   * @dev Get functing info of user/address. It will return how much funding the user has made in terms of wei
   */
   function getFundingInfoForUser(address _user)public view nonZeroAddress(_user) returns(uint256){
       return vault.deposited(_user);
   }
   
      
}
