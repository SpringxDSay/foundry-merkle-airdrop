// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from 'forge-std/Script.sol';
import {DevOpsTools} from 'lib/foundry-devops/src/DevOpsTools.sol';
import {MerkleAirdrop} from '../src/MerkleAirdrop.sol';

contract ClaimAirdrop is Script {
    error ClaimAirdropScrip__InvalidSignatureLength();

    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 CLAIMING_AMOUNT = 25e18;
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE = hex"a761156e248988cf94ea2b00a3c0dd18e0424e1a548d9211a1f96f94414c732550fd8f5211ccb29cb59ff3d1b90583d118a3c93676697282a3fc2a51fd2ade6d1b";

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }

    function splitSignature(bytes memory sig) public pure returns(uint8 v, bytes32 r, bytes32 s) {
        if(sig.length != 65) revert ClaimAirdropScrip__InvalidSignatureLength();

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}