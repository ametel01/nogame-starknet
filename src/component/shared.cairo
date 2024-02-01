use starknet::ContractAddress;

#[starknet::component]
mod SharedComponent {
    use nogame::colony::colony::{IColonyDispatcher, IColonyDispatcherTrait};
    use nogame::compound::library as compound;
    use nogame::libraries::types::{E18, ERC20s, HOUR, PlanetPosition};
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};
    use starknet::{get_block_timestamp, get_caller_address, ContractAddress};

    #[storage]
    struct Storage {
        storage: IStorageDispatcher,
        colony: IColonyDispatcher,
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            storage: ContractAddress,
            colony: ContractAddress
        ) {
            self.storage.write(IStorageDispatcher { contract_address: storage });
            self.colony.write(IColonyDispatcher { contract_address: colony });
        }

        fn collect_resources(ref self: ComponentState<TContractState>) {
            let caller = get_caller_address();
            let planet_id = self.get_owned_planet(caller);
            let colonies = self.storage.read().get_colonies_for_planet(planet_id);
            let mut i = 1;
            let colonies_len = colonies.len();
            let mut total_production: ERC20s = Default::default();
            loop {
                if colonies_len.is_zero() || i > colonies_len {
                    break;
                }
                let production = self.colony.read().collect_resources(i.try_into().unwrap());
                total_production = total_production + production;
                i += 1;
            };
            self.receive_resources_erc20(caller, total_production);
            self.collect(get_caller_address());
        }

        fn get_owned_planet(self: @ComponentState<TContractState>, caller: ContractAddress) -> u32 {
            let tokens = self.storage.read().get_token_addresses();
            tokens.erc721.token_of(caller).try_into().expect('get_owned_planet fail')
        }

        fn receive_resources_erc20(
            self: @ComponentState<TContractState>, to: ContractAddress, amounts: ERC20s
        ) {
            let tokens = self.storage.read().get_token_addresses();
            tokens.steel.mint(to, (amounts.steel * E18).into());
            tokens.quartz.mint(to, (amounts.quartz * E18).into());
            tokens.tritium.mint(to, (amounts.tritium * E18).into());
        }

        fn pay_resources_erc20(
            self: @ComponentState<TContractState>, account: ContractAddress, amounts: ERC20s
        ) {
            let tokens = self.storage.read().get_token_addresses();
            tokens.steel.burn(account, (amounts.steel * E18).into());
            tokens.quartz.burn(account, (amounts.quartz * E18).into());
            tokens.tritium.burn(account, (amounts.tritium * E18).into());
        }

        fn collect(ref self: ComponentState<TContractState>, caller: ContractAddress) {
            let planet_id = self.get_owned_planet(caller);
            assert(!planet_id.is_zero(), 'planet does not exist');
            let production = self.calculate_production(planet_id);
            self.receive_resources_erc20(caller, production);
            self.storage.read().update_resources_timer(planet_id, get_block_timestamp());
        }

        fn get_celestia_production(self: @ComponentState<TContractState>, planet_id: u32) -> u32 {
            let position = self.storage.read().get_planet_position(planet_id);
            compound::position_to_celestia_production(position.orbit)
        }

        fn get_erc20s_available(
            self: @ComponentState<TContractState>, caller: ContractAddress
        ) -> ERC20s {
            let tokens = self.storage.read().get_token_addresses();
            let steel = tokens.steel.balance_of(caller);
            let quartz = tokens.quartz.balance_of(caller);
            let tritium = tokens.tritium.balance_of(caller);

            ERC20s {
                steel: steel.try_into().unwrap(),
                quartz: quartz.try_into().unwrap(),
                tritium: tritium.try_into().unwrap()
            }
        }

        fn check_enough_resources(
            self: @ComponentState<TContractState>, caller: ContractAddress, amounts: ERC20s
        ) {
            let available: ERC20s = self.get_erc20s_available(caller);
            assert(amounts.steel <= available.steel / E18, 'Not enough steel');
            assert(amounts.quartz <= available.quartz / E18, 'Not enough quartz');
            assert(amounts.tritium <= available.tritium / E18, 'Not enough tritium');
        }

        fn calculate_production(self: @ComponentState<TContractState>, planet_id: u32) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self.storage.read().get_resources_timer(planet_id);
            let time_elapsed = time_now - last_collection_time;
            let mines_levels = self.storage.read().get_compounds_levels(planet_id);
            let position = self.storage.read().get_planet_position(planet_id);
            let temp = compound::calculate_avg_temperature(position.orbit);
            let speed = self.storage.read().get_uni_speed();
            let steel_available = compound::production::steel(mines_levels.steel)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let quartz_available = compound::production::quartz(mines_levels.quartz)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let tritium_available = compound::production::tritium(mines_levels.tritium, temp, speed)
                * time_elapsed.into()
                / HOUR.into();
            let energy_available = compound::production::energy(mines_levels.energy);
            let celestia_production = self.get_celestia_production(planet_id);
            let celestia_available = self.storage.read().get_defences_levels(planet_id).celestia;
            let energy_required = compound::consumption::base(mines_levels.steel)
                + compound::consumption::base(mines_levels.quartz)
                + compound::consumption::base(mines_levels.tritium);
            if energy_available
                + (celestia_production.into() * celestia_available).into() < energy_required {
                let _steel = compound::production_scaler(
                    steel_available, energy_available, energy_required
                );
                let _quartz = compound::production_scaler(
                    quartz_available, energy_available, energy_required
                );
                let _tritium = compound::production_scaler(
                    tritium_available, energy_available, energy_required
                );

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium, };
            }

            ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available, }
        }
    }
}
