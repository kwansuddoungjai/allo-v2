// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Core Strategy Interfaces
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Strategy Contracts
import {DonationVotingStrategy} from "../../../contracts/strategies/donation-voting/DonationVotingStrategy.sol";
import {DonationVotingCustomRegistryStrategy} from
    "../../../contracts/strategies/donation-voting-custom-registry/DonationVotingCustomRegistryStrategy.sol";
import {DonationVotingStrategyTest} from "./DonationVotingStrategy.t.sol";
import {SimpleProjectRegistry} from
    "../../../contracts/strategies/donation-voting-custom-registry/SimpleProjectRegistry.sol";
// Internal Core libraries
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

contract DonationVotingCustomRegistryStrategyTest is Test, DonationVotingStrategyTest {
    SimpleProjectRegistry customRegistry;

    /// @notice Sets up the test
    function setUp() public override {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        customRegistry = new SimpleProjectRegistry(local());
        customRegistry.addProject(recipient());

        registrationStartTime = block.timestamp + 10;
        registrationEndTime = block.timestamp + 300;
        allocationStartTime = block.timestamp + 301;
        allocationEndTime = block.timestamp + 600;

        useRegistryAnchor = true;
        metadataRequired = true;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        address payable _strategy = payable(
            address(
                new DonationVotingCustomRegistryStrategy(
                address(allo()),
                "DonationVotingStrategy"
                )
            )
        );
        strategy = DonationVotingStrategy(_strategy);

        allowedTokens = new address[](1);
        allowedTokens[0] = address(0);

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                address(customRegistry),
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    /// @notice Tests that the strategy can be initialized with a custom registry
    function test_initialize_registry() public {
        assertEq(
            address(DonationVotingCustomRegistryStrategyTest(address(strategy)).registry()), address(customRegistry)
        );
    }

    /// @notice Tests that the strategy can be initialized only once
    function test_initialize_custom_registry_ALREADY_INITIALIZED() public {
        DonationVotingStrategy testStrategy =
            new DonationVotingCustomRegistryStrategy(address(allo()), "testing registry");

        // vm.expectRevert(ALREADY_INITIALIZED.selector);
        vm.prank(address(pool_admin()));
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(testStrategy),
            abi.encode(
                address(testStrategy),
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );

        vm.expectRevert(ALREADY_INITIALIZED.selector);
        vm.prank(address(allo()));
        testStrategy.initialize(
            777,
            abi.encode(
                address(testStrategy),
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );
    }

    /// @notice Tests that the strategy cannot be initailized with an invalid strategy address
    function test_initialize_custom_registry_INVALID_ADDRESS() public {
        DonationVotingStrategy testStrategy =
            new DonationVotingCustomRegistryStrategy(address(allo()), "testing registry");

        vm.expectRevert(INVALID_ADDRESS.selector);
        vm.prank(address(pool_admin()));
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(testStrategy),
            abi.encode(
                address(0),
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            ),
            NATIVE,
            0,
            poolMetadata,
            pool_managers()
        );
    }

    /// @notice Tests that the allocate reverts when token is invalid
    function testRevert_allocate_INVALID_invalidToken() public override {
        allowedTokens = new address[](1);
        allowedTokens[0] = makeAddr("token");

        address payable _strategy = payable(
            address(
                new DonationVotingCustomRegistryStrategy(
                address(allo()),
                "DonationVotingStrategy"
                )
            )
        );
        strategy = DonationVotingStrategy(_strategy);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                address(customRegistry),
                metadataRequired,
                registrationStartTime,
                registrationEndTime,
                allocationStartTime,
                allocationEndTime,
                allowedTokens
            )
        );

        address recipientId = __register_accept_recipient();
        vm.expectRevert(INVALID.selector);

        vm.warp(allocationStartTime + 10);

        address allocator = makeAddr("allocator");
        bytes memory allocateData = abi.encode(recipientId, 1e18, NATIVE);
        vm.prank(address(allo()));
        strategy.allocate(allocateData, allocator);
    }

    /// @notice Helper to return abi.encoded data
    function __getEncodedData(address _recipientAddress, uint256 _protocol, string memory _pointer)
        internal
        override
        returns (bytes memory data)
    {
        Metadata memory metadata = Metadata({protocol: _protocol, pointer: _pointer});
        data = abi.encode(recipient(), _recipientAddress, metadata);
    }
}
