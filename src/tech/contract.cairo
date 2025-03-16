use nogame::libraries::types::{TechLevels, TechUpgradeType};
use starknet::ClassHash;

#[starknet::interface]
trait ITech<TState> {
    fn upgrade(ref self: TState, impl_hash: ClassHash);
    fn process_tech_upgrade(ref self: TState, component: TechUpgradeType, quantity: u8);
    fn get_tech_levels(self: @TState, planet_id: u32) -> TechLevels;
}

#[starknet::contract]
mod Tech {
    use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::libraries::names::Names;
    use nogame::libraries::types::{E18, ERC20s, TechLevels, TechUpgradeType};
    use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
    use nogame::tech::library as tech;
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::upgradeable::UpgradeableComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    impl UpgradableInteralImpl = UpgradeableComponent::InternalImpl<ContractState>;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        game_manager: IGameDispatcher,
        tech_level: Map<(u32, u8), u8>,
        planet_manager: IPlanetDispatcher,
        compound_manager: ICompoundDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TechSpent: TechSpent,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u32,
        quantity: u8,
        spent: ERC20s,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(owner);
        self.game_manager.write(IGameDispatcher { contract_address: game });
    }

    #[abi(embed_v0)]
    impl TechImpl of super::ITech<ContractState> {
        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(impl_hash);
        }

        fn process_tech_upgrade(ref self: ContractState, component: TechUpgradeType, quantity: u8) {
            let caller = get_caller_address();
            let contracts = self.game_manager.read().get_contracts();
            contracts.planet.collect_resources(caller);
            let planet_id = contracts.planet.get_owned_planet(caller);
            let cost = self.upgrade_component(caller, planet_id, component, quantity);
            self.planet_manager.read().update_planet_points(planet_id, cost, false);
            self.emit(TechSpent { planet_id, quantity, spent: cost })
        }

        fn get_tech_levels(self: @ContractState, planet_id: u32) -> TechLevels {
            TechLevels {
                energy: self.tech_level.read((planet_id, Names::Tech::ENERGY)),
                digital: self.tech_level.read((planet_id, Names::Tech::DIGITAL)),
                beam: self.tech_level.read((planet_id, Names::Tech::BEAM)),
                armour: self.tech_level.read((planet_id, Names::Tech::ARMOUR)),
                ion: self.tech_level.read((planet_id, Names::Tech::ION)),
                plasma: self.tech_level.read((planet_id, Names::Tech::PLASMA)),
                weapons: self.tech_level.read((planet_id, Names::Tech::WEAPONS)),
                shield: self.tech_level.read((planet_id, Names::Tech::SHIELD)),
                spacetime: self.tech_level.read((planet_id, Names::Tech::SPACETIME)),
                combustion: self.tech_level.read((planet_id, Names::Tech::COMBUSTION)),
                thrust: self.tech_level.read((planet_id, Names::Tech::THRUST)),
                warp: self.tech_level.read((planet_id, Names::Tech::WARP)),
                exocraft: self.tech_level.read((planet_id, Names::Tech::EXOCRAFT)),
            }
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn upgrade_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            component: TechUpgradeType,
            quantity: u8,
        ) -> ERC20s {
            let lab_level = self.compound_manager.read().get_compounds_levels(planet_id).lab;
            let techs = self.get_tech_levels(planet_id);
            let contracts = self.game_manager.read().get_contracts();
            let mut cost: ERC20s = Default::default();
            let base_cost = tech::base_tech_costs();
            match component {
                TechUpgradeType::EnergyTech => {
                    tech::energy_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.energy, quantity, base_cost.energy);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::ENERGY),
                            techs.energy + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Digital => {
                    tech::digital_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.digital, quantity, base_cost.digital);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::DIGITAL),
                            techs.digital + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::BeamTech => {
                    tech::beam_tech_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.beam, quantity, base_cost.beam);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::BEAM),
                            techs.beam + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Armour => {
                    tech::armour_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.armour, quantity, base_cost.armour);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::ARMOUR),
                            techs.armour + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Ion => {
                    tech::ion_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.ion, quantity, base_cost.ion);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::ION),
                            techs.ion + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::PlasmaTech => {
                    tech::plasma_tech_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.plasma, quantity, base_cost.plasma);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::PLASMA),
                            techs.plasma + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Weapons => {
                    tech::weapons_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.weapons, quantity, base_cost.weapons);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::WEAPONS),
                            techs.weapons + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Shield => {
                    tech::shield_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.shield, quantity, base_cost.shield);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::SHIELD),
                            techs.shield + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Spacetime => {
                    tech::spacetime_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.spacetime, quantity, base_cost.spacetime);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::SPACETIME),
                            techs.spacetime + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Combustion => {
                    tech::combustion_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.combustion, quantity, base_cost.combustion);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::COMBUSTION),
                            techs.combustion + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Thrust => {
                    tech::thrust_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.thrust, quantity, base_cost.thrust);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::THRUST),
                            techs.thrust + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Warp => {
                    tech::warp_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.warp, quantity, base_cost.warp);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::WARP),
                            techs.warp + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                TechUpgradeType::Exocraft => {
                    tech::exocraft_requirements_check(lab_level, techs);
                    cost = tech::exocraft_cost(techs.exocraft, quantity);
                    contracts.game.check_enough_resources(caller, cost);
                    contracts.game.pay_resources_erc20(caller, cost);
                    self
                        .tech_level
                        .write(
                            (planet_id, Names::Tech::EXOCRAFT),
                            techs.exocraft + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
            }
            cost
        }
    }
}
