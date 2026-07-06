# Multi-Universe Deployment Lifecycle Spike

## Summary

The current NoGame deployment lifecycle creates one universe by deploying one complete set of contracts, initializing one `Game` registry with those addresses, and persisting the latest addresses into one environment file. The quarterly "new universe" roadmap item needs an explicit lifecycle decision before code changes, because the choice determines whether universe identity lives in deployment artifacts, a new onchain factory/registry, or versioned configuration around shared contracts.

Recommendation: use a redeploy-all lifecycle for the first quarterly universe, with a small offchain manifest convention as the immediate follow-up. Defer a registry/factory until the frontend, indexer, and deployment process have one real multi-universe manifest to prove the read model and switching behavior.

## Current Lifecycle

### Deployment Order

`DEPLOYMENT.md` and `scripts/deploy-starknet.sh` define a fixed deployment order:

1. Deploy `Game` with the deployer owner.
2. Deploy `Colony`, `Compound`, `Defence`, `Dockyard`, `FleetMovements`, `Planet`, and `Tech` with the deployer and `GAME_ADDRESS`.
3. Deploy `ERC721NoGame` with `PLANET_ADDRESS`.
4. Deploy the Steel, Quartz, and Tritium `ERC20NoGame` resource tokens with `PLANET_ADDRESS`.
5. Use Katana ETH for local/docker deployments, or deploy `ERC20Upgradeable` ETH for remote test deployments.
6. Call `Game.initialize(...)` with all deployed contract addresses plus `UNI_SPEED` and `TOKEN_PRICE`.

The test helper mirrors this order in `tests/utils.cairo`: `set_up()` declares and deploys every contract, and `init_game()` initializes `Game` before seeded gameplay state is created.

### Initialization

`Game.initialize` is now owner-only and one-time. It writes the contract registry, token dispatchers, token price, universe speed, and `universe_start_time`, then marks `initialized = true`. A second initialization fails with `Game:E_ALREADY_INITIALIZED`.

This means a new universe cannot be represented by reinitializing the same `Game` contract with new addresses. A universe lifecycle has to either deploy a fresh `Game`, introduce a new registry/factory layer, or change the storage model so one contract can address multiple universe versions.

### Address Persistence

The deployment script persists the latest deployed addresses into the selected env file:

- `.env.local`, `.env.sepolia`, or `.env.mainnet` for direct environments.
- `.env.docker`, plus a sync to `.env.local`, for docker deployments.

The persisted keys are singular: `GAME_ADDRESS`, `PLANET_ADDRESS`, `COLONY_ADDRESS`, `COMPOUND_ADDRESS`, `DEFENCE_ADDRESS`, `DOCKYARD_ADDRESS`, `FLEET_ADDRESS`, `TECH_ADDRESS`, `ERC721_ADDRESS`, `STEEL_ADDRESS`, `QUARTZ_ADDRESS`, `TRITIUM_ADDRESS`, `ETH_ADDRESS`, and `STARKNET_RPC_URL`.

There is no persisted `UNIVERSE_ID`, no history of previous universes, and no onchain registry/factory contract that maps universe identifiers to addresses. Running the current script for a new universe overwrites the env file pointers unless the operator manually copies them elsewhere first.

### Drift Handled

The plan was written before the merged initialization and deployment hardening work. The pre-edit drift check showed changes in `DEPLOYMENT.md`, `scripts/deploy-starknet.sh`, and `src/game/contract.cairo`. The relevant current facts are:

- `Game.initialize` is one-time and records `universe_start_time`.
- The deploy script uses strict env parsing, helper functions for declare/deploy/invoke, and quoted `starkli` arguments.
- The deploy script still deploys one linear universe and persists only one active address set.

## Option 1: Redeploy All Contracts Per Universe

Redeploy the complete contract graph for each quarterly universe. Each universe has its own `Game`, gameplay contracts, planet NFT, resource tokens, ETH token choice, `universe_start_time`, and env or manifest entry.

### Storage Implications

Storage remains simple because every universe has isolated contract storage. Existing maps, token balances, planet ownership, colony state, fleet state, and resource accounting do not need a `universe_id` key. The cost is duplicated storage and contracts per universe.

### Migration Risk

Migration risk is lowest. Current contracts already support this lifecycle because `Game.initialize` is one-time per deployed `Game`. There is no need to retrofit every storage map or token contract for universe awareness. The main operational risk is losing old addresses if deployment artifacts continue to overwrite singular env keys.

### Frontend And Indexer Impact

