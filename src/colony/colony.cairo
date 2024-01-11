use nogame::libraries::types::{PlanetPosition, UpgradeType, ERC20s};

#[starknet::interface]
trait INoGameColony<TState> {
    fn generate_colony(ref self: TState, planet_id: u16);
    fn process_compound_upgrade(
        ref self: TState, planet_id: u16, colony_id: u8, name: UpgradeType, quantity: u8
    );
    fn get_colony_resources(self: @TState, planet_id: u16 ,colony_id: u8) -> ERC20s;
}

mod ResourceName {
    const STEEL: felt252 = 1;
    const QUARTZ: felt252 = 1;
    const TRITIUM: felt252 = 3;
}

#[starknet::component]
mod NoGameColony {
    use starknet::{get_block_timestamp, get_caller_address};
    use nogame::libraries::types::{PlanetPosition, Names, UpgradeType, ERC20s, CompoundsLevels};
    use nogame::colony::positions;
    use nogame::libraries::compounds::CompoundCost;
    use super::ResourceName;

    #[storage]
    struct Storage {
        colony_count: usize,
        planet_colonies_count: LegacyMap::<u16, u8>,
        colony_position: LegacyMap::<(u16, u8), PlanetPosition>,
        colony_resource_timer: LegacyMap<(u16, u8), u64>,
        colony_compounds: LegacyMap::<(u16, u8, felt252), u8>,
        colony_ships: LegacyMap::<(u16, u8, felt252), u32>,
    }

    #[embeddable_as(NoGameColonyImpl)]
    impl NoGameColony<
        TContractState, +HasComponent<TContractState>
    > of super::INoGameColony<ComponentState<TContractState>> {
        fn generate_colony(ref self: ComponentState<TContractState>, planet_id: u16) {
            let colony_count = self.colony_count.read();
            let position = positions::get_colony_position(colony_count);
            let colony_id = self.planet_colonies_count.read(planet_id) + 1;
            self.colony_position.write((planet_id, colony_id), position);
            self.colony_resource_timer.write((planet_id, colony_id), get_block_timestamp());
        }

        fn process_compound_upgrade(
            ref self: ComponentState<TContractState>,
            planet_id: u16,
            colony_id: u8,
            name: UpgradeType,
            quantity: u8
        ) {
            let caller = get_caller_address();
            // self._collect_resources(caller);
            let cost = self.upgrade_component(planet_id, colony_id, name, quantity);
        }

        fn get_colony_resources(self: @ComponentState<TContractState>, planet_id: u16 ,colony_id: u8) -> ERC20s {
            let steel = self.
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn check_enough_resources(planet_id: u16, colony_id: u8, cost: ERC20s) {
            let re
        }
        fn upgrade_component(
            ref self: ComponentState<TContractState>,
            planet_id: u16,
            colony_id: u8,
            component: UpgradeType,
            quantity: u8
        ) -> ERC20s {
            match component {
                UpgradeType::SteelMine => {
                    let current_level = self.colony_compounds.read((planet_id, colony_id, Names::STEEL));
                    let cost: ERC20s = CompoundCost::steel(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self
                        .colony_compounds
                        .write(
                            (planet_id, colony_id, Names::STEEL),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::QuartzMine => {
                    let current_level = self.compounds_level.read((planet_id, Names::QUARTZ));
                    let cost: ERC20s = CompoundCost::quartz(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::QUARTZ),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::TritiumMine => {
                    let current_level = self.compounds_level.read((planet_id, Names::TRITIUM));
                    let cost: ERC20s = CompoundCost::tritium(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::TRITIUM),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::EnergyPlant => {
                    let current_level = self.compounds_level.read((planet_id, Names::ENERGY_PLANT));
                    let cost: ERC20s = CompoundCost::energy(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::ENERGY_PLANT),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Dockyard => {
                    let current_level = self.compounds_level.read((planet_id, Names::DOCKYARD));
                    let cost: ERC20s = CompoundCost::dockyard(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::DOCKYARD),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
            }
        }

        fn get_coumpounds_levels(self: @ComponentState<TContractState>, planet_id: u16, colony_id: u8) -> CompoundsLevels {
            CompoundsLevels {steel: self.colony_compounds.read(planet_id, colony_id, Names::STEEL), quartz:self.colony_compounds.read(planet_id, colony_id, Names::QUARTZ), tritium: self.colony_compounds.read(planet_id, colony_id, Names::TRITIUM), D }
        }

        fn calculate_production(self: @ContractState, planet_id: u16) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed = time_now - last_collection_time;
            let mines_levels = self.get_compounds_levels(planet_id);
            let position = self.planet_position.read(planet_id);
            let temp = self.calculate_avg_temperature(position.orbit);
            let speed = self.uni_speed.read();
            let steel_available = Production::steel(mines_levels.steel)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let quartz_available = Production::quartz(mines_levels.quartz)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let tritium_available = Production::tritium(mines_levels.tritium, temp, speed)
                * time_elapsed.into()
                / HOUR.into();
            let energy_available = Production::energy(mines_levels.energy);
            let energy_required = Consumption::base(mines_levels.steel)
                + Consumption::base(mines_levels.quartz)
                + Consumption::base(mines_levels.tritium);
            if energy_available < energy_required {
                let _steel = Compounds::production_scaler(
                    steel_available, energy_available, energy_required
                );
                let _quartz = Compounds::production_scaler(
                    quartz_available, energy_available, energy_required
                );
                let _tritium = Compounds::production_scaler(
                    tritium_available, energy_available, energy_required
                );

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium, };
            }

            ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available, }
        }
    }
}
