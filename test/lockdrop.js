const Promise = require('bluebird');
const utility = require('../helpers/util');
const ldHelpers = require('../helpers/lockdropHelper');
const constants = require('../helpers/constants');
const { toWei, toBN, padRight } = web3.utils;
const BN = require('bn.js');
const rlp = require('rlp');
const keccak = require('keccak');
const { decodeAddress, encodeAddress } = require('@polkadot/util-crypto');
const { u8aToHex } = require('@polkadot/util');

const Lock = artifacts.require("./Lock.sol");
const Lockdrop = artifacts.require("./Lockdrop.sol");
const MXCToken = artifacts.require("./MXCToken.sol");

contract('Lockdrop', (accounts) => {
  console.log('accounts: ', accounts);
  const SECONDS_IN_DAY = 86400;
  const THREE_MONTHS = 0;
  const SIX_MONTHS = 1;
  const TWELVE_MONTHS = 2;

  let lockdrop;
  let lockdropAsArray;
  let mxcTokenInstance;
  let mxcTokenInstanceAddress;

  beforeEach(async function() {
    let time = await utility.getCurrentTimestamp(web3);
    try {
      lockdrop = await Lockdrop.new(time);
      lockdropAsArray = Array(lockdrop);

      mxcTokenInstance = await MXCToken.new();
    } catch(err) {
      console.log('Error creating contracts: ', err);
    }
  });

  it('should setup and pull constants', async function () {
    let time = await utility.getCurrentTimestamp(web3);
    let LOCK_DROP_PERIOD = (await lockdrop.LOCK_DROP_PERIOD()).toNumber();
    let LOCK_START_TIME = (await lockdrop.LOCK_START_TIME()).toNumber();
    assert.equal(LOCK_DROP_PERIOD, SECONDS_IN_DAY * 92);
    assert.ok(LOCK_START_TIME <= time && time <= LOCK_START_TIME + 1000);
  });

  it('should lock funds and also be a potential validator', async function () {
    const mxcTokenInstanceOwnerAccountBalance = await mxcTokenInstance.balanceOf(accounts[0]);
    console.log('Lock contract owner has MXCToken balance: ', toBN(mxcTokenInstanceOwnerAccountBalance).toString());
    const ethAccountBalance = await utility.getBalance(accounts[0], web3);
    console.log('Lock contract owner has ETH balance: ', toBN(ethAccountBalance).toString());

    await lockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: 0,
    });

    const lockEvents = await ldHelpers.getLocks(lockdrop, accounts[0]);
    assert.equal(lockEvents.length, 1);
    assert.equal(lockEvents[0].args.isValidator, true);
    const lockStorages = await Promise.all(lockEvents.map(event => {
      return ldHelpers.getLockStorage(web3, event.returnValues.lockAddr);
    }));

    assert.equal(lockStorages[0].owner, lockEvents[0].returnValues.owner.toLowerCase());
  });

  it('should unlock the funds after the lock period has ended', async function () {
    const mxcTokenInstanceOwnerAccountBalanceBefore = await mxcTokenInstance.balanceOf(accounts[0]);
    console.log('Lock contract owner has MXCToken balance BEFORE: ', toBN(mxcTokenInstanceOwnerAccountBalanceBefore).toString());

    let txHash = await lockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: web3.utils.toWei('0', 'ether'),
    });

    const mxcTokenInstanceOwnerAccountBalanceAfter = await mxcTokenInstance.balanceOf(accounts[0]);
    console.log('Lock contract owner has MXCToken balance AFTER: ', toBN(mxcTokenInstanceOwnerAccountBalanceAfter).toString());

    const lockEvents = await ldHelpers.getLocks(lockdrop, accounts[0]);
    const lockStorages = await Promise.all(lockEvents.map(event => {
      return ldHelpers.getLockStorage(web3, event.returnValues.lockAddr);
    }));
    let unlockTime = lockStorages[0].unlockTime;

    const lockContract = await Lock.at(lockEvents[0].returnValues.lockAddr);

    let time = await utility.getCurrentTimestamp(web3);
    let res = await utility.advanceTime(unlockTime - time + SECONDS_IN_DAY, web3);

    // TODO - refactor into helper function since this is repeated
    const sender = mxcTokenInstance.address;
    const nonce = (await web3.eth.getTransactionCount(sender));
    const nonceHex = `0x${nonce.toString(16)}`;
    const input = [ sender, nonce ];
    const rlpEncoded = rlp.encode(input);
    const contractAddressLong = keccak('keccak256').update(rlpEncoded).digest('hex');
    const mxcTokenInstanceAddress = `0x${contractAddressLong.substring(24)}`;
    console.log('MXCToken address: ', mxcTokenInstanceAddress);

    txHash = await lockContract.withdrawTokens(mxcTokenInstanceAddress, {
      from: accounts[0],
      value: 0,
      gas: 50000,
    });

    const afterafter = await utility.getBalance(accounts[0], web3);
    assert(toBN(mxcTokenInstanceOwnerAccountBalanceBefore).gt(toBN(mxcTokenInstanceOwnerAccountBalanceAfter)), "Owners token balance should reduce after locking");
    assert(toBN(afterafter).gt(toBN(mxcTokenInstanceOwnerAccountBalanceAfter)), "Owners token balance should increase after unlocking");
  });

  // it('should not allow one to send Ether to the lockdrop contract', async function () {
  //   let txHash = await lockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
  //     from: accounts[0],
  //     value: web3.utils.toWei('0', 'ether'),
  //   });

  //   const lockEvents = await ldHelpers.getLocks(lockdrop, accounts[0]);
  //   const lockContract = await Lock.at(lockEvents[0].returnValues.lockAddr);

  //   utility.assertRevert(await lockContract.sendTransaction({
  //     from: accounts[0],
  //     value: 0,
  //     gas: 50000,
  //   }));
  // });

  it('should not allow one to lock before the lock start time', async function () {
    let time = await utility.getCurrentTimestamp(web3);
    const newLockdrop = await Lockdrop.new(time + SECONDS_IN_DAY * 10);
    utility.assertRevert(newLockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: web3.utils.toWei('0', 'ether'),
    }));
  });

  it('should not allow one to lock after the lock start time', async function () {
    await lockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: web3.utils.toWei('0', 'ether'),
    });

    utility.advanceTime(SECONDS_IN_DAY * 15, web3);
    utility.assertRevert(lockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: web3.utils.toWei('0', 'ether'),
    }));
  });

  it('should not allow one to lock up any different length than 3,6,9,12,24,36 months', async function () {
    utility.assertRevert(lockdrop.lock(accounts[0], 123456, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: web3.utils.toWei('0', 'ether'),
    }));
  });

  it('should fail to withdraw funds if not enough gas is sent', async function () {
    let time = await utility.getCurrentTimestamp(web3);
    const newLockdrop = await Lockdrop.new(time);
    await newLockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: web3.utils.toWei('0', 'ether'),
    });

    const balAfter = await utility.getBalance(accounts[0], web3);

    const lockEvents = await ldHelpers.getLocks(newLockdrop, accounts[0]);
    const lockStorages = await Promise.all(lockEvents.map(event => {
      return ldHelpers.getLockStorage(web3, event.returnValues.lockAddr);
    }));
    let unlockTime = lockStorages[0].unlockTime;
    const lockContract = await Lock.at(lockEvents[0].returnValues.lockAddr);

    time = await utility.getCurrentTimestamp(web3);
    await utility.advanceTime(unlockTime - time + SECONDS_IN_DAY, web3);

    // TODO - refactor into helper function since this is repeated
    const sender = mxcTokenInstance.address;
    const nonce = (await web3.eth.getTransactionCount(sender));
    const nonceHex = `0x${nonce.toString(16)}`;
    const input = [ sender, nonce ];
    const rlpEncoded = rlp.encode(input);
    const contractAddressLong = keccak('keccak256').update(rlpEncoded).digest('hex');
    const mxcTokenInstanceAddress = `0x${contractAddressLong.substring(24)}`;
    console.log('MXCToken address: ', mxcTokenInstanceAddress);

    utility.assertRevert(await lockContract.withdrawTokens(mxcTokenInstanceAddress, {
      from: accounts[0],
      value: 0,
      gas: 1,
    }));
  });

  it('should generate the allocation for a substrate genesis spec with THREE_MONTHS term', async function () {
    await Promise.all(accounts.map(async (addr, inx) => {
      return await lockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
        from: accounts[0],
        value: web3.utils.toWei('0', 'ether'),
      });
    }));

    const allocation = await ldHelpers.calculateEffectiveLocks(lockdropAsArray);
    let { validatingLocks, locks, totalEffectiveERC20TokenLocked } = allocation;
    const signalAllocation = await ldHelpers.calculateEffectiveSignals(web3, lockdropAsArray);
    let { signals, totalEffectiveERC20TokenSignaled, genLocks } = signalAllocation;
    console.log('signals, totalEffectiveERC20TokenSignaled: ', signals, totalEffectiveERC20TokenSignaled)
    const totalEffectiveETH = totalEffectiveERC20TokenLocked.add(totalEffectiveERC20TokenSignaled);
    let json = await ldHelpers.getEdgewareBalanceObjects(locks, signals, genLocks, constants.TOTAL_ALLOCATION, totalEffectiveETH);

    const bal = toBN(constants.TOTAL_ALLOCATION).div(toBN(accounts.length)).toString();
    json.balances.forEach(elt => {
      assert.equal(elt[0], bal);
    });
  });

  it('should generate the allocation for a substrate genesis spec with SIX_MONTHS term', async function () {
    await Promise.all(accounts.map(async (addr, inx) => {
      return await lockdrop.lock(accounts[0], SIX_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
        from: accounts[0],
        value: web3.utils.toWei('0', 'ether'),
      });
    }));

    const allocation = await ldHelpers.calculateEffectiveLocks(lockdropAsArray);
    let { validatingLocks, locks, totalEffectiveERC20TokenLocked } = allocation;
    const signalAllocation = await ldHelpers.calculateEffectiveSignals(web3, lockdropAsArray);
    let { signals, totalEffectiveERC20TokenSignaled, genLocks } = signalAllocation;
    const totalEffectiveETH = totalEffectiveERC20TokenLocked.add(totalEffectiveERC20TokenSignaled);
    let json = await ldHelpers.getEdgewareBalanceObjects(locks, signals, genLocks, constants.TOTAL_ALLOCATION, totalEffectiveETH);

    const bal = toBN(constants.TOTAL_ALLOCATION).div(toBN(accounts.length)).toString();
    json.balances.forEach(elt => {
      assert.equal(elt[0], bal);
    });
  });

  it('should generate the allocation for a substrate genesis spec with TWELVE_MONTHS term', async function () {
    await Promise.all(accounts.map(async (addr, inx) => {
      return await lockdrop.lock(accounts[0], TWELVE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
        from: accounts[0],
        value: web3.utils.toWei('0', 'ether'),
      });
    }));

    const allocation = await ldHelpers.calculateEffectiveLocks(lockdropAsArray);
    let { validatingLocks, locks, totalEffectiveERC20TokenLocked } = allocation;
    const signalAllocation = await ldHelpers.calculateEffectiveSignals(web3, lockdropAsArray);
    let { signals, totalEffectiveERC20TokenSignaled, genLocks } = signalAllocation;
    const totalEffectiveETH = totalEffectiveERC20TokenLocked.add(totalEffectiveERC20TokenSignaled);
    let json = await ldHelpers.getEdgewareBalanceObjects(locks, signals, genLocks, constants.TOTAL_ALLOCATION, totalEffectiveETH);

    const bal = toBN(constants.TOTAL_ALLOCATION).div(toBN(accounts.length)).toString();
    json.balances.forEach(elt => {
      assert.equal(elt[0], bal);
    });
  });

  it('should aggregate the balances for all non validators and separate for validators', async function () {
    await Promise.all(accounts.map(async (addr, inx) => {
      return await lockdrop.lock(accounts[0], TWELVE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, false, {
        from: accounts[0],
        value: web3.utils.toWei('0', 'ether'),
      });
    }));

    // Note that account[0] is locking their tokens and making account[1] the owner of them
    await lockdrop.lock(accounts[1], TWELVE_MONTHS, 200, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: web3.utils.toWei('0', 'ether'),
    });

    // FIXME - change to check locks of ERC20 tokens instead of ETH
    const allocation = await ldHelpers.calculateEffectiveLocks(lockdropAsArray);
    let { validatingLocks, locks, totalEffectiveERC20TokenLocked } = allocation;
    assert.equal(Object.keys(validatingLocks).length, 1);
    assert.equal(Object.keys(locks).length, 1);
  });

  it('should turn a lockdrop allocation into the substrate genesis format', async function () {
    await Promise.all(accounts.map(async (addr, inx) => {
      return await lockdrop.lock(accounts[0], TWELVE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].pubKey), constants.SAMPLE_MXC_TOKEN_ADDRESS, (Math.random() > 0.5) ? true : false, {
        from: accounts[0],
        value: web3.utils.toWei('0', 'ether'),
      });
    }));

    const allocation = await ldHelpers.calculateEffectiveLocks(lockdropAsArray);
    let { validatingLocks, locks, totalEffectiveERC20TokenLocked } = allocation;
    const signalAllocation = await ldHelpers.calculateEffectiveSignals(web3, lockdropAsArray);
    let { signals, totalEffectiveERC20TokenSignaled, genLocks } = signalAllocation;
    const totalEffectiveETH = totalEffectiveERC20TokenLocked.add(totalEffectiveERC20TokenSignaled);
    let json = await ldHelpers.getEdgewareBalanceObjects(locks, signals, genLocks, constants.TOTAL_ALLOCATION, totalEffectiveETH);
    let validators = ldHelpers.selectEdgewareValidators(validatingLocks, constants.TOTAL_ALLOCATION, totalEffectiveETH, 10);
    assert(validators.length < 10);
    assert.ok(json.hasOwnProperty('balances'));
    assert.ok(json.hasOwnProperty('vesting'));
  });

  it('should allow contracts to lock up ERC20 tokens by signalling', async function () {
    const sender = accounts[0];
    const term = 12;
    const tokenERC20Amount = 200;
    const dataHighwayPublicKey = decodeAddress(constants.FIXTURES[0].pubKey);
    const tokenContractAddress = constants.SAMPLE_MXC_TOKEN_ADDRESS;
    const nonce = (await web3.eth.getTransactionCount(sender));
    const nonceHex = `0x${nonce.toString(16)}`;
    const input = [ sender, nonce ];
    const rlpEncoded = rlp.encode(input);
    const contractAddressLong = keccak('keccak256').update(rlpEncoded).digest('hex');
    const contractAddr = contractAddressLong.substring(24);
    await lockdrop.signal(accounts[0], `0x${contractAddr}`, nonce, term, tokenERC20Amount, dataHighwayPublicKey, tokenContractAddress, { from: sender });
    const lockEvents = await ldHelpers.getSignals(lockdrop, contractAddr);
  });

  it('ensure the contract address matches JS RLP script', async function () {
    const sender = accounts[0];
    const nonce = (await web3.eth.getTransactionCount(sender));
    const nonceHex = `0x${nonce.toString(16)}`;
    const input = [ sender, nonce ];
    const rlpEncoded = rlp.encode(input);
    const contractAddressLong = keccak('keccak256').update(rlpEncoded).digest('hex');
    const contractAddr = contractAddressLong.substring(24);

    let time = await utility.getCurrentTimestamp(web3);
    let tempLd = await Lockdrop.new(time);
    assert.equal(web3.utils.toBN(tempLd.address).toString(), web3.utils.toBN(contractAddr).toString());
  });

  it('should ensure base58 encodings are valid to submit', async function () {
    let bytes, decodedKey, encodedKey = '';
    // Add locks using default accounts
    await Promise.all(accounts.map(async (addr, inx) => {
      decodedKey = u8aToHex(decodeAddress(constants.FIXTURES[inx].base58Address));
      console.log('decodedKey', decodedKey)
      return await lockdrop.lock(accounts[0], TWELVE_MONTHS, 100, `${decodedKey}`, constants.SAMPLE_MXC_TOKEN_ADDRESS, (Math.random() > 0.5) ? true : false, {
        from: accounts[0],
        value: web3.utils.toWei('0', 'ether'),
      });
    }));

    await Promise.all(accounts.map(async (a, inx) => {
      // TODO - replace with decodeAddress(constants.FIXTURES[0].pubKey) ??
      decodedKey = u8aToHex(decodeAddress(constants.FIXTURES[inx].base58Address));
      return await lockdrop.lock(TWELVE_MONTHS, a, `${decodedKey}`, constants.SAMPLE_MXC_TOKEN_ADDRESS, (Math.random() > 0.5) ? true : false, {
        from: a,
        value: web3.utils.toWei('0', 'ether'),
      });
    }));

    const allocation = await ldHelpers.calculateEffectiveLocks(lockdropAsArray);
    let { validatingLocks, locks, totalEffectiveERC20TokenLocked } = allocation;
    const signalAllocation = await ldHelpers.calculateEffectiveSignals(web3, lockdropAsArray);
    let { signals, totalEffectiveERC20TokenSignaled, genLocks } = signalAllocation;
    const totalEffectiveETH = totalEffectiveERC20TokenLocked.add(totalEffectiveERC20TokenSignaled);

    let totalERC20TokenLockedInETH = web3.utils.fromWei(totalEffectiveERC20TokenLocked.toString(), 'ether');
    console.log('Validating Locks in ETH: ', totalERC20TokenLockedInETH);
    console.log('Locks in ETH: ', totalERC20TokenLockedInETH);
    let totalERC20TokenSignaledInETH = web3.utils.fromWei(totalEffectiveERC20TokenSignaled.toString(), 'ether');
    console.log('Signalled in ETH: ', totalERC20TokenSignaledInETH);
    let json = await ldHelpers.getEdgewareBalanceObjects(locks, signals, genLocks, constants.TOTAL_ALLOCATION, totalEffectiveETH);
    let validators = ldHelpers.selectEdgewareValidators(validatingLocks, constants.TOTAL_ALLOCATION, totalEffectiveETH, 4);

    let sum = toBN(0);
    console.log('json: ', json);
    json.balances.forEach((elt, inx) => {
      decodedKey = elt[0];
      bytes = Buffer.from(decodedKey, 'hex');
      // Note: Decode/encode either using bs58 library or Polkadot.js util-crypto and util libraries
      // e.g. https://gist.github.com/ltfschoen/f98e5af52dd5ef60e87e87f143d70625
      encodedKey = encodeAddress(bytes);
      assert.equal(encodedKey, constants.FIXTURES[inx].base58Address);
      sum = sum.add(toBN(elt[1]));
    });

    assert.ok(sum < toBN(constants.TOTAL_ALLOCATION).add(toBN(10)) || sum > toBN(constants.TOTAL_ALLOCATION).sub(toBN(10)))
  });

  it('should not break the first lock of the lockdrop', async function () {
    const sender = lockdrop.address;
    const nonce = (await web3.eth.getTransactionCount(sender));
    const nonceHex = `0x${nonce.toString(16)}`;
    const input = [ sender, nonce ];
    const rlpEncoded = rlp.encode(input);
    const contractAddressLong = keccak('keccak256').update(rlpEncoded).digest('hex');
    const contractAddr = `0x${contractAddressLong.substring(24)}`;

    await web3.eth.sendTransaction({
      from: accounts[0],
      to: contractAddr,
      value: web3.utils.toWei('0', 'ether'),
    });

    await lockdrop.lock(accounts[0], THREE_MONTHS, 100, decodeAddress(constants.FIXTURES[0].base58Address), constants.SAMPLE_MXC_TOKEN_ADDRESS, true, {
      from: accounts[0],
      value: 0,
    });
  });
});
