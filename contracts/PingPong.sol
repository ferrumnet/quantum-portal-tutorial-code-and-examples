// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "quantum-portal-smart-contracts/contracts/quantumPortal/poc/IQuantumPortalPoc.sol";
import "quantum-portal-smart-contracts/contracts/quantumPortal/poc/IQuantumPortalFeeManager.sol";

contract Pong  {
    uint256 public CHAIN_ID;
    IQuantumPortalPoc public portal;
    mapping (address => uint) public pings;
    address public pingContract;

    constructor() {
        initialize();
    }

    function initialize() internal virtual {
        uint256 overrideChainID; // for test only. provide 0 outside a test
        address portal_address;
        portal = IQuantumPortalPoc(portal_address);
        CHAIN_ID = overrideChainID == 0 ? block.chainid : overrideChainID;
    }

    /**
     @notice This function should be called by the QuantumPortal
     */
    function pingRemote() external {
        // caller is QP
        (uint netId, address sourceMsgSender, address beneficiary) = portal.msgSender();
        // ensure the caller is the ping contract
        require(sourceMsgSender == pingContract, "Caller not expected!");
        pings[sourceMsgSender] += 1;
    }

    function pong(address recipient, uint256 chainId) external {
        pings[recipient] -= 1;
        bytes memory method = abi.encodeWithSelector(Ping.remotePong.selector);
        portal.run(
            0, uint64(chainId), pingContract, msg.sender, method);
    }

    function setPingContractAddress(address contractAddress) external {
        pingContract = contractAddress;
    }
}

contract Ping {
    IQuantumPortalPoc public portal;
    uint256 public MASTER_CHAIN_ID = 26000; // The FRM chain ID
    address public PongContract;
    mapping (address => uint) public pongs;

    constructor() {
        initialize();
    }

    function initialize() internal virtual {
        uint256 overrideChainID; // for test only. provide 0 outside a test
        address portal_address;
        portal = IQuantumPortalPoc(portal_address);
    }

    function ping() external {
        bytes memory method = abi.encodeWithSelector(Pong.pingRemote.selector);
        portal.run(
            0, uint64(MASTER_CHAIN_ID), PongContract, msg.sender, method);
    }

    function remotePong (address recipient) external {
        pongs[recipient] += 1;
    }
}
