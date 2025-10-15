# Architecture Improvements - Interface Segregation & Dependency Injection

**Date:** 2025-10-15
**Status:** ✅ Implemented
**Related:** IMPROVEMENT_PLAN.md Section 2.1.1

## Overview

This document describes the architectural improvements made to reduce tight coupling between contracts in the NoGame Starknet project. The changes implement **Interface Segregation Principle** and **Facade Pattern** to improve testability, maintainability, and separation of concerns.

## Problem Statement

### Before: Tight Coupling via Monolithic Interface

Previously, all contracts were tightly coupled to the `game_manager` through a single monolithic `IGame` interface:

```cairo
// Every contract had to depend on the entire IGame interface
let game_manager = self.game_manager.read();
let contracts = game_manager.get_contracts();  // Requires full IGame interface
let tokens = game_manager.get_tokens();        // Requires full IGame interface
```

**Issues:**
- **Tight Coupling**: All contracts depended on the entire `IGame` interface even if they only used 1-2 methods
- **Difficult Testing**: Mocking required implementing all 10+ methods of `IGame`
- **Poor Separation of Concerns**: Resource management, token access, configuration, and contract registry all mixed in one interface
- **Unclear Dependencies**: Not obvious which contracts need which functionality

## Solution: Segregated Interfaces

### New Architecture

We split the monolithic `IGame` interface into four focused interfaces:

```
src/game/interfaces/
├── resource_manager.cairo   - Resource minting, burning, validation
├── token_provider.cairo      - Access to ERC20/ERC721 dispatchers
├── universe_config.cairo     - Game-wide configuration (speed, price, time)
└── contract_registry.cairo   - Contract discovery (facade pattern)
```

### 1. IResourceManager

Handles all resource-related operations:

```cairo
#[starknet::interface]
trait IResourceManager<TState> {
    fn pay_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);
    fn receive_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);
    fn check_enough_resources(self: @TState, caller: ContractAddress, amounts: ERC20s);
}
```

**Use Cases:**
- Compound upgrades paying resources
- Planet collecting resources
- Fleet missions transporting resources

### 2. ITokenProvider

Provides access to token dispatchers:

```cairo
#[starknet::interface]
trait ITokenProvider<TState> {
    fn get_tokens(self: @TState) -> Tokens;
}
```

**Use Cases:**
- Getting player's planet ID from ERC721
- Checking resource balances
- Minting/burning tokens

### 3. IUniverseConfig

Game-wide configuration settings:

```cairo
#[starknet::interface]
trait IUniverseConfig<TState> {
    fn get_uni_speed(self: @TState) -> u128;
    fn get_universe_start_time(self: @TState) -> u64;
    fn get_token_price(self: @TState) -> u128;
}
```

**Use Cases:**
- Calculating resource production (needs universe speed)
- Planet pricing (needs start time and token price)
- Time-based mechanics

### 4. IContractRegistry

Contract discovery using facade pattern:

```cairo
#[starknet::interface]
trait IContractRegistry<TState> {
    fn get_contracts(self: @TState) -> Contracts;
}
```

**Use Cases:**
- Cross-contract calls (planet → compound, fleet → dockyard)
- Batch operations across multiple contracts
- Contract verification

## Implementation

### Game Contract Changes

The `Game` contract now implements all four segregated interfaces:

```cairo
#[starknet::contract]
mod Game {
    // ...

    #[abi(embed_v0)]
    impl ResourceManagerImpl of IResourceManager<ContractState> { /* ... */ }

    #[abi(embed_v0)]
    impl TokenProviderImpl of ITokenProvider<ContractState> { /* ... */ }

    #[abi(embed_v0)]
    impl UniverseConfigImpl of IUniverseConfig<ContractState> { /* ... */ }

    #[abi(embed_v0)]
    impl ContractRegistryImpl of IContractRegistry<ContractState> { /* ... */ }

    // Legacy IGame impl (internal only, not exposed in ABI)
    impl GameImpl of super::IGame<ContractState> {
        fn initialize(...) { /* Only method still unique to IGame */ }
        fn upgrade(...) { /* ... */ }
        // Other methods delegate to segregated interfaces
    }
}
```

**Key Points:**
- Segregated interfaces are exposed in the ABI
- Legacy `IGame` is NOT exposed in ABI (no `#[abi(embed_v0)]`)
- Legacy interface kept for internal use and backward compatibility
- All method calls explicitly use trait qualification to avoid ambiguity

### Module Organization

```cairo
// src/game/interfaces.cairo
mod contract_registry;
mod resource_manager;
mod token_provider;
mod universe_config;

pub use contract_registry::{IContractRegistry, IContractRegistryDispatcher, IContractRegistryDispatcherTrait};
pub use resource_manager::{IResourceManager, IResourceManagerDispatcher, IResourceManagerDispatcherTrait};
pub use token_provider::{ITokenProvider, ITokenProviderDispatcher, ITokenProviderDispatcherTrait};
pub use universe_config::{IUniverseConfig, IUniverseConfigDispatcher, IUniverseConfigDispatcherTrait};
```

## Migration Guide

### For New Code

Use the specific interface your contract needs:

```cairo
// Example: Compound contract only needs resource management
use nogame::game::interfaces::{IResourceManagerDispatcher, IResourceManagerDispatcherTrait};

fn process_upgrade(ref self: ContractState, planet_id: u32) {
    let cost = self.calculate_cost(level);
    let game = IResourceManagerDispatcher { contract_address: self.game_manager.read() };
    game.check_enough_resources(caller, cost);
    game.pay_resources_erc20(caller, cost);
}
```

