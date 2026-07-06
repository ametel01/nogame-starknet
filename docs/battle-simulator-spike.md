# Offchain Battle Simulator Boundary Spike

## Summary

The README roadmap calls for an offchain battle simulator, and the current `FleetMovements` contract already exposes a narrow `simulate_attack` view for loss previews. This spike defines the boundary for a player-facing simulator without changing battle formulas or adding frontend behavior.

The recommended first slice is to extend the simulator boundary so callers can pass both players' `TechLevels` and then test that the view result matches the same settlement facts used by real `attack_planet` execution.

## Drift Check

Required plan drift command run before edits:

```bash
git diff --stat a370d98..HEAD -- README.md src/fleet_movements src/libraries/types.cairo tests/fleet.cairo tests/fleet_write.cairo
```

Result: PASS. The command produced no diff output in `codex/issue-8-battle-simulator-spike`, so the watched battle and roadmap paths had not drifted from the plan baseline in this worktree.

Required symbol mapping command:

```bash
rg -n "struct SimulationResult|struct TechLevels|fn settle" src/libraries/types.cairo src/fleet_movements
```

Result: PASS.

- `src/libraries/types.cairo:176` defines `TechLevels`.
- `src/libraries/types.cairo:513` defines `SimulationResult`.
- `src/fleet_movements/battle_settlement.cairo:15` defines `settle`.

## Current Code Map

- Roadmap intent: `README.md` lists "Implement an offchain battle simulator" under the Q1-Q2 new feature roadmap.
- Onchain preview API: `src/fleet_movements/contract.cairo` declares and implements `simulate_attack(self, attacker_fleet, defender_fleet, defences) -> SimulationResult`.
- Current preview limitation: `simulate_attack` creates one default `TechLevels` value and passes it as both attacker and defender techs, passes `defences.celestia` as the initial celestia count, and passes `0` as `time_since_arrived`.
- Battle settlement source of truth: `src/fleet_movements/battle_settlement.cairo::settle` takes attacker fleet, defender fleet, defences, attacker techs, defender techs, initial celestia, and time since arrival. It returns surviving fleets/defences, losses, and debris.
- Real attack path: `src/fleet_movements/orchestration.cairo::plan_attack` fetches attacker techs from `contracts.tech.get_tech_levels(origin)`, fetches defender fleet/defences/techs/celestia through `get_defender_assets`, and calls `battle_settlement::settle` with `time_now - mission.time_arrival`.
- Fleet math support: `src/fleet_movements/library.cairo` contains `war`, `build_ships_array`, `build_fleet_struct`, `add_techs`, cargo, debris, speed, fuel, and decay helpers used by settlement and mission planning.
- Shared types: `src/libraries/types.cairo` owns the ABI-visible `Fleet`, `Defences`, `TechLevels`, `SimulationResult`, `Mission`, `Debris`, and related structs.

## Target Users

- Players planning attacks before spending tritium or revealing intent onchain.
- Frontend clients presenting a deterministic battle preview from user-entered fleet and defence values.
- Backend or indexer services that want to cache simulations for known public planet states.
- Test authors who need a stable seam for asserting simulator parity with real settlement.

## Use Cases

- Preview expected attacker fleet losses, defender fleet losses, and defence losses for an arbitrary matchup.
- Compare outcomes as attacker or defender combat tech levels change.
- Model the same no-decay case currently covered by `simulate_attack`.
- Eventually model delayed execution after arrival, where attacker fleet decay may affect settlement.
- Keep the offchain UX aligned with the exact battle math used by real settlement.

## API shape

### Current view

```cairo
fn simulate_attack(
    self: @TState,
    attacker_fleet: Fleet,
    defender_fleet: Fleet,
    defences: Defences,
) -> SimulationResult;
```

This is useful as a zero-tech, no-decay baseline. It is not enough for a real player simulator because it cannot represent attacker techs, defender techs, or delayed-arrival decay.

### Proposed onchain view extension

Add a second view rather than breaking the existing ABI immediately:

```cairo
fn simulate_attack_with_techs(
    self: @TState,
    attacker_fleet: Fleet,
    defender_fleet: Fleet,
    defences: Defences,
    attacker_techs: TechLevels,
    defender_techs: TechLevels,
) -> SimulationResult;
```

