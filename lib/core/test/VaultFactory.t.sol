// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {VaultFactory} from "src/contracts/VaultFactory.sol";
import {DelegatorFactory} from "src/contracts/DelegatorFactory.sol";
import {SlasherFactory} from "src/contracts/SlasherFactory.sol";
import {NetworkRegistry} from "src/contracts/NetworkRegistry.sol";
import {OperatorRegistry} from "src/contracts/OperatorRegistry.sol";
import {MetadataService} from "src/contracts/service/MetadataService.sol";
import {NetworkMiddlewareService} from "src/contracts/service/NetworkMiddlewareService.sol";
import {OptInService} from "src/contracts/service/OptInService.sol";

import {Vault} from "src/contracts/vault/Vault.sol";
import {NetworkRestakeDelegator} from "src/contracts/delegator/NetworkRestakeDelegator.sol";
import {FullRestakeDelegator} from "src/contracts/delegator/FullRestakeDelegator.sol";
import {Slasher} from "src/contracts/slasher/Slasher.sol";
import {VetoSlasher} from "src/contracts/slasher/VetoSlasher.sol";

import {IVault} from "src/interfaces/vault/IVault.sol";
import {SimpleCollateral} from "./mocks/SimpleCollateral.sol";
import {Token} from "./mocks/Token.sol";
import {VaultConfigurator} from "src/contracts/VaultConfigurator.sol";
import {IVaultConfigurator} from "src/interfaces/IVaultConfigurator.sol";
import {INetworkRestakeDelegator} from "src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IFullRestakeDelegator} from "src/interfaces/delegator/IFullRestakeDelegator.sol";
import {IBaseDelegator} from "src/interfaces/delegator/IBaseDelegator.sol";

contract VaultFactoryTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    VaultFactory vaultFactory;
    DelegatorFactory delegatorFactory;
    SlasherFactory slasherFactory;
    NetworkRegistry networkRegistry;
    OperatorRegistry operatorRegistry;
    MetadataService operatorMetadataService;
    MetadataService networkMetadataService;
    NetworkMiddlewareService networkMiddlewareService;
    OptInService operatorVaultOptInService;
    OptInService operatorNetworkOptInService;

    SimpleCollateral collateral;
    VaultConfigurator vaultConfigurator;

    function setUp() public {
        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vaultFactory = new VaultFactory(owner);
        delegatorFactory = new DelegatorFactory(owner);
        slasherFactory = new SlasherFactory(owner);
        networkRegistry = new NetworkRegistry();
        operatorRegistry = new OperatorRegistry();
        operatorMetadataService = new MetadataService(address(operatorRegistry));
        networkMetadataService = new MetadataService(address(networkRegistry));
        networkMiddlewareService = new NetworkMiddlewareService(address(networkRegistry));
        operatorVaultOptInService = new OptInService(address(operatorRegistry), address(vaultFactory));
        operatorNetworkOptInService = new OptInService(address(operatorRegistry), address(networkRegistry));

        address vaultImpl =
            address(new Vault(address(delegatorFactory), address(slasherFactory), address(vaultFactory)));
        vaultFactory.whitelist(vaultImpl);

        address networkRestakeDelegatorImpl = address(
            new NetworkRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(networkRestakeDelegatorImpl);

        address fullRestakeDelegatorImpl = address(
            new FullRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(fullRestakeDelegatorImpl);

        address slasherImpl = address(
            new Slasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(slasherImpl);

        address vetoSlasherImpl = address(
            new VetoSlasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(networkRegistry),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(vetoSlasherImpl);

        Token token = new Token("Token");
        collateral = new SimpleCollateral(address(token));

        collateral.mint(token.totalSupply());

        vaultConfigurator =
            new VaultConfigurator(address(vaultFactory), address(delegatorFactory), address(slasherFactory));
    }

    function test_Create() public {
        address[] memory networkLimitSetRoleHolders = new address[](1);
        networkLimitSetRoleHolders[0] = alice;
        address[] memory operatorNetworkSharesSetRoleHolders = new address[](1);
        operatorNetworkSharesSetRoleHolders[0] = alice;
        (address vault_,,) = vaultConfigurator.create(
            IVaultConfigurator.InitParams({
                version: 1,
                owner: alice,
                vaultParams: IVault.InitParams({
                    collateral: address(collateral),
                    delegator: address(0),
                    slasher: address(0),
                    burner: address(0xdEaD),
                    epochDuration: 1,
                    depositWhitelist: false,
                    defaultAdminRoleHolder: alice,
                    depositWhitelistSetRoleHolder: alice,
                    depositorWhitelistRoleHolder: alice
                }),
                delegatorIndex: 0,
                delegatorParams: abi.encode(
                    INetworkRestakeDelegator.InitParams({
                        baseParams: IBaseDelegator.BaseParams({
                            defaultAdminRoleHolder: alice,
                            hook: address(0),
                            hookSetRoleHolder: alice
                        }),
                        networkLimitSetRoleHolders: networkLimitSetRoleHolders,
                        operatorNetworkSharesSetRoleHolders: operatorNetworkSharesSetRoleHolders
                    })
                ),
                withSlasher: false,
                slasherIndex: 0,
                slasherParams: ""
            })
        );

        assertEq(Vault(vault_).FACTORY(), address(vaultFactory));
        assertEq(vaultFactory.isEntity(vault_), true);
    }
}
