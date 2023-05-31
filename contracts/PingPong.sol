// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "quantum-portal-smart-contracts/contracts/quantumPortal/poc/IQuantumPortalPoc.sol";
import "quantum-portal-smart-contracts/contracts/quantumPortal/poc/IQuantumPortalFeeManager.sol";

/**
 * @title Pong
 * @dev A smart contract that handles pinging and ponging between contracts using Quantum Portal.
 */
contract Pong  {
    uint256 public CHAIN_ID;
    IQuantumPortalPoc public portal;
    mapping (address => uint) public pings;
    address public pingContract;

    constructor() {
        initialize();
    }

    /**
     * @dev Initializes the Pong contract.
     */
    function initialize() internal virtual {
        uint256 overrideChainID; // for test only. provide 0 outside a test
        address portal_address;
        portal = IQuantumPortalPoc(portal_address);
        CHAIN_ID = overrideChainID == 0 ? block.chainid : overrideChainID;
    }

    /**
     * @notice This function should be called by the QuantumPortal.
     * @dev Handles the ping event triggered by the QuantumPortal.
     */
    function pingRemote() external {
        // caller is QP
        (uint netId, address sourceMsgSender, address beneficiary) = portal.msgSender();
        // ensure the caller is the ping contract
        require(sourceMsgSender == pingContract, "Caller not expected!");
        pings[sourceMsgSender] += 1;
    }

    /**
     * @dev Sends a pong response to the recipient on a specific chain.
     * @param recipient The address of the recipient to send the pong response.
     * @param chainId The ID of the chain on which the pong response is sent.
     */
    function pong(address recipient, uint256 chainId) external {
        pings[recipient] -= 1;
        bytes memory method = abi.encodeWithSelector(Ping.remotePong.selector);
        // Call the QuantumPortal to run the specified method on the given chain and contract
        portal.run(
            uint64(chainId), pingContract, msg.sender, method);
    }

    /**
     * @dev Sets the address of the ping contract.
     * @param contractAddress The address of the ping contract.
     */
    function setPingContractAddress(address contractAddress) external {
        pingContract = contractAddress;
    }
}

/**
 * @title Ping
 * @dev A smart contract that handles pinging and ponging between contracts using Quantum Portal.
 */
contract Ping {
    IQuantumPortalPoc public portal;
    uint256 public MASTER_CHAIN_ID = 26000; // The FRM chain ID
    address public PongContract;
    mapping (address => uint) public pongs;

    constructor() {
        initialize();
    }

    /**
     * @dev Initializes the Ping contract.
     */
    function initialize() internal virtual {
        uint256 overrideChainID; // for test only. provide 0 outside a test
        address portal_address;
        portal = IQuantumPortalPoc(portal_address);
    }

    /**
     * @dev Initiates the ping event.
     */
    function ping() external {
        bytes memory method = abi.encodeWithSelector(Pong.pingRemote.selector);
        portal.run(
            0, uint64(MASTER_CHAIN_ID), PongContract, msg.sender, method);
    }

    /**
     * @dev Handles the pong event triggered by the QuantumPortal.
     * @param recipient The address of the recipient of the pong event.
     */
    function remotePong(address recipient) external {
        pongs[recipient] += 1;
    }
}