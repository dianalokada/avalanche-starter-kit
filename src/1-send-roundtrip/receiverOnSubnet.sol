// SPDX-License-Identifier: Ecosystem
pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

interface IBLSSignatureVerifier {
    function verifyBLSSignature(
        string calldata message,
        bytes calldata signature,
        bytes calldata publicKey
    ) external view returns (bool isValid);
}

contract ReceiverOnSubnet is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);
    
    IBLSSignatureVerifier private constant BLS_VERIFIER = IBLSSignatureVerifier(0x0000000000000000000000000000000000000810); // Replace with the actual precompile address

    function receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes calldata message)
        external
    {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(messenger), "ReceiverOnSubnet: unauthorized TeleporterMessenger");

        // Decoding the incoming message
        (string memory userMessage, bytes memory blsSignature, bytes memory blsPublicKey) =
            abi.decode(message, (string, bytes, bytes));

        // Verifying the signature
        bool verificationResult = verifySignature(userMessage, blsSignature, blsPublicKey);
        
        // The response message
        string memory response =
            verificationResult ? "Signature verification successful" : "Signature verification failed";

        // Sends the verification result back to the C-chain
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: sourceBlockchainID,
                destinationAddress: originSenderAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(response)
            })
        );
    }

    function verifySignature(string memory _message, bytes memory _signature, bytes memory _publicKey)
        internal
        view
        returns (bool)
    {
        return BLS_VERIFIER.verifyBLSSignature(_message, _signature, _publicKey);
    }
}