use nogame::libraries::types::{
    ColonyBuildType, ColonyUpgradeType, CompoundsLevels, Defences, ERC20s, Fleet, PlanetPosition,
    ShipsLevels, TechLevels,
};

#[starknet::interface]
trait IColony<TState> {
    fn generate_colony(ref self: TState);
    fn collect_resources(ref self: TState, colony_id: u8) -> ERC20s;
    fn process_colony_compound_upgrade(
        ref self: TState, colony_id: u8, name: ColonyUpgradeType, quantity: u8,
    );
    fn process_colony_unit_build(
        ref self: TState, colony_id: u8, name: ColonyBuildType, quantity: u32,
    );
    fn set_resource_timer(ref self: TState, planet_id: u32, colony_id: u8);
    fn set_colony_ship(ref self: TState, planet_id: u32, colony_id: u8, name: u8, quantity: u32);
    fn set_colony_defence(ref self: TState, planet_id: u32, colony_id: u8, name: u8, quantity: u32);
    fn get_colony_resources(self: @TState, planet_id: u32, colony_id: u8) -> ERC20s;
    fn update_defences_after_attack(ref self: TState, planet_id: u32, colony_id: u8, d: Defences);
    // fn reset_resource_timer(ref self: TState, planet_id: u32, colony_id: u8);
    fn fleet_arrives(ref self: TState, planet_id: u32, colony_id: u8, fleet: Fleet);
    fn fleet_leaves(ref self: TState, planet_id: u32, colony_id: u8, fleet: Fleet);
    fn get_colony_position(self: @TState, planet_id: u32, colony_id: u8) -> PlanetPosition;
    fn get_colony_id(self: @TState, planet_id: u32, colony_id: u8) -> u32;
    fn get_colonies_for_planet(self: @TState, planet_id: u32) -> Array<(u8, PlanetPosition)>;
    fn get_colony_mother_planet(self: @TState, colony_planet_id: u32) -> u32;
    fn get_colony_compounds(self: @TState, planet_id: u32, colony_id: u8) -> CompoundsLevels;
    fn get_colony_ships(self: @TState, planet_id: u32, colony_id: u8) -> ShipsLevels;
    fn get_colony_defences(self: @TState, planet_id: u32, colony_id: u8) -> Defences;
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
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::libraries::names::Names;
    use nogame::libraries::types::{
        ColonyBuildType, ColonyUpgradeType, CompoundsLevels, Defences, ERC20s, Fleet, HOUR,
        PlanetPosition, ShipsLevels, TechLevels,
    };
    use nogame::planet::contract::IPlanetDispatcherTrait;
    use nogame::tech::contract::ITechDispatcherTrait;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        game_manager: IGameDispatcher,
        colony_owner: Map<u32, u32>,
        colony_count: usize,
        planet_colonies_count: Map<u32, u8>,
        colony_position: Map<(u32, u8), PlanetPosition>,
        position_to_colony: Map<PlanetPosition, (u32, u8)>,
        colony_resource_timer: Map<(u32, u8), u64>,
        colony_compounds: Map<(u32, u8, u8), u8>,
        colony_ships: Map<(u32, u8, u8), u32>,
        colony_defences: Map<(u32, u8, u8), u32>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PlanetGenerated: PlanetGenerated,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        id: u32,
        position: PlanetPosition,
        account: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(owner);
        self.game_manager.write(IGameDispatcher { contract_address: game });
    }

    #[abi(embed_v0)]
    impl ColonyImpl of super::IColony<ContractState> {
        fn generate_colony(ref self: ContractState) {
            let caller = get_caller_address();
            let contracts = self.game_manager.read().get_contracts();
            let planet_id = contracts.planet.get_owned_planet(caller);
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            let exo_tech = contracts.tech.get_tech_levels(planet_id).exocraft;
            let max_colonies = if exo_tech % 2 == 1 {
                exo_tech / 2 + 1
            } else {
                exo_tech / 2
            };
            let current_count = self.colony_count.read();
            assert!(
                current_count < max_colonies.into(),
                "NoGame: max colonies {} reached, upgrade Exocraft tech to increase max colonies",
                max_colonies,
            );
            let price: u256 = 0;
            if !price.is_zero() {
                let eth = game_manager.get_tokens().eth;
                eth.transfer_from(caller, self.ownable.owner(), price);
            }
            let position = positions::get_colony_position(current_count.into());
            let colony_id = self.planet_colonies_count.read(planet_id) + 1;
            let id = ((planet_id * 1000) + colony_id.into());
            self.colony_position.write((planet_id, colony_id), position);
            self.planet_colonies_count.write(planet_id, colony_id);
            self.colony_count.write(current_count + 1);
            let number_of_planets = contracts.planet.get_number_of_planets();
            self.colony_owner.write(id, planet_id);
            self.colony_resource_timer.write((planet_id, colony_id), get_block_timestamp());
            contracts.planet.add_colony_planet(id, position, number_of_planets + 1);
            self.emit(Event::PlanetGenerated(PlanetGenerated { id, position, account: caller }));
        }

        fn collect_resources(ref self: ContractState, colony_id: u8) -> ERC20s {
            let contracts = self.game_manager.read().get_contracts();
            let planet_id = contracts.planet.get_owned_planet(get_caller_address());
            self.verify_colony_exist(planet_id, colony_id);
            let uni_speed = self.game_manager.read().get_uni_speed();
            let production = self.calculate_colony_production(uni_speed, planet_id, colony_id);
            self.colony_resource_timer.write((planet_id, colony_id), get_block_timestamp());

            production
        }

        fn process_colony_compound_upgrade(
            ref self: ContractState, colony_id: u8, name: ColonyUpgradeType, quantity: u8,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            let planet_id = contracts.planet.get_owned_planet(get_caller_address());
            self.verify_colony_exist(planet_id, colony_id);
            self.upgrade_component(planet_id, colony_id, name, quantity);
        }

        fn process_colony_unit_build(
            ref self: ContractState, colony_id: u8, name: ColonyBuildType, quantity: u32,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            let planet_id = contracts.planet.get_owned_planet(get_caller_address());
            self.verify_colony_exist(planet_id, colony_id);
            let techs = self.game_manager.read().get_contracts().tech.get_tech_levels(planet_id);
            self.build_component(planet_id, colony_id, techs, name, quantity);
        }

        fn update_defences_after_attack(
            ref self: ContractState, planet_id: u32, colony_id: u8, d: Defences,
        ) {
            self
                .colony_defences
                .write((planet_id, colony_id, Names::Defence::CELESTIA), d.celestia);
            self.colony_defences.write((planet_id, colony_id, Names::Defence::BLASTER), d.blaster);
            self.colony_defences.write((planet_id, colony_id, Names::Defence::BEAM), d.beam);
            self.colony_defences.write((planet_id, colony_id, Names::Defence::ASTRAL), d.astral);
            self.colony_defences.write((planet_id, colony_id, Names::Defence::PLASMA), d.plasma);
        }

        fn fleet_arrives(ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            let current_levels = self.get_colony_ships(planet_id, colony_id);
            if fleet.carrier > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::CARRIER),
                        current_levels.carrier + fleet.carrier,
                    );
            }
            if fleet.scraper > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::SCRAPER),
                        current_levels.scraper + fleet.scraper,
                    );
            }
            if fleet.sparrow > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::SPARROW),
                        current_levels.sparrow + fleet.sparrow,
                    );
            }
            if fleet.frigate > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::FRIGATE),
                        current_levels.frigate + fleet.frigate,
                    );
            }
            if fleet.armade > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::ARMADE),
                        current_levels.armade + fleet.armade,
                    );
            }
        }

        fn fleet_leaves(ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            let current_levels = self.get_colony_ships(planet_id, colony_id);
            if fleet.carrier > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::CARRIER),
                        current_levels.carrier - fleet.carrier,
                    );
            }
            if fleet.scraper > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::SCRAPER),
                        current_levels.scraper - fleet.scraper,
                    );
            }
            if fleet.sparrow > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::SPARROW),
                        current_levels.sparrow - fleet.sparrow,
                    );
            }
            if fleet.frigate > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::FRIGATE),
                        current_levels.frigate - fleet.frigate,
                    );
            }
            if fleet.armade > 0 {
                self
                    .colony_ships
                    .write(
                        (planet_id, colony_id, Names::Fleet::ARMADE),
                        current_levels.armade - fleet.armade,
                    );
            }
        }

        fn get_colony_position(
            self: @ContractState, planet_id: u32, colony_id: u8,
        ) -> PlanetPosition {
            self.colony_position.read((planet_id, colony_id))
        }

        fn get_colony_id(self: @ContractState, planet_id: u32, colony_id: u8) -> u32 {
            (planet_id * 1000) + colony_id.into()
        }

        fn get_colonies_for_planet(
            self: @ContractState, planet_id: u32,
        ) -> Array<(u8, PlanetPosition)> {
            let mut arr: Array<(u8, PlanetPosition)> = array![];
            let mut i = 1;
            loop {
                let colony_position = self.colony_position.read((planet_id, i));
                if colony_position.is_zero() {
                    break;
                }
                arr.append((i, colony_position));
                i += 1;
            }
            arr
        }

        fn get_colony_mother_planet(self: @ContractState, colony_planet_id: u32) -> u32 {
            self.colony_owner.read(colony_planet_id)
        }

        fn set_resource_timer(ref self: ContractState, planet_id: u32, colony_id: u8) {
            self.colony_resource_timer.write((planet_id, colony_id), get_block_timestamp());
        }

        fn set_colony_ship(
            ref self: ContractState, planet_id: u32, colony_id: u8, name: u8, quantity: u32,
        ) {
            self.colony_ships.write((planet_id, colony_id, name), quantity);
        }

        fn set_colony_defence(
            ref self: ContractState, planet_id: u32, colony_id: u8, name: u8, quantity: u32,
        ) {
            self.colony_defences.write((planet_id, colony_id, name), quantity);
        }


        fn get_colony_resources(self: @ContractState, planet_id: u32, colony_id: u8) -> ERC20s {
            if self.colony_position.read((planet_id, colony_id)).is_zero() {
                return Zeroable::zero();
            }
            let uni_speed = self.game_manager.read().get_uni_speed();
            self.calculate_colony_production(uni_speed, planet_id, colony_id)
        }

        fn get_colony_compounds(
            self: @ContractState, planet_id: u32, colony_id: u8,
        ) -> CompoundsLevels {
            CompoundsLevels {
                steel: self.colony_compounds.read((planet_id, colony_id, Names::Compound::STEEL)),
                quartz: self.colony_compounds.read((planet_id, colony_id, Names::Compound::QUARTZ)),
                tritium: self
                    .colony_compounds
                    .read((planet_id, colony_id, Names::Compound::TRITIUM)),
                energy: self.colony_compounds.read((planet_id, colony_id, Names::Compound::ENERGY)),
                lab: self.colony_compounds.read((planet_id, colony_id, Names::Compound::LAB)),
                dockyard: self
                    .colony_compounds
                    .read((planet_id, colony_id, Names::Compound::DOCKYARD)),
            }
        }

        fn get_colony_ships(self: @ContractState, planet_id: u32, colony_id: u8) -> ShipsLevels {
            ShipsLevels {
                carrier: self.colony_ships.read((planet_id, colony_id, Names::Fleet::CARRIER)),
                scraper: self.colony_ships.read((planet_id, colony_id, Names::Fleet::SCRAPER)),
                sparrow: self.colony_ships.read((planet_id, colony_id, Names::Fleet::SPARROW)),
                frigate: self.colony_ships.read((planet_id, colony_id, Names::Fleet::FRIGATE)),
                armade: self.colony_ships.read((planet_id, colony_id, Names::Fleet::ARMADE)),
            }
        }

        fn get_colony_defences(self: @ContractState, planet_id: u32, colony_id: u8) -> Defences {
            Defences {
                celestia: self
                    .colony_defences
                    .read((planet_id, colony_id, Names::Defence::CELESTIA)),
                blaster: self.colony_defences.read((planet_id, colony_id, Names::Defence::BLASTER)),
                beam: self.colony_defences.read((planet_id, colony_id, Names::Defence::BEAM)),
                astral: self.colony_defences.read((planet_id, colony_id, Names::Defence::ASTRAL)),
                plasma: self.colony_defences.read((planet_id, colony_id, Names::Defence::PLASMA)),
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn verify_colony_exist(self: @ContractState, planet_id: u32, colony_id: u8) {
            assert!(
                !self.colony_position.read((planet_id, colony_id)).is_zero(),
                "NoGameColony: colony {} not present for planet {}",
                colony_id,
                planet_id,
            );
        }

        fn upgrade_component(
            ref self: ContractState,
            planet_id: u32,
            colony_id: u8,
            component: ColonyUpgradeType,
            quantity: u8,
        ) {
            let current_levels = self.get_colony_compounds(planet_id, colony_id);
            match component {
                ColonyUpgradeType::SteelMine => {
                    self
                        .colony_compounds
                        .write(
                            (planet_id, colony_id, Names::Compound::STEEL),
                            current_levels.steel + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                ColonyUpgradeType::QuartzMine => {
                    self
                        .colony_compounds
                        .write(
                            (planet_id, colony_id, Names::Compound::QUARTZ),
                            current_levels.quartz
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                ColonyUpgradeType::TritiumMine => {
                    self
                        .colony_compounds
                        .write(
                            (planet_id, colony_id, Names::Compound::TRITIUM),
                            current_levels.tritium
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                ColonyUpgradeType::EnergyPlant => {
                    self
                        .colony_compounds
                        .write(
                            (planet_id, colony_id, Names::Compound::ENERGY),
                            current_levels.energy
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                ColonyUpgradeType::Dockyard => {
                    self
                        .colony_compounds
                        .write(
                            (planet_id, colony_id, Names::Compound::DOCKYARD),
                            current_levels.dockyard
                                + quantity.try_into().expect('u32 into u8 failed'),
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
        ) {
            let dockyard_level = self.get_colony_compounds(planet_id, colony_id).dockyard;
            let ship_levels = self.get_colony_ships(planet_id, colony_id);
            let defence_levels = self.get_colony_defences(planet_id, colony_id);
            match component {
                ColonyBuildType::Carrier => {
                    dockyard::requirements::carrier(dockyard_level, techs);
                    self
                        .colony_ships
                        .write(
                            (planet_id, colony_id, Names::Fleet::CARRIER),
                            ship_levels.carrier + quantity,
                        );
                },
                ColonyBuildType::Scraper => {
                    dockyard::requirements::scraper(dockyard_level, techs);
                    self
                        .colony_ships
                        .write(
                            (planet_id, colony_id, Names::Fleet::SCRAPER),
                            ship_levels.scraper + quantity,
                        );
                },
                ColonyBuildType::Sparrow => {
                    dockyard::requirements::sparrow(dockyard_level, techs);
                    self
                        .colony_ships
                        .write(
                            (planet_id, colony_id, Names::Fleet::SPARROW),
                            ship_levels.sparrow + quantity,
                        );
                },
                ColonyBuildType::Frigate => {
                    dockyard::requirements::frigate(dockyard_level, techs);
                    self
                        .colony_ships
                        .write(
                            (planet_id, colony_id, Names::Fleet::FRIGATE),
                            ship_levels.frigate + quantity,
                        );
                },
                ColonyBuildType::Armade => {
                    dockyard::requirements::armade(dockyard_level, techs);
                    self
                        .colony_ships
                        .write(
                            (planet_id, colony_id, Names::Fleet::ARMADE),
                            ship_levels.armade + quantity,
                        );
                },
                ColonyBuildType::Celestia => {
                    defence::requirements::celestia(dockyard_level, techs);
                    self
                        .colony_defences
                        .write(
                            (planet_id, colony_id, Names::Defence::CELESTIA),
                            defence_levels.celestia + quantity,
                        );
                },
                ColonyBuildType::Blaster => {
                    defence::requirements::blaster(dockyard_level, techs);
                    self
                        .colony_defences
                        .write(
                            (planet_id, colony_id, Names::Defence::BLASTER),
                            defence_levels.blaster + quantity,
                        );
                },
                ColonyBuildType::Beam => {
                    defence::requirements::beam(dockyard_level, techs);
                    self
                        .colony_defences
                        .write(
                            (planet_id, colony_id, Names::Defence::BEAM),
                            defence_levels.beam + quantity,
                        );
                },
                ColonyBuildType::Astral => {
                    defence::requirements::astral(dockyard_level, techs);
                    self
                        .colony_defences
                        .write(
                            (planet_id, colony_id, Names::Defence::ASTRAL),
                            defence_levels.astral + quantity,
                        );
                },
                ColonyBuildType::Plasma => {
                    defence::requirements::plasma(dockyard_level, techs);
                    self
                        .colony_defences
                        .write(
                            (planet_id, colony_id, Names::Defence::PLASMA),
                            defence_levels.plasma + quantity,
                        );
                },
            }
        }

        fn calculate_colony_production(
            self: @ContractState, uni_speed: u128, planet_id: u32, colony_id: u8,
        ) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self.colony_resource_timer.read((planet_id, colony_id));
            let time_elapsed = time_now - last_collection_time;
            let mines_levels = self.get_colony_compounds(planet_id, colony_id);
            let position = self.colony_position.read((planet_id, colony_id));
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
                mines_levels.tritium, temp, uni_speed,
            )
                * time_elapsed.into()
                / HOUR.into();

            let celestia_production = self.position_to_celestia_production(position.orbit);
            let celestia_production: u128 = self
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
                    steel_available, total_production, energy_required,
                );
                let _quartz = compound::production_scaler(
                    quartz_available, total_production, energy_required,
                );
                let _tritium = compound::production_scaler(
                    tritium_available, total_production, energy_required,
                );

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium };
            }

            ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available }
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
