# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to semantic versioning when versions are released.

## [Unreleased]

### Security

- Gate Game resource manager mutation methods so arbitrary external callers cannot mint, burn, or spend resource balances through Game.
- Gate privileged Planet, Dockyard, and Defence state setters so external callers cannot directly mutate points, timers, debris, ship levels, or defence levels.
- Harden deployment env-file handling so the script parses plain assignments instead of executing env-file contents and passes private keys as quoted command arguments.
- Make `Game.initialize` one-time and record `universe_start_time` from the initialization block timestamp.
- Require the owner for `Game.upgrade` so arbitrary callers cannot replace the Game implementation.

### Fixed

- Keep ERC721NoGame `token_of(account)` indexes consistent after snake-case, camel-case, and safe transfer variants.
- Fix Planet resource collection to use the explicit player identity and include all of that player's colonies.
- Enforce colony generation limits per home planet so one player's colonies do not block another player's first allowed colony.
