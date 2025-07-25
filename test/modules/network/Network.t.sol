// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {MyNetwork} from "../../../examples/MyNetwork.sol";

import {INetwork} from "../../../src/interfaces/modules/network/INetwork.sol";

import "../../MasterSetup.sol";

import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";

contract NetworkTest is MasterSetupTest {
    using Subnetwork for address;

    MyNetwork private myNetwork;

    address internal admin = address(0xA11CE);
    address internal proposer = address(0xBEEF1);
    address internal proposer2 = address(0xBEEF2);
    address internal executor = address(0xCAFE);

    uint256 constant GLOBAL_MIN_DELAY = 3 days;
    bytes4 constant FOO_SEL = bytes4(keccak256("foo()"));

    function setUp() public override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        MasterSetupTest.setUp();

        myNetwork =
            new MyNetwork(address(symbioticCore.networkRegistry), address(symbioticCore.networkMiddlewareService));

        INetwork.NetworkInitParams memory p;
        p.globalMinDelay = GLOBAL_MIN_DELAY;
        p.proposers = new address[](2);
        p.proposers[0] = proposer;
        p.proposers[1] = proposer2;
        p.executors = new address[](1);
        p.executors[0] = executor;
        p.defaultAdminRoleHolder = admin;
        p.nameUpdateRoleHolder = admin;
        p.metadataURIUpdateRoleHolder = admin;
        p.delayParams = new INetwork.DelayParams[](2);
        p.delayParams[0] = INetwork.DelayParams({
            target: address(symbioticCore.networkMiddlewareService),
            selector: ISymbioticNetworkMiddlewareService.setMiddleware.selector,
            delay: 0
        });
        p.delayParams[1] = INetwork.DelayParams({target: address(0), selector: FOO_SEL, delay: 1 days});
        p.name = "MyNetwork";
        p.metadataURI = "https://";

        myNetwork.initialize(p);

        vm.startPrank(proposer);
        myNetwork.schedule(
            address(symbioticCore.networkMiddlewareService),
            0,
            abi.encodeCall(ISymbioticNetworkMiddlewareService.setMiddleware, (address(this))),
            0,
            bytes32(0),
            0
        );
        vm.stopPrank();

        vm.startPrank(executor);
        myNetwork.execute(
            address(symbioticCore.networkMiddlewareService),
            0,
            abi.encodeCall(ISymbioticNetworkMiddlewareService.setMiddleware, (address(this))),
            0,
            bytes32(0)
        );
        vm.stopPrank();
    }

    function test_Init() public {
        assertEq(myNetwork.NETWORK_REGISTRY(), address(symbioticCore.networkRegistry));
        assertEq(myNetwork.NETWORK_MIDDLEWARE_SERVICE(), address(symbioticCore.networkMiddlewareService));

        assertTrue(myNetwork.hasRole(myNetwork.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(myNetwork.hasRole(myNetwork.NAME_UPDATE_ROLE(), admin));
        assertTrue(myNetwork.hasRole(myNetwork.METADATA_URI_UPDATE_ROLE(), admin));
        assertTrue(myNetwork.hasRole(myNetwork.PROPOSER_ROLE(), proposer));

        assertEq(myNetwork.name(), "MyNetwork");
        assertEq(myNetwork.metadataURI(), "https://");

        assertEq(
            myNetwork.getMinDelay(
                address(symbioticCore.networkMiddlewareService),
                abi.encodeWithSelector(ISymbioticNetworkMiddlewareService.setMiddleware.selector, address(this))
            ),
            0
        );
        assertEq(myNetwork.getMinDelay(address(this), abi.encodeWithSelector(FOO_SEL)), 1 days);

        assertEq(
            myNetwork.getMinDelay(
                address(symbioticCore.networkMiddlewareService),
                abi.encodeWithSelector(ISymbioticNetworkMiddlewareService.setMiddleware.selector, address(this))
            ),
            0
        );
    }

    function testInitializeCantBeCalledTwice() public {
        vm.expectRevert();
        myNetwork.initialize(
            INetwork.NetworkInitParams({
                globalMinDelay: 0,
                proposers: new address[](0),
                executors: new address[](0),
                name: "",
                metadataURI: "",
                defaultAdminRoleHolder: address(0),
                nameUpdateRoleHolder: address(0),
                metadataURIUpdateRoleHolder: address(0),
                delayParams: new INetwork.DelayParams[](0)
            })
        );
    }

    function test_UpdateNameByRoleHolder() public {
        vm.prank(admin);
        myNetwork.updateName("SymbioticNetwork");
        assertEq(myNetwork.name(), "SymbioticNetwork");
    }

    function test_UpdateNameWithoutRoleReverts() public {
        vm.expectRevert();
        myNetwork.updateName("bad");
    }

    function test_UpdateMetadataURI() public {
        string memory uri = "ipfs://foo";
        vm.prank(admin);
        myNetwork.updateMetadataURI(uri);
        assertEq(myNetwork.metadataURI(), uri);
    }

    function test_PerSelectorDelayOverridesGlobal() public {
        uint256 d = myNetwork.getMinDelay(address(this), abi.encodeWithSelector(FOO_SEL));
        assertEq(d, 1 days);
    }

    function test_ScheduleRevertsIfDelayTooShort() public {
        bytes memory payload = abi.encodeWithSelector(FOO_SEL);
        vm.prank(proposer);
        vm.expectRevert();
        myNetwork.schedule(address(this), 0, payload, bytes32(0), bytes32("salt"), 12 hours);
    }

    function test_UpdateDelayThroughTimelock() public {
        uint256 newDelay = 5 days;
        bytes memory callData = abi.encodeWithSelector(
            bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")), address(this), FOO_SEL, true, newDelay
        );

        vm.prank(proposer);
        myNetwork.schedule(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.prank(proposer);
        vm.expectRevert();
        myNetwork.schedule(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.warp(vm.getBlockTimestamp() + GLOBAL_MIN_DELAY);
        vm.prank(executor);
        myNetwork.execute(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"));

        assertEq(myNetwork.getMinDelay(address(this), abi.encodeWithSelector(FOO_SEL)), newDelay);
        assertEq(
            myNetwork.getMinDelay(
                address(myNetwork),
                abi.encodeWithSelector(
                    bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")), address(this), FOO_SEL, false, 0
                )
            ),
            newDelay
        );
        vm.expectRevert(INetwork.InvalidTargetAndSelector.selector);
        myNetwork.getMinDelay(
            address(myNetwork),
            abi.encodeWithSelector(
                bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")),
                address(myNetwork),
                bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")),
                false,
                0
            )
        );
    }

    function test_UpdateDelayThroughTimelock_ZeroAddress() public {
        uint256 newDelay = 7 days;
        bytes memory callData = abi.encodeWithSelector(
            bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")), address(0), FOO_SEL, true, newDelay
        );

        vm.prank(proposer);
        myNetwork.schedule(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.prank(proposer);
        vm.expectRevert();
        myNetwork.schedule(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.warp(vm.getBlockTimestamp() + GLOBAL_MIN_DELAY);
        vm.prank(executor);
        myNetwork.execute(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"));

        assertEq(myNetwork.getMinDelay(address(this), abi.encodeWithSelector(FOO_SEL)), newDelay);
        vm.expectRevert(INetwork.InvalidTargetAndSelector.selector);
        myNetwork.getMinDelay(address(0), abi.encodeWithSelector(FOO_SEL));
        assertEq(
            myNetwork.getMinDelay(
                address(myNetwork),
                abi.encodeWithSelector(
                    bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")), address(this), FOO_SEL, false, 0
                )
            ),
            newDelay
        );
    }

    function test_UpdateDelayThroughTimelock_ZeroSelector() public {
        uint256 newDelay = 5 days;
        bytes memory callData = abi.encodeWithSelector(
            bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")), address(this), bytes4(0), true, newDelay
        );

        vm.prank(proposer);
        myNetwork.schedule(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.prank(proposer);
        vm.expectRevert();
        myNetwork.schedule(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.warp(vm.getBlockTimestamp() + GLOBAL_MIN_DELAY);
        vm.prank(executor);
        myNetwork.execute(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"));

        assertEq(myNetwork.getMinDelay(address(this), abi.encodeWithSelector(bytes4(0))), newDelay);
        assertEq(
            myNetwork.getMinDelay(
                address(myNetwork),
                abi.encodeWithSelector(
                    bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")), address(this), bytes4(0), false, 0
                )
            ),
            newDelay
        );
        vm.expectRevert(INetwork.InvalidTargetAndSelector.selector);
        myNetwork.getMinDelay(
            address(myNetwork),
            abi.encodeWithSelector(
                bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")),
                address(myNetwork),
                bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")),
                false,
                0
            )
        );
    }

    function test_UpdateDelayThroughTimelock_RevertInvalidNewDelay() public {
        uint256 newDelay = 5 days;
        bytes memory callData = abi.encodeWithSelector(
            bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")), address(this), FOO_SEL, false, newDelay
        );

        vm.prank(proposer);
        myNetwork.schedule(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.warp(vm.getBlockTimestamp() + GLOBAL_MIN_DELAY);
        vm.prank(executor);
        vm.expectRevert(INetwork.InvalidNewDelay.selector);
        myNetwork.execute(address(myNetwork), 0, callData, bytes32(0), bytes32("salt42"));
    }

    function test_DirectUpdateDelayReverts() public {
        vm.expectRevert();
        myNetwork.updateDelay(address(this), FOO_SEL, true, 7 days);
    }

    function test_SetMaxNetworkLimitOnlyMiddleware() public {
        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        vm.prank(address(this));
        myNetwork.setMaxNetworkLimit(ISymbioticVault(vaults[0]).delegator(), 1, type(uint96).max);

        assertEq(
            ISymbioticBaseDelegator(ISymbioticVault(vaults[0]).delegator()).maxNetworkLimit(
                address(myNetwork).subnetwork(uint96(1))
            ),
            type(uint96).max
        );
    }

    function test_SetMaxNetworkLimitWrongCallerReverts() public {
        vm.expectRevert();
        vm.prank(admin);
        myNetwork.setMaxNetworkLimit(address(1), 1, 1);
    }

    function test_GetMinDelayInvalidSelectorReverts() public {
        vm.expectRevert(INetwork.InvalidDataLength.selector);
        myNetwork.getMinDelay(address(0), new bytes(1));
    }

    function test_ScheduleBatchLengthMismatchReverts() public {
        address[] memory targets = new address[](1);
        targets[0] = address(this);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encodeWithSelector(FOO_SEL);

        vm.prank(proposer);
        vm.expectRevert();
        myNetwork.scheduleBatch(targets, values, payloads, bytes32(0), bytes32("BAD_LEN"), 0);
    }

    function test_ScheduleBatchRevertsIfDelayTooShort() public {
        address[] memory targets = new address[](2);
        targets[0] = address(symbioticCore.networkMiddlewareService);
        targets[1] = address(this);

        uint256[] memory values = new uint256[](2);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeCall(ISymbioticNetworkMiddlewareService.setMiddleware, (address(this)));
        payloads[1] = abi.encodeWithSelector(FOO_SEL);

        vm.prank(proposer);
        vm.expectRevert();
        myNetwork.scheduleBatch(targets, values, payloads, bytes32(0), bytes32("SHORT"), 12 hours);
    }

    function test_ScheduleBatchAndExecute() public {
        address[] memory targets = new address[](2);
        targets[0] = address(symbioticCore.networkMiddlewareService);
        targets[1] = address(myNetwork);

        uint256[] memory values = new uint256[](2);

        uint256 newSelectorDelay = 5 days;

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeCall(ISymbioticNetworkMiddlewareService.setMiddleware, (address(4)));
        payloads[1] = abi.encodeWithSelector(
            bytes4(keccak256("updateDelay(address,bytes4,bool,uint256)")),
            address(this),
            FOO_SEL,
            true,
            newSelectorDelay
        );

        bytes32 salt = bytes32("BATCH_OK");
        uint256 delay = 2 days;

        vm.prank(proposer);
        myNetwork.scheduleBatch(targets, values, payloads, bytes32(0), salt, delay);

        vm.warp(vm.getBlockTimestamp() + delay);
        vm.prank(executor);
        myNetwork.executeBatch(targets, values, payloads, bytes32(0), salt);

        assertEq(myNetwork.getMinDelay(address(this), abi.encodeWithSelector(FOO_SEL)), newSelectorDelay);
    }

    function test_EthTransfer() public {
        uint256 amount = 100 ether;

        deal(address(myNetwork), amount);

        vm.prank(proposer);
        myNetwork.schedule(address(1), amount, new bytes(0), bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        vm.prank(proposer);
        vm.expectRevert();
        myNetwork.schedule(address(1), amount, new bytes(0), bytes32(0), bytes32("salt42"), GLOBAL_MIN_DELAY);

        uint256 balanceBefore = address(1).balance;

        vm.warp(vm.getBlockTimestamp() + GLOBAL_MIN_DELAY);
        vm.prank(executor);
        myNetwork.execute(address(1), amount, new bytes(0), bytes32(0), bytes32("salt42"));

        assertEq(address(1).balance - balanceBefore, amount);

        assertEq(myNetwork.getMinDelay(address(1), new bytes(0)), GLOBAL_MIN_DELAY);
    }
}
