

const BigNumber = web3.BigNumber;

function increaseTime (duration) {
    const id = Date.now();
  
    return new Promise((resolve, reject) => {
      web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [duration],
        id: id,
      }, err1 => {
        if (err1) return reject(err1);
  
        web3.currentProvider.sendAsync({
          jsonrpc: '2.0',
          method: 'evm_mine',
          id: id + 1,
        }, (err2, res) => {
          return err2 ? reject(err2) : resolve(res);
        });
      });
    });
  }

function latestTime () {
    return web3.eth.getBlock('latest').timestamp;
  }
  function increaseTimeTo (target) {
    let now = latestTime();
    if (target < now) throw Error(`Cannot increase current time(${now}) to a moment in the past(${target})`);
    let diff = target - now;
    return increaseTime(diff);
  }
  const duration = {
    seconds: function (val) { return val; },
    minutes: function (val) { return val * this.seconds(60); },
    hours: function (val) { return val * this.minutes(60); },
    days: function (val) { return val * this.hours(24); },
    weeks: function (val) { return val * this.days(7); },
    years: function (val) { return val * this.days(365); },
  };

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const DroneToken = artifacts.require('DroneToken');
const TokenTimelock = artifacts.require('TokenTimelock');

contract('TokenTimelock', function (accounts) {
  const amount = new BigNumber(100);

  beforeEach(async function () {
    this.token = await  DroneToken.new(5000000000, "DRONE", "DRONE");
    this.releaseTime = latestTime() + duration.years(1);
    this.timelock = await TokenTimelock.new(this.token.address, [accounts[1], accounts[2], accounts[3]], [70, 30, 30], this.releaseTime);
    await this.token.transfer(this.timelock.address, 100, { from: accounts[0] });
  });

  it('cannot be released before time limit', async function () {
    await this.timelock.release().should.be.rejected;
  });

  it('cannot be released just before time limit', async function () {
    await increaseTimeTo(this.releaseTime - duration.seconds(3));
    await this.timelock.release().should.be.rejected;
  });

  it('can be released just after limit', async function () {
    await increaseTimeTo(this.releaseTime + duration.seconds(1));
    await this.timelock.release({from:accounts[1]}).should.be.fulfilled;
    const balance = await this.token.balanceOf(accounts[1]);
    balance.should.be.bignumber.equal(70);
  });

  it('can be released after time limit', async function () {
    await increaseTimeTo(this.releaseTime + duration.years(1));
    await this.timelock.release({from:accounts[2]}).should.be.fulfilled;
    const balance = await this.token.balanceOf(accounts[2]);
    balance.should.be.bignumber.equal(30);
  });

  it('cannot be released twice', async function () {
    await increaseTimeTo(this.releaseTime + duration.years(1));
    await this.timelock.release({from:accounts[2]}).should.be.fulfilled;
    await this.timelock.release({from:accounts[2]}).should.be.rejected;
    const balance = await this.token.balanceOf(accounts[2]);
    balance.should.be.bignumber.equal(30);
  });
});
