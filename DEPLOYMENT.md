# NoGame Starknet Deployment Guide

This guide documents the deployment architecture and provides scripts for deploying NoGame contracts to Katana and other Starknet networks.

## Contract Architecture

NoGame consists of 13 interconnected contracts that manage a space-themed strategy game:

### Core Contracts

1. **Game** - Central hub contract that coordinates all other contracts
2. **Planet** - Manages player planets, positions, and resource generation
3. **Colony** - Handles colony creation and management for players
4. **Compound** - Manages building upgrades (mines, energy plants, labs, dockyards)
5. **Tech** - Handles technology research and upgrades
6. **Defence** - Manages defensive structures
7. **Dockyard** - Handles spaceship construction
8. **FleetMovements** - Manages fleet movements, attacks, and missions

### Token Contracts

9. **ERC721NoGame** - NFT contract for planet ownership
10. **ERC20NoGame (Steel)** - Resource token for steel
11. **ERC20NoGame (Quartz)** - Resource token for quartz
12. **ERC20NoGame (Tritium)** - Resource token for tritium
13. **ERC20Upgradeable (ETH)** - Payment token for planet purchases

## Deployment Order

The contracts must be deployed in this specific order due to dependencies:

```
1. Game (deployer)
2. Colony (deployer, game_address)
3. Compound (deployer, game_address)
4. Defence (deployer, game_address)
5. Dockyard (deployer, game_address)
6. FleetMovements (deployer, game_address)
7. Planet (deployer, game_address)
8. Tech (deployer, game_address)
9. ERC721NoGame (name, symbol, base_uri, planet_address, deployer)
10. ERC20NoGame - Steel (name, symbol, planet_address, deployer)
11. ERC20NoGame - Quartz (name, symbol, planet_address, deployer)
12. ERC20NoGame - Tritium (name, symbol, planet_address, deployer)
13. ERC20Upgradeable - ETH (name, symbol, supply, deployer, deployer)
```

## Initialization

After deployment, the Game contract must be initialized with all contract addresses:

```cairo
game.initialize(
    colony_address,
    compound_address,
    defence_address,
    dockyard_address,
    fleet_address,
    planet_address,
    tech_address,
    erc721_address,
    steel_address,
    quartz_address,
    tritium_address,
    eth_address,
    uni_speed,      // Universe speed multiplier (1 = normal)
    token_price,    // Planet price in ETH
)
```

## Test Setup Reference

The test setup in `tests/utils.cairo` provides the complete deployment flow:

- `set_up()` - Declares and deploys all contracts
- `init_game()` - Initializes the Game contract with all addresses
- `init_storage()` - Seeds test data for a planet

Key test constants:
- `UNI_SPEED: u128 = 1` - Universe speed (1x normal)
- `TOKEN_PRICE: u128 = 1` - Planet price in ETH
- `ETH_SUPPLY: u256 = 1_000_000_000_000_000_000_000` - Initial ETH supply

## Contract Classes

Based on Scarb.toml configuration:

```toml
[package]
name = "nogame"
version = "0.1.0"
edition = '2023_01'

[dependencies]
openzeppelin_access = "3.0.0"
openzeppelin_token = "3.0.0"
openzeppelin_upgrades = "3.0.0"
openzeppelin_security = "3.0.0"
openzeppelin_introspection = "3.0.0"
openzeppelin_utils = "2.1.0"
openzeppelin_interfaces = "2.1.0"
starknet = "2.18.0"

[dev-dependencies]
snforge_std = "0.62.1"
```

Contract class names for declaration:
- `Game`
- `Colony`
- `Compound`
- `Defence`
- `Dockyard`
- `FleetMovements`
- `Planet`
- `Tech`
- `ERC721NoGame`
- `ERC20NoGame`
- `ERC20Upgradeable`

## Build Commands

```bash
# Build contracts
scarb build

# Run tests
snforge test

# Run specific test
snforge test test_deploy_and_init
```

## Deployment Artifacts

After building, contract artifacts are located in:
```
target/dev/nogame_*.contract_class.json
```

## Environment Configuration

For local/docker Katana deployment, you'll need:

### Katana Account Details
Local Katana accounts generated with a fixed seed are deterministic development accounts. Use local placeholders in tracked docs, set real values only in untracked env files, and never reuse Katana private keys on public networks.

```bash
# Account #0
STARKNET_ACCOUNT_ADDRESS=0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec
STARKNET_PRIVATE_KEY=<katana-private-key-0>
STARKNET_PUBLIC_KEY=0x33246ce85ebdc292e6a5c5b4dd51fab2757be34b8ffda847ca6925edf31cb67
```

### RPC Configuration
```bash
STARKNET_RPC_URL=http://localhost:5050
```

## Integration with Frontend

To integrate as a git submodule in your frontend:

```bash
cd nogame-app
git submodule add https://github.com/ametel01/nogame-starknet.git contracts/nogame-starknet
git submodule update --init --recursive
```

## Docker Compose Integration

Add Katana service to your `docker-compose.yml`:

```yaml
katana:
  image: ghcr.io/dojoengine/katana:latest
  container_name: nogame-katana
  ports:
    - "5050:5050"
  command: --host 0.0.0.0 --accounts 10 --seed 0
  networks:
    - nogame-network
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:5050"]
    interval: 10s
    timeout: 5s
    retries: 5
```

## Deployment Script Usage

```bash
# Deploy to local Katana (no private key needed)
./scripts/deploy-starknet.sh local

# Deploy to Docker Katana
./scripts/deploy-starknet.sh docker

# Skip build step
./scripts/deploy-starknet.sh --no-build local
```

## Post-Deployment

After deployment, the script will update your `.env.local` or `.env.docker` file with:
- All deployed contract addresses
- Game initialization status
- Test account balances

## Testing Deployment

Use the test accounts to verify deployment:

```bash
# Generate a planet with test account
starkli invoke $PLANET_ADDRESS generate_planet \
  --account $STARKNET_ACCOUNT \
  --rpc $STARKNET_RPC_URL
```

## Common Issues

1. **Build failures** - Ensure you have Scarb 2.19.1 and Starknet Foundry 0.62.1 installed
2. **Declaration failures** - Check that Katana is running and accessible
3. **Initialization failures** - Verify all contract addresses are correct
4. **Test failures** - Run `scarb clean` and rebuild

## Contract Addresses

After deployment, contract addresses will be stored in your environment file:

```bash
# Core contracts
GAME_ADDRESS=0x...
PLANET_ADDRESS=0x...
COLONY_ADDRESS=0x...
COMPOUND_ADDRESS=0x...
TECH_ADDRESS=0x...
DEFENCE_ADDRESS=0x...
DOCKYARD_ADDRESS=0x...
FLEET_ADDRESS=0x...

# Token contracts
ERC721_ADDRESS=0x...
STEEL_ADDRESS=0x...
QUARTZ_ADDRESS=0x...
TRITIUM_ADDRESS=0x...
ETH_ADDRESS=0x...
```

## References

- Test utils: `tests/utils.cairo:70-166` (set_up function)
- Game initialization: `tests/utils.cairo:168-219` (init_game function)
- Example deployment test: `tests/utils.cairo:221-227`
