use nogame::libraries::types::{
    PlanetPosition, ColonyUpgradeType, ERC20s, ColonyBuildType, TechLevels, CompoundsLevels, Fleet,
    Defences
};

#[starknet::interface]
trait IColony<TState> {
    fn generate_colony(ref self: TState, planet_id: u32) -> (u8, PlanetPosition);
    fn collect_resources(
        ref self: TState, uni_speed: u128, planet_id: u32, colony_id: u8
    ) -> ERC20s;
    fn process_colony_compound_upgrade(
        ref self: TState, planet_id: u32, colony_id: u8, name: ColonyUpgradeType, quantity: u8
    );
    fn process_colony_unit_build(
        ref self: TState,
        planet_id: u32,
        colony_id: u8,
        techs: TechLevels,
        name: ColonyBuildType,
        quantity: u32,
        is_testnet: bool
    );
    fn get_colony_resources(
        self: @TState, uni_speed: u128, planet_id: u32, colony_id: u8
    ) -> ERC20s;
    fn update_defences_after_attack(ref self: TState, planet_id: u32, colony_id: u8, d: Defences);
    fn reset_resource_timer(ref self: TState, planet_id: u32, colony_id: u8);
    fn fleet_arrives(ref self: TState, planet_id: u32, colony_id: u8, fleet: Fleet);
    fn fleet_leaves(ref self: TState, planet_id: u32, colony_id: u8, fleet: Fleet);
}

mod ResourceName {
    const STEEL: felt252 = 1;
    const QUARTZ: felt252 = 1;
    const TRITIUM: felt252 = 3;
}

