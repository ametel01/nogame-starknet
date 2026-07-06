# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to semantic versioning when versions are released.

## [Unreleased]

### Added

- Add an example universe deployment manifest and redeploy-all documentation for preserving address sets across universe lifecycles.
- Add `simulate_attack_with_techs` so clients can preview battle losses with caller-supplied attacker and defender tech levels while preserving the existing zero-tech `simulate_attack` view.

### Security

- Gate Game resource manager mutation methods so arbitrary external callers cannot mint, burn, or spend resource balances through Game.
- Gate privileged Planet, Dockyard, and Defence state setters so external callers cannot directly mutate points, timers, debris, ship levels, or defence levels.
- Harden deployment env-file handling so the script parses plain assignments instead of executing env-file contents and passes private keys as quoted command arguments.
- Charge resource costs and record planet points for colony compound upgrades, ship builds, and defence builds so colony progression cannot mutate state for free.
- Make `Game.initialize` one-time and record `universe_start_time` from the initialization block timestamp.
- Require the owner for `Game.upgrade` so arbitrary callers cannot replace the Game implementation.

### Fixed

- Reject invalid fleet speed modifiers before fleet mission travel-time and fuel-cost arithmetic.
- Calculate debris from destroyed frigates and armades using their own unit costs.
- Keep ERC721NoGame `token_of(account)` indexes consistent after snake-case, camel-case, and safe transfer variants.
- Prevent attack loot from classifying defender spendable balances as collectible loot, so spendable resources granted to attackers are burned from defenders and remain cargo-limited.
- Fix Planet resource collection to use the explicit player identity and include all of that player's colonies.
- Enforce colony generation limits per home planet so one player's colonies do not block another player's first allowed colony.
- Require transport missions to arrive before `dock_fleet` applies docking effects.
- Make shared `ERC20s` addition and subtraction panic on component overflow or underflow instead of silently wrapping.
