// SPDX-License-Identifier: Ecosystem
pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

// declare the contract and indicate it implements ITeleporterReceiver
contract SenderOnCChain is ITeleporterReceiver {
    // This line declares and initializes the messenger variable with a specific address
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    // This line declares a public string variable to store the verification result
    string public verificationResult;

    // Event to log the verification result
    event VerificationReceived(string result);

    // This function sends a message with a BLS signature and public key to a subnet
    function sendMessageWithSignature(
        address destinationAddress,
        string memory message,
        bytes memory blsSignature,
        bytes memory blsPublicKey
    ) external {
        // This calls the sendCrossChainMessage function of the receiverOnSubnet contract
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Replace with blockchainID of your Subnet (see instructions in Readme)
                destinationBlockchainID: 0x38c1762345634168bdc821af5df172d9c0e7b7c9ffcf06d63a1367602ab94e12,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message, blsSignature, blsPublicKey)
            })
        );
    }

    // This function receives a Teleporter message
    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        // Only the Teleporter receiver can deliver a message and this line ensures that only the authorized messenger can call this function
        require(msg.sender == address(messenger), "SenderOnCChain: unauthorized TeleporterMessenger");

        // This line decodes the received message and stores it in verificationResult
        verificationResult = abi.decode(message, (string));

        // Emit an event with the verification result
        emit VerificationReceived(verificationResult);
    }
}