#[starknet::contract]
mod Colony {
    use nogame::colony::positions;
    use nogame::compound::library as compound;
    use nogame::defence::library as defence;
    use nogame::dockyard::library as dockyard;
    use nogame::libraries::types::{
        PlanetPosition, Names, ERC20s, CompoundsLevels, HOUR, ColonyUpgradeType, ColonyBuildType,
        TechLevels, ShipsLevels, Defences, Fleet
    };
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};

    use snforge_std::PrintTrait;
    use starknet::{get_block_timestamp, get_caller_address};
    use super::ResourceName;

    #[storage]
    struct Storage {
        storage: IStorageDispatcher,
    }

    #[embeddable_as(ColonyWrite)]
    impl ColonyWriteImpl of super::IColony<ContractState> {
        fn generate_colony(ref self: ContractState, planet_id: u32) -> (u8, PlanetPosition) {
            let current_count = self.storage.read().get_colony_count();
            let position = positions::get_colony_position(current_count);
            let colony_id = self.storage.read().get_planet_colonies_count(planet_id) + 1;
            self.storage.read().set_colony_position(planet_id, colony_id, position);
            self.storage.read().set_planet_colonies_count(planet_id, colony_id);
            self.storage.read().set_colony_count(current_count + 1);
            (colony_id, position)
        }

        fn collect_resources(
            ref self: ContractState, uni_speed: u128, planet_id: u32, colony_id: u8
        ) -> ERC20s {
            assert!(
                !self.storage.read().get_colony_position(planet_id, colony_id).is_zero(),
                "NoGameColony: colony {} not present for planet {}",
                colony_id,
                planet_id
            );
            let production = self.calculate_colony_production(uni_speed, planet_id, colony_id);
            self
                .storage
                .read()
                .set_colony_resource_timer(planet_id, colony_id, get_block_timestamp());

            production
        }

        fn process_colony_compound_upgrade(
            ref self: ContractState,
            planet_id: u32,
            colony_id: u8,
            name: ColonyUpgradeType,
            quantity: u8
        ) {
            assert!(
                !self.storage.read().get_colony_position(planet_id, colony_id).is_zero(),
                "NoGameColony: colony {} not present for planet {}",
                colony_id,
                planet_id
            );
            self.upgrade_component(planet_id, colony_id, name, quantity);
        }

        fn process_colony_unit_build(
            ref self: ContractState,
            planet_id: u32,
            colony_id: u8,
            techs: TechLevels,
            name: ColonyBuildType,
            quantity: u32,
            is_testnet: bool
        ) {
            assert!(
                !self.storage.read().get_colony_position(planet_id, colony_id).is_zero(),
                "NoGameColony: colony {} not present for planet {}",
                colony_id,
                planet_id
            );
            self.build_component(planet_id, colony_id, techs, name, quantity, is_testnet);
        }

        fn get_colony_resources(
            self: @ContractState, uni_speed: u128, planet_id: u32, colony_id: u8
        ) -> ERC20s {
            if self.storage.read().get_colony_position(planet_id, colony_id).is_zero() {
                return Zeroable::zero();
            }
            self.calculate_colony_production(uni_speed, planet_id, colony_id)
        }

        fn update_defences_after_attack(
            ref self: ContractState, planet_id: u32, colony_id: u8, d: Defences
        ) {
            self
                .storage
                .read()
                .set_colony_defence(planet_id, colony_id, Names::CELESTIA, d.celestia);
            self.storage.read().set_colony_defence(planet_id, colony_id, Names::BLASTER, d.blaster);
            self.storage.read().set_colony_defence(planet_id, colony_id, Names::BEAM, d.beam);
            self.storage.read().set_colony_defence(planet_id, colony_id, Names::ASTRAL, d.astral);
            self.storage.read().set_colony_defence(planet_id, colony_id, Names::PLASMA, d.plasma);
        }

        fn reset_resource_timer(ref self: ContractState, planet_id: u32, colony_id: u8) {
            self
                .storage
                .read()
                .set_colony_resource_timer(planet_id, colony_id, get_block_timestamp());
        }

        fn fleet_arrives(ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            let current_levels = self.storage.read().get_colony_ships(planet_id, colony_id);
            if fleet.carrier > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::CARRIER, current_levels.carrier + fleet.carrier
                    );
            }
            if fleet.scraper > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::SCRAPER, current_levels.scraper + fleet.scraper
                    );
            }
            if fleet.sparrow > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::SPARROW, current_levels.sparrow + fleet.sparrow
                    );
            }
            if fleet.frigate > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::FRIGATE, current_levels.frigate + fleet.frigate
                    );
            }
            if fleet.armade > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::ARMADE, current_levels.armade + fleet.armade
                    );
            }
        }

        fn fleet_leaves(ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            let current_levels = self.storage.read().get_colony_ships(planet_id, colony_id);
            if fleet.carrier > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::CARRIER, current_levels.carrier - fleet.carrier
                    );
            }
            if fleet.scraper > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::SCRAPER, current_levels.scraper - fleet.scraper
                    );
            }
            if fleet.sparrow > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::SPARROW, current_levels.sparrow - fleet.sparrow
                    );
            }
            if fleet.frigate > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::FRIGATE, current_levels.frigate - fleet.frigate
                    );
            }
            if fleet.armade > 0 {
                self
                    .storage
                    .read()
                    .set_colony_ship(
                        planet_id, colony_id, Names::ARMADE, current_levels.armade - fleet.armade
                    );
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn upgrade_component(
            ref self: ContractState,
            planet_id: u32,
            colony_id: u8,
            component: ColonyUpgradeType,
            quantity: u8
        ) {
            let current_levels = self.storage.read().get_colony_compounds(planet_id, colony_id);
            match component {
                ColonyUpgradeType::SteelMine => {
                    self
                        .storage
                        .read()
                        .set_colony_compound(
                            planet_id,
                            colony_id,
                            Names::STEEL,
                            current_levels.steel + quantity.try_into().expect('u32 into u8 failed')
                        );
                },
                ColonyUpgradeType::QuartzMine => {
                    self
                        .storage
                        .read()
                        .set_colony_compound(
                            planet_id,
                            colony_id,
                            Names::QUARTZ,
                            current_levels.quartz + quantity.try_into().expect('u32 into u8 failed')
                        );
                },
                ColonyUpgradeType::TritiumMine => {
                    self
                        .storage
                        .read()
                        .set_colony_compound(
                            planet_id,
                            colony_id,
                            Names::TRITIUM,
                            current_levels.tritium
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                },
                ColonyUpgradeType::EnergyPlant => {
                    self
                        .storage
                        .read()
                        .set_colony_compound(
                            planet_id,
                            colony_id,
                            Names::ENERGY_PLANT,
                            current_levels.energy + quantity.try_into().expect('u32 into u8 failed')
                        );
                },
                ColonyUpgradeType::Dockyard => {
                    self
                        .storage
                        .read()
                        .set_colony_compound(
                            planet_id,
                            colony_id,
                            Names::DOCKYARD,
                            current_levels.dockyard
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                },
            }
        }

        fn build_component(
            ref self: ContractState,
            planet_id: u32,
            colony_id: u8,
            techs: TechLevels,
            component: ColonyBuildType,
            quantity: u32,
            is_tesnet: bool,
        ) {
            let dockyard_level = self
                .storage
                .read()
                .get_colony_compounds(planet_id, colony_id)
                .dockyard;
            let ship_levels = self.storage.read().get_colony_ships(planet_id, colony_id);
            let defence_levels = self.storage.read().get_colony_defences(planet_id, colony_id);
            match component {
                ColonyBuildType::Carrier => {
                    dockyard::carrier_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_ship(
                            planet_id, colony_id, Names::CARRIER, ship_levels.carrier + quantity
                        );
                },
                ColonyBuildType::Scraper => {
                    dockyard::scraper_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_ship(
                            planet_id, colony_id, Names::SCRAPER, ship_levels.scraper + quantity
                        );
                },
                ColonyBuildType::Sparrow => {
                    dockyard::scraper_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_ship(
                            planet_id, colony_id, Names::SPARROW, ship_levels.sparrow + quantity
                        );
                },
                ColonyBuildType::Frigate => {
                    dockyard::scraper_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_ship(
                            planet_id, colony_id, Names::FRIGATE, ship_levels.frigate + quantity
                        );
                },
                ColonyBuildType::Armade => {
                    dockyard::scraper_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_ship(
                            planet_id, colony_id, Names::ARMADE, ship_levels.armade + quantity
                        );
                },
                ColonyBuildType::Celestia => {
                    dockyard::celestia_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_defence(
                            planet_id,
                            colony_id,
                            Names::CELESTIA,
                            defence_levels.celestia + quantity
                        );
                },
                ColonyBuildType::Blaster => {
                    defence::blaster_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_defence(
                            planet_id, colony_id, Names::BLASTER, defence_levels.blaster + quantity
                        );
                },
                ColonyBuildType::Beam => {
                    defence::beam_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_defence(
                            planet_id, colony_id, Names::BEAM, defence_levels.beam + quantity
                        );
                },
                ColonyBuildType::Astral => {
                    defence::astral_launcher_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_defence(
                            planet_id, colony_id, Names::ASTRAL, defence_levels.astral + quantity
                        );
                },
                ColonyBuildType::Plasma => {
                    defence::plasma_beam_requirements_check(dockyard_level, techs);
                    self
                        .storage
                        .read()
                        .set_colony_defence(
                            planet_id, colony_id, Names::PLASMA, defence_levels.plasma + quantity
                        );
                },
            }
        }

        fn calculate_colony_production(
            self: @ContractState, uni_speed: u128, planet_id: u32, colony_id: u8
        ) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self
                .storage
                .read()
                .get_colony_resource_timer(planet_id, colony_id);
            let time_elapsed = time_now - last_collection_time;
            let mines_levels = self.storage.read().get_colony_compounds(planet_id, colony_id);
            let position = self.storage.read().get_colony_position(planet_id, colony_id);
            let temp = self.calculate_avg_temperature(position.orbit);
            let steel_available = compound::production::steel(mines_levels.steel)
                * uni_speed
                * time_elapsed.into()
                / HOUR.into();

            let quartz_available = compound::production::quartz(mines_levels.quartz)
                * uni_speed
                * time_elapsed.into()
                / HOUR.into();

            let tritium_available = compound::production::tritium(
                mines_levels.tritium, temp, uni_speed
            )
                * time_elapsed.into()
                / HOUR.into();

            let colony_position = self.storage.read().get_colony_position(planet_id, colony_id);
            let celestia_production = self.position_to_celestia_production(colony_position.orbit);
            let celestia_production: u128 = self
                .storage
                .read()
                .get_colony_defences(planet_id, colony_id)
                .celestia
                .into()
                * celestia_production;
            let energy_available = compound::production::energy(mines_levels.energy);
            let energy_required = compound::consumption::base(mines_levels.steel)
                + compound::consumption::base(mines_levels.quartz)
                + compound::consumption::base(mines_levels.tritium);
            let total_production = energy_available + celestia_production;

            if total_production < energy_required {
                let _steel = compound::production_scaler(
                    steel_available, total_production, energy_required
                );
                let _quartz = compound::production_scaler(
                    quartz_available, total_production, energy_required
                );
                let _tritium = compound::production_scaler(
                    tritium_available, total_production, energy_required
                );

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium, };
            }

            ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available, }
        }

        fn calculate_avg_temperature(self: @ContractState, orbit: u8) -> u32 {
            if orbit == 1 {
                return 230;
            }
            if orbit == 2 {
                return 170;
            }
            if orbit == 3 {
                return 120;
            }
            if orbit == 4 {
                return 70;
            }
            if orbit == 5 {
                return 60;
            }
            if orbit == 6 {
                return 50;
            }
            if orbit == 7 {
                return 40;
            }
            if orbit == 8 {
                return 40;
            }
            if orbit == 9 {
                return 20;
            } else {
                return 10;
            }
        }

        fn position_to_celestia_production(self: @ContractState, orbit: u8) -> u128 {
            if orbit == 1 {
                return 48;
            }
            if orbit == 2 {
                return 41;
            }
            if orbit == 3 {
                return 36;
            }
            if orbit == 4 {
                return 32;
            }
            if orbit == 5 {
                return 27;
            }
            if orbit == 6 {
                return 24;
            }
            if orbit == 7 {
                return 21;
            }
            if orbit == 8 {
                return 17;
            }
            if orbit == 9 {
                return 14;
            } else {
                return 11;
            }
        }
    }
}
