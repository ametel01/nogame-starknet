/// Segregated interfaces for the Game contract following Interface Segregation Principle
///
/// This module breaks down the monolithic IGame interface into smaller, focused interfaces:
/// - IResourceManager: Resource minting, burning, and validation
/// - ITokenProvider: Access to token dispatchers
/// - IUniverseConfig: Game-wide configuration
/// - IContractRegistry: Contract discovery (facade pattern)
///
/// Benefits:
/// - Reduced coupling between contracts
/// - Easier testing and mocking
/// - Clearer dependency requirements
/// - Better separation of concerns

mod contract_registry;
mod resource_manager;
mod token_provider;
mod universe_config;

// Re-export for convenience
pub use contract_registry::{
    IContractRegistry, IContractRegistryDispatcher, IContractRegistryDispatcherTrait,
};
pub use resource_manager::{
    IResourceManager, IResourceManagerDispatcher, IResourceManagerDispatcherTrait,
};
pub use token_provider::{ITokenProvider, ITokenProviderDispatcher, ITokenProviderDispatcherTrait};
pub use universe_config::{
    IUniverseConfig, IUniverseConfigDispatcher, IUniverseConfigDispatcherTrait,
};
