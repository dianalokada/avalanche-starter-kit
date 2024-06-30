# Cross-Chain BLS Signature Verification dApp (Part 1)

### Part 1: Create a Cross-Chain dApp with Verification

This repository contains the implementation of creating a Cross-Chain BLS Signature Verification dApp using the Avalanche platform. We will set up a local Avalanche network, deploy a Subnet, and create a dApp on the local C-Chain that sends messages to the Subnet. The Subnet will verify the BLS signatures and send back the result to the C-Chain.

### Goal

Deploy a Subnet to a local network. The dApp on the local C-Chain needs to send a message containing some message, a BLS signature, and a BLS public key to your Subnet. The Subnet needs to verify the signature and send a message back to the C-Chain informing the result of the verification. 

Part 2 of this assessment is located here: [Creating a Signature Verification Precompile Contract](https://github.com/dianalokada/my-precompile-evm).


## Learn about Cross-Subnet dApps with Teleporter

To get a better understanding of Cross-Subnet dApps architecture, take the Avalanche Academy course on [Cross-Subnet dApps with Teleporter](https://academy.avax.network/course/teleporter).

### Local Network

For convenience the private key 56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027 of the default airdrop address is stored in the environment variable $PK. Furthermore, the RPC-url for the C-Chain of your local network is set in the foundry.toml file.

## Environment Setup

This starter kit will get you started with developing solidity smart contract dApps on the C-Chain and on an Avalanche Subnet. It includes:

- **Avalanche CLI**: Run a local Avalanche Network
- **Foundry**:
  - Forge: Compile and Deploy smart contracts to the local network, Fuji Testnet or Mainnet
  - Cast: Interact with these smart contracts
- **Teleporter**: All contracts you may want to interact with Teleporter
- **AWM Relayer**: The binary to run your own relayer

This starter kit utilizes a Dev Container specification. Dev Containers use containerization to create consistent and isolated development environments. All of the above mentioned components are pre-installed in that container. These containers can be run using GitHub Codespaces or locally using Docker and VS Code. You can switch back and forth between the two options.

### Run on Github Codespace

You can run them directly on Github by clicking **Code**, switching to the **Codespaces** tab and clicking **Create codespace on main**. A new window will open that loads the codespace. Afterwards you will see a browser version of VS code with all the dependencies installed. Codespace time out after some time of inactivity, but can be restarted.

### Run Dev Container locally with Docker

Alternatively, you can run them locally. You need docker installed and VS Code with the extensions Dev Container extension. Then clone the repository and open it in VS Code. VS Code will ask you if you want to reopen the project in a container.

To make sure that all the submodules are cloned please use `git clone --recurse-submodules` instead of `git clone`

If you are running on Apple Silicon you may run into issues while opening and running your dev container in VSCode. The issue resides in Foundry platform targeting. The fix is currently in draft: foundry-rs/foundry#7512

To workaround, please edit the file Dockerfile to include --platform linux/amd64 before pulling Foundry.

```bash
# .devcontainer/Dockerfile
FROM avaplatform/avalanche-cli:latest as avalanche-cli
FROM avaplatform/awm-relayer:latest as awm-relayer
FROM --platform=linux/amd64 ghcr.io/foundry-rs/foundry:latest as foundry
...
```

## Starting a local Avalanche Network

To start a local Avalanche network with your own teleporter-enabled Subnet inside the container follow these commands. 

First let's create out Subnet configuration. Follow the dialog and if you don't have special requirements for precompiles just follow the suggested options. For the Airdrop of the native token select "Airdrop 1 million tokens to the default ewoq address (do not use in production)". Keep the name "mysubnet" to avoid additional configuration.
```bash
? Choose your VM:
✔ Subnet-EVM
? What version of Subnet-EVM would you like?:
✔ Use latest release version
? Would you like to enable Teleporter on your VM?:
✔ Yes
? Would you like to run AMW Relayer when deploying your VM?:
✔ Yes
Installing subnet-evm-v0.6.4...
subnet-evm-v0.6.4 installation successful
creating genesis for subnet mysubnet
Enter your subnet's ChainId. It can be any positive integer.
ChainId: 012345
Select a symbol for your subnet's native token
Token symbol: NATV
? How would you like to set fees:
✔ Low disk use    / Low Throughput    1.5 mil gas/s (C-Chain's setting)
? How would you like to distribute funds:
✔ Airdrop 1 million tokens to the default ewoq address (do not use in production)
prefunding address 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC with balance 1000000000000000000000000
? Advanced: Would you like to add a custom precompile to modify the EVM?:
✔ No
✓ Successfully created subnet configuration
```

```bash
avalanche subnet create mysubnet
```

Now let's spin up the local Avalanche network and deploy our Subnet. This will also deploy the Teleporter messenger and the registry on our Subnet and the C-Chain.

```bash
avalanche subnet deploy mysubnet
```

```bash
? Choose a network for the operation:
✔ Local Network
Deploying [mysubnet] to Local Network
```

Make sure to add the RPC Url to the `foundry.toml` file if you have chosen a different name than `mysubnet`. If you've used `mysubnet` the rpc is already configured.

```toml
[rpc_endpoints]
local-c = "http://localhost:9650/ext/bc/C/rpc"
mysubnet = "http://localhost:9650/ext/bc/mysubnet/rpc"
anothersubnet = "http://localhost:9650/ext/bc/BASE58_BLOCKCHAIN_ID/rpc"
```

### Setting the Blockchain ID in the Contracts

Find the blockchainID of your Subnet with this command:

```bash
avalanche subnet describe mysubnet
```

Make sure to replace the blockchainID in the sender contract `src/1-send-roundtrip/senderOnCChain.sol` with the ID of your Subnet's blockchain.

> :no_entry_sign: blockchainID of Subnet ≠ chainID of Subnet

Take the HEX blockchain ID and replace it sender contract:

```solidity
teleporterMessenger.sendCrossChainMessage(
    TeleporterMessageInput({
        // Replace with blockchainID of your Subnet (see instructions in Readme)
        destinationBlockchainID: 0x92756d698399805f0088fc07fc42af47c67e1d38c576667ac6c7031b8df05293,
        destinationAddress: destinationAddress,
        
        // ...
    })
);
```

### Deploying the Contracts

After adapting the contracts you can deploy them with `forge create`:

```bash
forge create --rpc-url local-c --private-key $PK src/1-send-roundtrip/senderOnCChain.sol:SenderOnCChain

```

```bash
forge create --rpc-url mysubnet --private-key $PK src/1-send-roundtrip/receiverOnSubnet.sol:ReceiverOnSubnet

```

### Sending a Message

Use `cast send` to send a message from the C-Chain to the Subnet.
You can find `<sender_contract_address>` in the output of the first and the `<receiver_contract_address>` of the second `forge create` command in the line saying `Deployed to:`.

```bash
cast send <sender_contract_address> "sendMessageWithSignature(address,string,bytes,bytes)" <receiver_contract_address> "hello" 0x00 0x00 --rpc-url local-c --private-key $PK
```

### Verifying Message Receipt

Use `cast call` to receive verification result on the C-Chain.

```bash
cast call <sender_contract_address> "verificationResult()(string)" --rpc-url local-c
```
