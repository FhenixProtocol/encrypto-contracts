// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TaskManager} from "./mocks/MockTaskManager.sol";
import {TASK_MANAGER_ADDRESS} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {ACL} from "./mocks/ACL.sol";
contract FhenixMocks is Test {
    // MOCKS
    TaskManager public tmpTaskManager;
    TaskManager public taskManager;
    ACL public acl;

    address public constant TM_ADMIN = address(128);

    function etchFhenixMocks() internal {
        deployCodeTo(
            "MockTaskManager.sol:TaskManager",
            abi.encode(TM_ADMIN, 0, 1),
            TASK_MANAGER_ADDRESS
        );
        taskManager = TaskManager(TASK_MANAGER_ADDRESS);

        acl = new ACL();
        vm.label(address(acl), "ACL");

        vm.prank(TM_ADMIN);
        taskManager.setACLContract(address(acl));
    }
}
