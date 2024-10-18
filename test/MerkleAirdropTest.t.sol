// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from 'forge-std/Test.sol';
import {MerkleAirdrop} from '../src/MerkleAirdrop.sol';
import {BagelToken} from '../src/BagelToken.sol';
import {ZkSyncChainChecker} from 'lib/foundry-devops/src/ZkSyncChainChecker.sol';
import {DeployMerkleAirdrop} from '../script/DeployMerkleAirdrop.s.sol';

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    MerkleAirdrop public airdrop;
    BagelToken public bagel;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT = 25e18;
    uint256 public constant INITIAL_BALANCE = 100e18;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];
    address public gasPayer;
    address user;
    uint256 userPrivateKey;


    function setUp() public {
        if(!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, bagel) = deployer.deployMerkleAirdrop ();
        } else {
        bagel = new BagelToken();
        airdrop = new MerkleAirdrop(ROOT, bagel);
        bagel.mint(bagel.owner(), INITIAL_BALANCE);
        bagel.transfer(address (airdrop), INITIAL_BALANCE);
        }

        (user, userPrivateKey) = makeAddrAndKey('user');
        gasPayer = makeAddr('gasPayer');
    }

    function testUsersCanClaim() public {
        uint256 userStartingBalance = bagel.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT);

        // sign a message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // gasPayer calls claim using the signed message
        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT, PROOF, v, r, s );

        uint256 userEndingBalance = bagel.balanceOf(user);
        assertEq(userEndingBalance - userStartingBalance, AMOUNT);
    }
}