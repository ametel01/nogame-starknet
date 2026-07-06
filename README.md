# NoGame Starknet

![Build](https://github.com/ametel01/nogame-starknet/actions/workflows/scarb.yml/badge.svg?style=for-the-badge&logo=github)
![Tests](https://github.com/ametel01/nogame-starknet/actions/workflows/test.yml/badge.svg?style=for-the-badge&logo=github)

NoGame is a space-themed multiplayer strategy game backend built as Cairo smart contracts for Starknet. Players own planets, collect resources, upgrade infrastructure, research technologies, build fleets and defences, create colonies, and send missions across a shared universe.

This repository contains the on-chain game contracts, token contracts, deployment tooling, and test suite. It does not contain the frontend client.

## What Players Do

Each player starts by generating a home planet. A generated planet is minted as an ERC721 token, assigned a universe position, and initialized with steel, quartz, and tritium.

From that base, players can:

- Collect steel, quartz, and tritium produced by planets and colonies.
- Upgrade mines, energy plants, labs, and dockyards.
- Research technologies that unlock ships, improve combat, and increase fleet capabilities.
- Build ships and defensive structures.
- Create colonies and manage colony infrastructure, fleets, and defences.
- Send fleets to attack, transport, recall, dock at colonies, or collect debris.
- Simulate battles before execution, including simulations with caller-supplied attacker and defender tech levels.

## Game Systems

NoGame uses a deterministic on-chain ruleset so battle outcomes can be reproduced and verified from contract state.

- Resource production scales with mine levels, energy availability, universe speed, elapsed time, and planet position.
- Planet ownership is represented by `ERC721NoGame`.
- Steel, quartz, and tritium are ERC20 resource tokens.
- Player points are derived from resource spending and losses.
- Noob protection prevents attacks across large point gaps unless inactivity rules apply.
- Fleet missions consume tritium and are limited by speed, distance, available ships, and mission capacity.
- Battles are capped at six rounds.
- Damage is distributed by deterministic class-weighted targeting.
- Shields reset between battle rounds while hull damage persists.
- Below-70-percent hull explosions use a deterministic approximation.
- Destroyed ships are permanent losses.
- Destroyed defences rebuild deterministically at 70%.
- Debris fields contain steel and quartz from destroyed ships and defences and can be collected by scraper ships.
- Attack loot is cargo-limited and awarded only when the attacker wins.

## Contract Architecture

NoGame is deployed as 13 interconnected contracts.

Core gameplay contracts:

- `Game`: central registry, universe configuration, token access, and authorized resource manager.
- `Planet`: home planet generation, ownership lookup, positions, resource collection, points, activity, noob protection, and debris fields.
- `Colony`: colony generation, colony production, colony buildings, colony ships, colony defences, and colony positioning.
- `Compound`: planet building upgrades such as mines, energy plants, labs, and dockyards.
- `Tech`: technology research and technology level storage.
- `Dockyard`: ship construction and ship count storage.
- `Defence`: defensive structure construction and defence count storage.
- `FleetMovements`: mission creation, recalls, docking, attacks, debris collection, battle reports, and battle simulation views.

Token contracts:

- `ERC721NoGame`: planet ownership NFT.
- `ERC20NoGame (Steel)`: steel resource token.
- `ERC20NoGame (Quartz)`: quartz resource token.
- `ERC20NoGame (Tritium)`: tritium resource token.
- `ERC20Upgradeable (ETH)`: payment token used by the deployment/test environment for planet purchases.

## Repository Layout

```text
src/
  colony/              Colony contract and colony helpers
  compound/            Building upgrade contract and costs
  defence/             Defence contract and defence costs/requirements
  dockyard/            Ship build contract and ship costs/requirements
  fleet_movements/     Missions, combat, settlement, loot, and debris
  game/                Central game manager and segregated interfaces
  libraries/           Shared types, math, production, names, and helpers
  planet/              Planet generation, ownership, production, positions
  tech/                Research contract and tech costs/requirements
  token/               ERC20 and ERC721 token contracts
tests/                 Starknet Foundry tests
scripts/               Deployment automation
deployments/           Example multi-universe deployment manifest
docs/                  Design notes and battle/universe spikes
```

## Build And Test

Install the Cairo/Starknet toolchain expected by the project, then run:

```bash
scarb fmt --check
scarb build
snforge test
```

The Scarb package also exposes:

```bash
scarb run test
```

## Deployment

Use the deployment guide for full setup and operator details:

- [DEPLOYMENT.md](DEPLOYMENT.md)
- [deployments/universes.example.json](deployments/universes.example.json)

Local Katana and Docker-style deployments are supported by the deployment script:

```bash
./scripts/deploy-starknet.sh local
./scripts/deploy-starknet.sh docker
./scripts/deploy-starknet.sh --no-build local
```

The script writes deployed contract addresses into the selected environment file. Before replacing an existing universe deployment, preserve the old address set in a universe manifest so frontends and indexers can select the correct universe.

## Current Status

The tracked implementation plan in [PROGRESS.md](PROGRESS.md) is complete. The latest completed work includes:

- Bounded fleet speed modifiers.
- Cargo-limited loot accounting that separates collectible and spendable resources.
- Tech-aware battle simulation.
- Multi-universe deployment manifest documentation.
- Correct large-ship debris accounting.
- Six-round battle caps with draw handling.
- Deterministic class-weighted targeting.
- Round shield restoration and deterministic explosion handling.
- Bounded rapid-fire handling.
- Deterministic 70% defence rebuild settlement.
- MIT license metadata alignment.

## License

NoGame Starknet is licensed under the [MIT License](LICENSE).
