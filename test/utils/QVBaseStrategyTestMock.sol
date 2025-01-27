// SPDX-License Identifier: MIT
pragma solidity 0.8.19;

import {QVBaseStrategy} from "../../contracts/strategies/qv-base/QVBaseStrategy.sol";

contract QVBaseStrategyTestMock is QVBaseStrategy {
    constructor(address allo, string memory name) QVBaseStrategy(allo, name) {}

    /// @notice Returns if the recipient is accepted
    /// @return true if the recipient is accepted
    function _isAcceptedRecipient(address) internal pure override returns (bool) {
        return true;
    }

    function _isValidAllocator(address) internal view virtual override returns (bool) {
        return true;
    }

    function _hasVoiceCreditsLeft(uint256, uint256) internal pure override returns (bool) {
        return true;
    }

    function initialize(uint256 _poolId, bytes memory _data) public virtual override onlyAllo {
        (
            bool _registryGating,
            bool _metadataRequired,
            uint256 _reviewThreshold,
            uint256 _registrationStartTime,
            uint256 _registrationEndTime,
            uint256 _allocationStartTime,
            uint256 _allocationEndTime
        ) = abi.decode(_data, (bool, bool, uint256, uint256, uint256, uint256, uint256));
        __QVBaseStrategy_init(
            _poolId,
            _registryGating,
            _metadataRequired,
            _reviewThreshold,
            _registrationStartTime,
            _registrationEndTime,
            _allocationStartTime,
            _allocationEndTime
        );
    }

    function _allocate(bytes memory _data, address _sender) internal virtual override {
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        // for coverage reasons
        if (_hasVoiceCreditsLeft(0, 0)) {
            _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);
        }
    }
}