Frontend and indexer changes are explicit but bounded. They must read a selected universe manifest instead of assuming one `GAME_ADDRESS`. Indexers can index each universe address set independently and expose a universe selector. Old universes remain queryable as long as their manifest entries are preserved.

### Testing Strategy

Add a deployment-manifest fixture test or script smoke test that proves two universe records can exist side by side without overwriting each other. Contract tests can keep using `set_up_game()` because each setup already deploys an isolated universe. End-to-end deployment validation should run one "deploy twice to separate manifest entries" dry run before any live quarterly rollout.

## Option 2: Registry/Factory

Add a new onchain factory/registry that deploys or records each universe and exposes a canonical lookup such as `get_universe(universe_id) -> address set`.

### Storage Implications

The registry/factory adds new persistent storage for universe metadata, ownership, address sets, lifecycle state, and possibly class hashes. Existing gameplay contracts can remain per-universe if the factory deploys a full graph, or storage can become more complex if contracts are shared. The registry itself becomes a durable root contract and must be treated as upgrade-sensitive infrastructure.

### Migration Risk

Migration risk is medium to high. If the factory deploys the same full graph, contract migration risk is moderate but deployment code becomes more complex. If the registry also changes gameplay contracts to discover dependencies dynamically, it touches the central trust boundary around `Game` and every authorized caller check. Any mistake can strand a universe behind a bad registry entry.

### Frontend And Indexer Impact

The frontend gets a clean canonical source for available universes, active universe, and historical address sets. Indexers can discover universes from registry events rather than manual config. The tradeoff is a hard dependency on registry reads and events; frontend and indexer logic must handle registry upgrades, failed universe creation, and partial deployments.

### Testing Strategy

Tests need factory deployment coverage, registry lookup coverage, authorization coverage, duplicate universe prevention, failed partial deployment behavior, and event/indexer fixtures. A realistic first test slice would deploy two universe records through the registry and assert each record resolves to distinct `Game` and token addresses.

## Option 3: Versioned Configuration

Keep some contracts shared and add a versioned universe configuration model, for example by storing `active_universe_id`, per-universe config, and per-universe address or state mappings.

### Storage Implications

This is the most invasive storage model. Any state that should reset quarterly needs a `universe_id` dimension: planets, colonies, resources, fleets, builds, research, defences, ownership indexes, and timestamps. Token sharing also becomes a product decision: shared resource tokens blur universe economies, while per-universe tokens pull the model back toward redeploy-all.

### Migration Risk

Migration risk is highest. Existing storage keys were not designed around universe identity. Retrofitting `universe_id` into maps can break historical reads, force migration tooling, and complicate storage-layout compatibility for upgradeable contracts. This path should not start until the product explicitly wants cross-universe shared identity or shared assets.

### Frontend And Indexer Impact

The frontend may keep a smaller address surface, but every query needs a universe parameter. Indexers must partition all entities by universe and reconcile shared-contract events into per-universe projections. Any missing universe filter becomes a cross-universe data leak.

### Testing Strategy

Testing would need broad regression coverage across every stateful gameplay path to prove universe isolation. At minimum, tests must create two universes in one contract graph and prove planets, colonies, resources, fleets, builds, research, and ownership indexes cannot cross-contaminate. This is too broad for the next slice.

## Decision Checkpoint

Choose between:

- **Redeploy-all now** when the goal is to ship quarterly resets with low contract risk and accept offchain universe manifests.
- **Registry/factory next** when the goal is a canonical onchain universe directory and the team is ready to invest in factory deployment and registry event indexing.
- **Versioned configuration later** only if shared contracts or cross-universe state become a product requirement.

The recommended checkpoint is to approve redeploy-all as the first production lifecycle and define the manifest shape before touching deployment scripts. That keeps the current one-time initialization invariant intact and creates real frontend/indexer requirements before adding onchain registry complexity.

## Smallest Follow-Up Slice

Add a design-backed deployment manifest slice:

1. Define a tracked example manifest schema such as `deployments/universes.example.json` with `universe_id`, `network`, `deployed_at`, `game_address`, dependent contract addresses, token addresses, `uni_speed`, `token_price`, and `universe_start_time`.
2. Update deployment documentation to require saving each new universe under a unique manifest entry before env pointers are overwritten.
3. Add a script-level dry-run or fixture check that validates two universe entries can coexist.

This follow-up should not add a factory, registry, or contract storage changes. It only makes the redeploy-all lifecycle auditable and gives the frontend/indexer a concrete config contract to review.
