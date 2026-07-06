# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to semantic versioning when versions are released.

## [Unreleased]

### Security

- Gate Game resource manager mutation methods so arbitrary external callers cannot mint, burn, or spend resource balances through Game.
- Gate privileged Planet, Dockyard, and Defence state setters so external callers cannot directly mutate points, timers, debris, ship levels, or defence levels.

### Fixed

- Keep ERC721NoGame `token_of(account)` indexes consistent after snake-case, camel-case, and safe transfer variants.
