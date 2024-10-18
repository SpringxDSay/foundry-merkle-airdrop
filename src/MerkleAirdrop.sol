// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from '@openzepplin/contracts/token/ERC20/utils/SafeERC20.sol';
import {MerkleProof} from '@openzepplin/contracts/utils/cryptography/MerkleProof.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    // a list of addresses to claim airdrop token
    // token to claim
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] claimers;
    mapping(address claimers => bool claimed) private s_hasClaimed;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaimed(address claimer, uint256 amount)");

    struct AirdropClaim {
        address claimer;
        uint256 amount;
    }

    event Claim(address claimer, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address claimer, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) public {
        if(s_hasClaimed[claimer]) revert MerkleAirdrop__AlreadyClaimed();
        // check the signature
        if(!_isValidSignature(claimer, getMessageHash(claimer, amount), v, r, s)) revert MerkleAirdrop__InvalidSignature();
        // hash the claimer address and amount => leaf node
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(claimer, amount))));

        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) revert MerkleAirdrop__InvalidProof();

        s_hasClaimed[claimer] = true;
        emit Claim(claimer, amount);
        i_airdropToken.safeTransfer(claimer, amount);
    }

    function getMessageHash(address claimer, uint256 amount) public view returns(bytes32) { 
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({claimer: claimer, amount: amount}))) 
        );
    }

    function getMerkleRoot() external view returns(bytes32) {
        return i_merkleRoot;
    }

     function getAirdropToken() external view returns(IERC20) {
        return i_airdropToken;
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns(bool) {
         (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
         return actualSigner == account;
    }
}