### For Existing Code

Existing code using `IGameDispatcher` continues to work:

```cairo
// This still works (backward compatible)
let game_manager = self.game_manager.read();
let contracts = game_manager.get_contracts();
```

However, consider migrating to segregated interfaces for:
- **Better clarity**: Shows exact dependencies
- **Easier testing**: Mock only what you need
- **Future-proofing**: Legacy interface may be deprecated

### Testing Benefits

Before (mocking IGame):
```cairo
// Had to implement all 10+ methods
#[starknet::interface]
trait IGame<TState> {
    fn initialize(...) -> ...; // Don't need this for test
    fn upgrade(...) -> ...;    // Don't need this for test
    fn pay_resources_erc20(...) -> ...; // Only need this!
    fn receive_resources_erc20(...) -> ...; // And this!
    // ... 6 more methods we don't care about
}
```

After (mocking IResourceManager):
```cairo
// Only implement what you need
#[starknet::interface]
trait IResourceManager<TState> {
    fn pay_resources_erc20(...) -> ...;
    fn receive_resources_erc20(...) -> ...;
    fn check_enough_resources(...) -> ...;
}
```

## Benefits Achieved

### ✅ Reduced Coupling
- Contracts now depend only on interfaces they actually use
- Clear separation of concerns (resource management vs configuration vs contract registry)

### ✅ Improved Testability
- Smaller interfaces easier to mock
- Test only relevant functionality
- Faster test compilation

### ✅ Better Code Organization
- Each interface has a single, well-defined responsibility
- Easier to understand dependencies
- Clearer API boundaries

### ✅ Enhanced Maintainability
- Changes to one interface don't affect contracts using other interfaces
- Easier to add new functionality
- Better documentation through focused interfaces

### ✅ Backward Compatibility
- Existing code continues to work
- Gradual migration possible
- No breaking changes

## Future Improvements

### Phase 1: Contract Migration (Recommended)
Migrate contracts to use segregated interfaces:

1. **Planet Contract**: Migrate to `IResourceManager` + `ITokenProvider` + `IUniverseConfig`
2. **Compound Contract**: Migrate to `IResourceManager` + `IContractRegistry`
3. **Dockyard Contract**: Migrate to `IResourceManager` + `IContractRegistry`
4. **Fleet Movements**: Migrate to `IResourceManager` + `IContractRegistry` + `IUniverseConfig`
5. **Defense Contract**: Migrate to `IResourceManager` + `IContractRegistry`
6. **Tech Contract**: Migrate to `IResourceManager` + `IContractRegistry`
7. **Colony Contract**: Migrate to `IResourceManager` + `IContractRegistry` + `IUniverseConfig`

### Phase 2: Further Interface Segregation
Split `IContractRegistry` into more focused interfaces:

```cairo
trait IPlanetRegistry<TState> {
    fn get_planet_contract(self: @TState) -> IPlanetDispatcher;
}

trait ICompoundRegistry<TState> {
    fn get_compound_contract(self: @TState) -> ICompoundDispatcher;
}

// etc.
```

**Benefits:**
- Even more precise dependencies
- Contracts only get dispatchers they need
- Better security (principle of least privilege)

### Phase 3: Dependency Injection
Store specific dispatchers instead of monolithic game_manager:

```cairo
#[storage]
struct Storage {
    // Instead of:
    // game_manager: IGameDispatcher,

    // Use specific dependencies:
    resource_manager: IResourceManagerDispatcher,
    token_provider: ITokenProviderDispatcher,
    universe_config: IUniverseConfigDispatcher,
}
```

**Benefits:**
- No contract registry needed
- Explicit dependencies in storage
- True dependency injection

## Metrics

### Code Quality Improvements
- **Interface Cohesion**: Increased (4 focused interfaces vs 1 monolithic)
- **Coupling**: Reduced (depends on subset vs entire interface)
- **Testability**: Improved (smaller mocks, faster tests)
- **Documentation**: Better (clear responsibility per interface)

### Deployment Impact
- **Gas Cost**: No change (same underlying implementation)
- **Contract Size**: Negligible increase (~4 additional dispatcher structs)
- **ABI Changes**: Additive only (new interfaces added, old methods still available)

### Migration Effort
- **Breaking Changes**: None
- **Required Updates**: None (optional migration recommended)
- **Testing**: Existing tests pass without modification

## Conclusion

The interface segregation refactoring successfully addresses Section 2.1.1 of the IMPROVEMENT_PLAN.md by:

1. ✅ **Breaking down monolithic interface** into 4 focused interfaces
2. ✅ **Implementing facade pattern** for contract registry
3. ✅ **Maintaining backward compatibility** with legacy interface
4. ✅ **Improving testability** through smaller, focused interfaces
5. ✅ **Setting foundation** for future dependency injection improvements

**Status**: Implementation complete, contracts can now migrate to segregated interfaces at their own pace.

**Next Steps**:
1. Update IMPROVEMENT_PLAN.md to mark Section 2.1.1 as complete
2. Begin migrating contracts to use segregated interfaces (Phase 1)
3. Update tests to use focused mock interfaces
4. Consider Phase 2 (further segregation) and Phase 3 (dependency injection)

---

**Related Files:**
- `src/game/interfaces.cairo` - Interface module definition
- `src/game/interfaces/*.cairo` - Segregated interface definitions
- `src/game/contract.cairo` - Updated Game contract implementation
- `src/lib.cairo` - Updated module imports
