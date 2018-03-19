var DroneToken = artifacts.require("./DroneToken.sol");

contract('StandardToken', function (accounts) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  
    beforeEach(async function () {
      this.token = await  DroneToken.new(5000000000, "DRONE", "DRONE");
    });
  
    describe('total supply', function () {
      it('returns the total amount of tokens', async function () {
        const totalSupply = await this.token.totalSupply();
  
        assert.equal(totalSupply, 5000000000);
      });
    });
  
    describe('balanceOf', function () {
      describe('when the requested account has no tokens', function () {
        it('returns zero', async function () {
          const balance = await this.token.balanceOf(accounts[1]);
  
          assert.equal(balance, 0);
        });
      });
  
      describe('when the requested account has some tokens', function () {
        it('returns the total amount of tokens', async function () {
          const balance = await this.token.balanceOf(accounts[0]);
  
          assert.equal(balance, 5000000000);
        });
      });
    });
  
    describe('transfer', function () {
      describe('when the recipient is not the zero address', function () {
        const to = accounts[2];
  
        
  
        describe('when the sender has enough balance', function () {
          const amount = 5000000000;
  
          it('transfers the requested amount', async function () {
            await this.token.transfer(to, amount, { from: accounts[0] });
  
            const senderBalance = await this.token.balanceOf(accounts[0]);
            assert.equal(senderBalance, 0);
  
            const recipientBalance = await this.token.balanceOf(to);
            assert.equal(recipientBalance, amount);
          });
  
          it('emits a transfer event', async function () {
            const { logs } = await this.token.transfer(to, amount, { from: accounts[0] });
  
            assert.equal(logs.length, 1);
            assert.equal(logs[0].event, 'Transfer');
            assert.equal(logs[0].args.from, accounts[0]);
            assert.equal(logs[0].args.to, to);
            assert(logs[0].args.value.eq(amount));
          });
        });
      });
  
      
    });
    describe('approve', function () {
        describe('when the spender is not the zero address', function () {
          const spender = accounts[2];
    
          describe('when the sender has enough balance', function () {
            const amount = 5000000000;
    
            it('emits an approval event', async function () {
              const { logs } = await this.token.approve(spender, amount, { from: accounts[0] });
    
              assert.equal(logs.length, 1);
              assert.equal(logs[0].event, 'Approval');
              assert.equal(logs[0].args.owner, accounts[0]);
              assert.equal(logs[0].args.spender, spender);
              assert(logs[0].args.value.eq(amount));
            });
    
            describe('when there was no approved amount before', function () {
              it('approves the requested amount', async function () {
                await this.token.approve(spender, amount, { from: accounts[0] });
    
                const allowance = await this.token.allowance(accounts[0], spender);
                assert.equal(allowance, amount);
              });
            });
    
            describe('when the spender had an approved amount', function () {
              beforeEach(async function () {
                await this.token.approve(spender, 1, { from: accounts[0] });
              });
    
              it('approves the requested amount and replaces the previous one', async function () {
                await this.token.approve(spender, amount, { from: accounts[0] });
    
                const allowance = await this.token.allowance(accounts[0], spender);
                assert.equal(allowance, amount);
              });
            });
          });
    
          describe('when the sender does not have enough balance', function () {
            const amount = 5000000000;
    
            it('emits an approval event', async function () {
              const { logs } = await this.token.approve(spender, amount, { from: accounts[0] });
    
              assert.equal(logs.length, 1);
              assert.equal(logs[0].event, 'Approval');
              assert.equal(logs[0].args.owner, accounts[0]);
              assert.equal(logs[0].args.spender, spender);
              assert(logs[0].args.value.eq(amount));
            });
    
            describe('when there was no approved amount before', function () {
              it('approves the requested amount', async function () {
                await this.token.approve(spender, amount, { from: accounts[0] });
    
                const allowance = await this.token.allowance(accounts[0], spender);
                assert.equal(allowance, amount);
              });
            });
    
            describe('when the spender had an approved amount', function () {
              beforeEach(async function () {
                await this.token.approve(spender, 1, { from: accounts[0] });
              });
    
              it('approves the requested amount and replaces the previous one', async function () {
                await this.token.approve(spender, amount, { from: accounts[0] });
    
                const allowance = await this.token.allowance(accounts[0], spender);
                assert.equal(allowance, amount);
              });
            });
          });
        });
    
        describe('when the spender is the zero address', function () {
          const amount = 5000000000;
          const spender = ZERO_ADDRESS;
    
          it('approves the requested amount', async function () {
            await this.token.approve(spender, amount, { from: accounts[0] });
    
            const allowance = await this.token.allowance(accounts[0], spender);
            assert.equal(allowance, amount);
          });
    
          it('emits an approval event', async function () {
            const { logs } = await this.token.approve(spender, amount, { from: accounts[0] });
    
            assert.equal(logs.length, 1);
            assert.equal(logs[0].event, 'Approval');
            assert.equal(logs[0].args.owner, accounts[0]);
            assert.equal(logs[0].args.spender, spender);
            assert(logs[0].args.value.eq(amount));
          });
        });
      });
    
      describe('transfer from', function () {
        const spender = accounts[2];
    
        describe('when the recipient is not the zero address', function () {
          const to = accounts[3];
    
          describe('when the spender has enough approved balance', function () {
            beforeEach(async function () {
              await this.token.approve(spender, 5000000000, { from: accounts[0] });
            });
    
            describe('when the owner has enough balance', function () {
              const amount = 5000000000;
    
              it('transfers the requested amount', async function () {
                await this.token.transferFrom(accounts[0], to, amount, { from: spender });
    
                const senderBalance = await this.token.balanceOf(accounts[0]);
                assert.equal(senderBalance, 0);
    
                const recipientBalance = await this.token.balanceOf(to);
                assert.equal(recipientBalance, amount);
              });
    
              it('decreases the spender allowance', async function () {
                await this.token.transferFrom(accounts[0], to, amount, { from: spender });
    
                const allowance = await this.token.allowance(accounts[0], spender);
                assert(allowance.eq(0));
              });
    
              it('emits a transfer event', async function () {
                const { logs } = await this.token.transferFrom(accounts[0], to, amount, { from: spender });
    
                assert.equal(logs.length, 1);
                assert.equal(logs[0].event, 'Transfer');
                assert.equal(logs[0].args.from, accounts[0]);
                assert.equal(logs[0].args.to, to);
                assert(logs[0].args.value.eq(amount));
              });
            });
    
           
          });
    
         
        });
    
      
      });
    
      describe('burn', function () {
        const from = accounts[0];
    
        describe('when the given amount is not greater than balance of the sender', function () {
    
          it('burns the requested amount', async function () {
              await this.token.addEligibleBurner(accounts[0], {from});

              const { logs } = await this.token.burnAllTokens({ from });
    
            const balance = await this.token.balanceOf(from);
            assert.equal(balance, 0);

            assert.equal(logs.length, 1);
            assert.equal(logs[0].event, 'Burn');
            assert.equal(logs[0].args.burner, accounts[0]);
          });
    
       
        });
    
       
      });
    
      
  });