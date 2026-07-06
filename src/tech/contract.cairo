use nogame::libraries::types::{TechLevels, TechUpgradeType};
use starknet::ClassHash;

#[starknet::interface]
trait ITech<TState> {
    /// Upgrades contract implementation (owner only).
    ///
    /// # Parameters
    /// - `impl_hash`: New implementation class hash
    fn upgrade(ref self: TState, impl_hash: ClassHash);

    /// Researches technology for the calling player's planet.
    ///
    /// # Parameters
    /// - `component`: Technology to research (Energy, Digital, Beam, Armour, etc.)
    /// - `quantity`: Number of levels to research
    ///
    /// # Effects
    /// - Verifies lab level and prerequisite tech requirements
    /// - Calculates and deducts resource costs (exponential growth)
    /// - Increments technology level
    /// - Updates planet points
    /// - Emits TechSpent event
    ///
    /// # Panics
    /// - If lab level insufficient
    /// - If prerequisite technologies not researched
    /// - If insufficient resources
    fn process_tech_upgrade(ref self: TState, component: TechUpgradeType, quantity: u8);

    /// Retrieves all technology levels for a planet.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - TechLevels struct with all 13 technology levels
    ///
    /// # Notes
    /// - Technologies unlock ship types, improve combat, and increase fleet speed
    fn get_tech_levels(self: @TState, planet_id: u32) -> TechLevels;
}

#[starknet::contract]
mod Tech {
    use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::game::interfaces::{IResourceManagerDispatcher, IResourceManagerDispatcherTrait};
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
            contracts.planet.update_planet_points(planet_id, cost, false);
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
            let contracts = self.game_manager.read().get_contracts();
            let lab_level = contracts.compound.get_compounds_levels(planet_id).lab;
            let techs = self.get_tech_levels(planet_id);
            let mut cost: ERC20s = Default::default();
            let base_cost = tech::base_tech_costs();
            let resource_manager = IResourceManagerDispatcher {
                contract_address: contracts.game.contract_address,
            };
            match component {
                TechUpgradeType::EnergyTech => {
                    tech::energy_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.energy, quantity, base_cost.energy);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::ENERGY), techs.energy + quantity);
                },
                TechUpgradeType::Digital => {
                    tech::digital_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.digital, quantity, base_cost.digital);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::DIGITAL), techs.digital + quantity);
                },
                TechUpgradeType::BeamTech => {
                    tech::beam_tech_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.beam, quantity, base_cost.beam);
                    self.tech_level.write((planet_id, Names::Tech::BEAM), techs.beam + quantity);
                },
                TechUpgradeType::Armour => {
                    tech::armour_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.armour, quantity, base_cost.armour);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::ARMOUR), techs.armour + quantity);
                },
                TechUpgradeType::Ion => {
                    tech::ion_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.ion, quantity, base_cost.ion);
                    self.tech_level.write((planet_id, Names::Tech::ION), techs.ion + quantity);
                },
                TechUpgradeType::PlasmaTech => {
                    tech::plasma_tech_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.plasma, quantity, base_cost.plasma);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::PLASMA), techs.plasma + quantity);
                },
                TechUpgradeType::Weapons => {
                    tech::weapons_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.weapons, quantity, base_cost.weapons);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::WEAPONS), techs.weapons + quantity);
                },
                TechUpgradeType::Shield => {
                    tech::shield_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.shield, quantity, base_cost.shield);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::SHIELD), techs.shield + quantity);
                },
                TechUpgradeType::Spacetime => {
                    tech::spacetime_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.spacetime, quantity, base_cost.spacetime);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::SPACETIME), techs.spacetime + quantity);
                },
                TechUpgradeType::Combustion => {
                    tech::combustion_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.combustion, quantity, base_cost.combustion);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::COMBUSTION), techs.combustion + quantity);
                },
                TechUpgradeType::Thrust => {
                    tech::thrust_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.thrust, quantity, base_cost.thrust);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::THRUST), techs.thrust + quantity);
                },
                TechUpgradeType::Warp => {
                    tech::warp_requirements_check(lab_level, techs);
                    cost = tech::get_tech_cost(techs.warp, quantity, base_cost.warp);
                    self.tech_level.write((planet_id, Names::Tech::WARP), techs.warp + quantity);
                },
                TechUpgradeType::Exocraft => {
                    tech::exocraft_requirements_check(lab_level, techs);
                    cost = tech::exocraft_cost(techs.exocraft, quantity);
                    self
                        .tech_level
                        .write((planet_id, Names::Tech::EXOCRAFT), techs.exocraft + quantity);
                },
            }
            resource_manager.spend_resources(caller, cost);
            cost
        }
    }
}
