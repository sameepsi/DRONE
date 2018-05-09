pragma solidity 0.4.23;


interface Token{
     function transfer(address _to, uint256 _amount) external returns (bool);
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
  constructor () public {
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

contract DroneAirdrop is Ownable {
    
    Token public token;
    
    constructor(address _tokenAddress)public {
        require(_tokenAddress != address(0));
        
        token = Token(_tokenAddress);
    }
    
    function multisend(address[] dests, uint256[] values) public onlyOwner returns (uint256) {
        require(dests.length == values.length, "Number of addresses and values should be same");
        
        uint256 i = 0;
        while (i < dests.length) {
           token.transfer(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }
}
