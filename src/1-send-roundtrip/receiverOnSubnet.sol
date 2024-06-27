// SPDX-License-Identifier: Ecosystem
pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract ReceiverOnSubnet is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    function receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes calldata message)
        external
    {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(messenger), "ReceiverOnSubnet: unauthorized TeleporterMessenger");

        // Decode the incoming message
        (string memory userMessage, bytes memory blsSignature, bytes memory blsPublicKey) = abi.decode(message, (string, bytes, bytes));

        // Mock verification (always returns true)
        bool verificationResult = mockVerifySignature(userMessage, blsSignature, blsPublicKey);

        // Prepare the response message
        string memory response = verificationResult 
            ? "Signature verification successful" 
            : "Signature verification failed";

        // Send the verification result back to the C-chain
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

    function mockVerifySignature(string memory _message, bytes memory _signature, bytes memory _publicKey) 
        internal 
        pure 
        returns (bool) 
    {
        // Mock verification: always return true
        return true;
    }
}