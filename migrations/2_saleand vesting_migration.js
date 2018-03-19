var DroneToken = artifacts.require("./DroneToken.sol");
var DroneTokenSale = artifacts.require("./DroneTokenSale.sol");
var TokenTimelock = artifacts.require("./TokenTimelock.sol");

module.exports = function(deployer) {
 deployer.deploy(DroneToken, 5000000000, "DRONE", "DRONE").then(function(){
    console.log(DroneToken.address);
    deployer.deploy(DroneTokenSale, DroneToken.address, "0xF97D9fc484024F3379D51F422F843b194E9D41C5");
    deployer.deploy(TokenTimelock, DroneToken.address, ["0xF97D9fc484024F3379D51F422F843b194E9D41C5", "0xd78D9fc484024F3379D51F422F8432434E9D4342"], [10000, 100000], 1529481554);

  });
};