The implementation should call `battle_settlement::settle(attacker_fleet, defender_fleet, defences, attacker_techs, defender_techs, defences.celestia, 0)` and map losses into `SimulationResult` exactly as the current `simulate_attack` does.

Keep `simulate_attack` as a compatibility wrapper that passes `Default::default()` for both tech structs.

### Future extension

If the product needs stale-arrival or "what if I execute later" previews, add a separate API that accepts `time_since_arrived: u64`. Do not overload the first tech-aware slice with decay until the UI and game design explicitly need it.

### Offchain service API

A frontend or backend simulator can expose a JSON request mirroring the ABI types:

```json
{
  "attackerFleet": {
    "carrier": 0,
    "scraper": 0,
    "sparrow": 10,
    "frigate": 0,
    "armade": 0
  },
  "defenderFleet": {
    "carrier": 0,
    "scraper": 0,
    "sparrow": 0,
    "frigate": 0,
    "armade": 0
  },
  "defences": {
    "celestia": 0,
    "blaster": 5,
    "beam": 0,
    "astral": 0,
    "plasma": 0
  },
  "attackerTechs": {
    "energy": 0,
    "digital": 0,
    "beam": 0,
    "armour": 0,
    "ion": 0,
    "plasma": 0,
    "weapons": 3,
    "shield": 2,
    "spacetime": 0,
    "combustion": 0,
    "thrust": 0,
    "warp": 0,
    "exocraft": 0
  },
  "defenderTechs": {
    "energy": 0,
    "digital": 0,
    "beam": 0,
    "armour": 1,
    "ion": 0,
    "plasma": 0,
    "weapons": 0,
    "shield": 1,
    "spacetime": 0,
    "combustion": 0,
    "thrust": 0,
    "warp": 0,
    "exocraft": 0
  }
}
```

Return the ABI-compatible `SimulationResult` fields first. A service can add metadata such as `sourceBlock`, `contractAddress`, or `mathVersion`, but those fields should not be required by the contract view.

## Battle math sharing

The contract settlement path is the source of truth. The safest sharing model is:

1. Keep the canonical formula in `src/fleet_movements/battle_settlement.cairo` and `src/fleet_movements/library.cairo`.
2. Expose enough view inputs to run that formula without reading mutable game state.
3. Use the onchain view as the parity oracle for any offchain TypeScript, Rust, or backend implementation.
4. Add fixtures that compare the offchain mirror against `simulate_attack_with_techs` for representative fleets, defences, and tech levels before trusting the mirror in production.

Avoid a long-lived independent offchain formula fork unless it is generated from shared fixtures and continuously checked against Cairo settlement behavior.

## Open questions

- Should the player-facing simulator include `time_since_arrived` decay, or should decay remain an execution-only mechanic?
- Should simulator output include debris in addition to losses? `BattleSettlement` computes debris, but `SimulationResult` currently omits it.
- Should a future view accept planet IDs and read live fleet/defence/tech state, or should all simulator inputs remain caller-supplied to avoid privacy, authorization, and state-read UX concerns?
- Should `SimulationResult` be replaced or supplemented with grouped structs such as `attacker_loss: Fleet`, `defender_loss: Fleet`, and `defences_loss: Defences` in a future ABI version?
- Which offchain client will own the mirror implementation and parity fixture suite?

## Implementation Slices

1. Add `simulate_attack_with_techs` as a non-breaking view and keep `simulate_attack` as a zero-tech compatibility wrapper.
2. Add Cairo tests that compare `simulate_attack_with_techs` against direct settlement expectations for at least one asymmetric tech matchup.
3. Add an optional decay-aware view only if the product needs delayed execution previews.
4. Add offchain mirror fixtures that call the contract view and fail when the mirror diverges.
5. Consider a richer result type with debris only after the frontend has a concrete display need.

## Recommended First Slice

Build only slice 1 first: add `simulate_attack_with_techs` and focused Cairo coverage.

Validation strategy:

- Run `scarb build`.
- Run the focused fleet simulator tests added for the new view.
- Run `snforge test` if the focused test command is not reliable or if shared fleet fixtures are touched.
- Keep a zero-tech regression that proves the existing `simulate_attack` output matches `simulate_attack_with_techs` with default attacker and defender techs.
- Include one non-default asymmetric tech case so the test would fail if either side's techs were ignored or swapped.
