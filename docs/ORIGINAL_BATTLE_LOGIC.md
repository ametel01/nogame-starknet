The original OGame combat model is basically **six rounds of stochastic, simultaneous-looking fire**, not a tactical grid or deterministic matchup system.

Important caveat: Gameforge’s actual server code is not public. What exists publicly is the long-standing community-reconstructed battle logic, old OGame forum explanations, and open-source simulators that implement the same rules.

## Core battle loop

A battle runs for **up to 6 rounds**. If the attacker has not destroyed all defending ships/defense by then, the result is a draw and no resources are looted. Each unit on both sides gets to fire once per round, with rapid-fire possibly granting extra shots. ([OGame Wiki][1])

Conceptually:

```txt
for round in 1..6:
    attacker units fire
    defender units fire
    remove destroyed units
    restore shields on surviving units
    if one side has no units:
        stop battle
```

That is also how an open-source OGame simulator structures it: attacker fires, defender fires, destroyed units are removed, shields are restored, and the loop stops if one side is gone; max rounds is set to 6. ([GitHub][2])

## Unit stats

Each unit has three combat stats:

```txt
weapon = base_weapon * (1 + 0.1 * weapons_tech)
shield = base_shield * (1 + 0.1 * shielding_tech)
hull   = ((metal_cost + crystal_cost) / 10) * (1 + 0.1 * armour_tech)
```

Weapon tech gives +10% weapon strength per level; shield tech similarly affects shields; hull plating is based on structural integrity, where structural integrity is metal + crystal cost and hull plating is one tenth of that, modified by armour tech. ([OGame Wiki][3])

## Target selection

Each shot chooses **one random enemy unit**, not a ship class in aggregate. So if the defender has 10,000 rocket launchers and 1 deathstar, the chance to target the deathstar is roughly `1 / 10001`. This is why “fodder” matters so much in OGame: cheap units dilute incoming fire. The old forum guide states the chance a unit gets hit is `1 / number_of_own_units`. ([OGame Forum][4])

Destroyed units are not removed immediately during the firing phase. They are removed after the round, so a unit destroyed earlier in the same round can still fire, and later shots can even be wasted on already-destroyed targets. ([OGame Wiki][1])

## Damage resolution

For each shot:

```txt
if weapon < target_current_shield * 0.01:
    shot bounces, no damage
else if weapon <= target_current_shield:
    target_shield -= weapon
else:
    hull_damage = weapon - target_current_shield
    target_shield = 0
    target_hull -= hull_damage
```

This is the “bounce rule”: if attack power is less than 1% of the target shield, it does no damage. Otherwise shields absorb damage first; only overflow damages hull. Shields regenerate between rounds, but hull damage persists. ([OGame Wiki][1])

## Explosion mechanic

This is one of the defining OGame quirks. A ship/defense does **not** need to reach zero hull to die.

Once current hull drops below 70% of initial hull, every damaging shot can trigger an explosion roll:

```txt
explosion_probability = 1 - current_hull / initial_hull
```

So if a unit has 25% hull left, it has a 75% chance to explode after that shot. This roll can happen after each shot, which makes many small shots dangerous once the target is below 70% hull. ([OGame Wiki][1])

## Rapid fire

Rapid fire is not “extra damage.” It is a chance to fire again after hitting a specific target type.

If unit A has rapid fire `r` against unit B:

```txt
chance_extra_shot = (r - 1) / r
```

So RF 10 means a 90% chance to shoot again after hitting that target. The extra shot then picks another random target, and the process can continue as long as rapid-fire rolls succeed. ([OGame Wiki][5])

Example: cruisers have strong rapid fire against rocket launchers, so cruisers can chew through rocket-launcher fodder efficiently. But if the cruiser’s next random target is a light laser and it has no rapid fire against that target, the chain stops. ([OGame Wiki][5])

## Post-combat effects

After combat, defender **defensive structures** have a chance to rebuild for free; ships do not. Destroyed ships create debris fields, while normal defenses generally do not unless the universe has special “defense into debris” settings. ([OGame Wiki][6])

## Minimal implementation shape

For a clone, model each unit instance, not just counts, unless you build a mathematically equivalent aggregate simulator.

```ts
for (let round = 1; round <= 6; round++) {
  fireSide(attacker, defender);
  fireSide(defender, attacker);

  removeDestroyed(attacker);
  removeDestroyed(defender);

  restoreShields(attacker);
  restoreShields(defender);

  if (attacker.units.length === 0 || defender.units.length === 0) break;
}

function fireSide(side, enemy) {
  for (const unit of side.units) {
    let keepFiring = true;

    while (keepFiring && enemy.units.length > 0) {
      const target = randomEnemyUnit(enemy.units);

      applyShot(unit, target);

      const rf = rapidFireValue(unit.type, target.type);
      keepFiring = rf > 0 && Math.random() <= (rf - 1) / rf;
    }
  }
}
```

The big design insight: **OGame combat is mostly about probabilistic target dilution, shield reset per round, hull persistence, explosion chance below 70%, and rapid-fire chains.** Fleet composition matters because it changes target probabilities and rapid-fire efficiency, not because players issue tactical commands during battle.

[1]: https://ogame.fandom.com/wiki/Combat "Combat | OGame Wiki | Fandom"
[2]: https://github.com/alaingilbert/ogame/blob/325667f573cc9fd257ecff10d7f2de77c9e212a5/pkg/simulator/simulator.go "ogame/pkg/simulator/simulator.go at 325667f573cc9fd257ecff10d7f2de77c9e212a5 · alaingilbert/ogame · GitHub"
[3]: https://ogame.fandom.com/wiki/Weapon_Power "Weapon Power | OGame Wiki | Fandom"
[4]: https://board.en.ogame.gameforge.com/index.php?thread%2F151317-how-a-fight-works%2F= "How a fight works  - Game Archive - OGame Forum"
[5]: https://ogame.fandom.com/wiki/Rapid_Fire "Rapid Fire | OGame Wiki | Fandom"
[6]: https://ogame.fandom.com/wiki/Defense "Defense | OGame Wiki | Fandom"
