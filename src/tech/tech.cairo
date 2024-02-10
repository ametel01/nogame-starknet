use nogame::libraries::types::{TechUpgradeType};

#[starknet::interface]
trait ITech<TState> {
    fn process_tech_upgrade(ref self: TState, component: TechUpgradeType, quantity: u8);
}

#[starknet::contract]
mod Tech {
    use nogame::component::shared::SharedComponent;
    use nogame::compound::compound::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::libraries::types::{TechUpgradeType, Names, ERC20s, E18};
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::tech::library as tech;
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{
        get_caller_address, ContractAddress, get_block_timestamp, contract_address_const
    };

    component!(path: SharedComponent, storage: shared, event: SharedEvent);
    impl SharedInternalImpl = SharedComponent::InternalImpl<ContractState>;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        compounds: ICompoundDispatcher,
        #[substorage(v0)]
        shared: SharedComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TechSpent: TechSpent,
        #[flat]
        SharedEvent: SharedComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u32,
        quantity: u8,
        spent: ERC20s
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        storage: ContractAddress,
        colony: ContractAddress
    ) {
        self.ownable.initializer(owner);
        self.shared.initializer(storage, colony);
    }

    #[abi(embed_v0)]
    impl TechImpl of super::ITech<ContractState> {
        fn process_tech_upgrade(ref self: ContractState, component: TechUpgradeType, quantity: u8) {
            let caller = get_caller_address();
            self.shared.collect(caller);
            let planet_id = self.shared.get_owned_planet(caller);
            let cost = self.upgrade_component(caller, planet_id, component, quantity);
            self.shared.storage.read().update_planet_points(planet_id, cost);
            self.emit(TechSpent { planet_id, quantity, spent: cost })
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn upgrade_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            component: TechUpgradeType,
            quantity: u8
        ) -> ERC20s {
            let is_testnet = self.shared.storage.read().get_is_testnet();
            let lab_level = self.compounds.read().get_compounds_levels(planet_id).lab;
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            match component {
                TechUpgradeType::EnergyTech => {
                    tech::energy_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().energy;
                    let cost = tech::get_tech_cost(techs.energy, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::ENERGY_TECH,
                            techs.energy + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Digital => {
                    tech::digital_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().digital;
                    let cost = tech::get_tech_cost(techs.digital, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::DIGITAL,
                            techs.digital + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::BeamTech => {
                    tech::beam_tech_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().beam;
                    let cost = tech::get_tech_cost(techs.beam, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::BEAM_TECH,
                            techs.beam + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Armour => {
                    tech::armour_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().armour;
                    let cost = tech::get_tech_cost(techs.armour, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::ARMOUR,
                            techs.armour + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Ion => {
                    assert!(!is_testnet, "NoGame Tech: Ion tech is not available on testnet");
                    tech::ion_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().ion;
                    let cost = tech::get_tech_cost(techs.ion, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::ION,
                            techs.ion + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::PlasmaTech => {
                    assert!(!is_testnet, "NoGame Tech: Plasma tech is not available on testnet");
                    tech::plasma_tech_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().plasma;
                    let cost = tech::get_tech_cost(techs.plasma, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::PLASMA_TECH,
                            techs.plasma + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Weapons => {
                    tech::weapons_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().weapons;
                    let cost = tech::get_tech_cost(techs.weapons, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::WEAPONS,
                            techs.weapons + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Shield => {
                    tech::shield_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().shield;
                    let cost = tech::get_tech_cost(techs.shield, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::SHIELD,
                            techs.shield + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Spacetime => {
                    assert!(!is_testnet, "NoGame Tech: Spacetime tech is not available on testnet");
                    tech::spacetime_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().spacetime;
                    let cost = tech::get_tech_cost(techs.spacetime, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::SPACETIME,
                            techs.spacetime + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Combustion => {
                    tech::combustion_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().combustion;
                    let cost = tech::get_tech_cost(techs.combustion, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::COMBUSTION,
                            techs.combustion + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Thrust => {
                    tech::thrust_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().thrust;
                    let cost = tech::get_tech_cost(techs.thrust, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::THRUST,
                            techs.thrust + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Warp => {
                    assert!(!is_testnet, "NoGame Tech: Warp tech is not available on testnet");
                    tech::warp_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = tech::base_tech_costs().warp;
                    let cost = tech::get_tech_cost(techs.warp, quantity, base_cost);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::WARP,
                            techs.warp + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                TechUpgradeType::Exocraft => {
                    tech::exocraft_requirements_check(lab_level, techs);
                    let cost = tech::exocraft_cost(techs.exocraft, quantity);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::EXOCRAFT,
                            techs.exocraft + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
            }
        }
    }
}
