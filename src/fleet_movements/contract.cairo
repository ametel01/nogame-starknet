use nogame::libraries::types::{
    Debris, Defences, Fleet, IncomingMission, Mission, PlanetPosition, SimulationResult,
};

#[starknet::interface]
trait IFleetMovements<TState> {
    /// Sends a fleet on a mission to a destination planet or colony.
    ///
    /// # Parameters
    /// - `f`: The fleet composition (carrier, scraper, sparrow, frigate, armade counts)
    /// - `destination`: Target position in the universe (galaxy, system, orbit)
    /// - `mission_type`: Type of mission (ATTACK, TRANSPORT, DEBRIS collection)
    /// - `speed_modifier`: Speed multiplier as percentage (100 = normal, 50 = half speed)
    /// - `colony_id`: Origin colony ID (0 for home planet, 1+ for colonies)
    ///
    /// # Effects
    /// - Deducts ships from origin planet/colony
    /// - Consumes tritium fuel based on distance and speed
    /// - Creates active mission and incoming mission records
    /// - Updates last active timestamp
    ///
    /// # Panics
    /// - If destination planet doesn't exist
    /// - If insufficient ships at origin
    /// - If active mission limit reached (based on digital tech)
    /// - If insufficient tritium for fuel
    /// - If attempting to transport to non-owned colony
    /// - If attempting to attack own planet/colony
    fn send_fleet(
        ref self: TState,
        f: Fleet,
        destination: PlanetPosition,
        mission_type: u8,
        speed_modifier: u32,
        colony_id: u8,
    );

    /// Executes an attack mission after fleet arrival at target planet.
    ///
    /// # Parameters
    /// - `mission_id`: ID of the active mission to execute
    ///
    /// # Effects
    /// - Simulates battle between attacker and defender fleets/defences
    /// - Applies fleet decay if mission arrived >2 hours ago
    /// - Updates debris field with destroyed ships/defences
    /// - Distributes loot to attacker based on cargo capacity
    /// - Updates defender's fleet and defence levels
    /// - Removes mission records
    /// - Updates planet points for both parties
    /// - Emits BattleReport event
    ///
    /// # Panics
    /// - If caller doesn't own the mission
    /// - If mission is not an ATTACK type
    /// - If fleet hasn't arrived yet
    fn attack_planet(ref self: TState, mission_id: usize);

    /// Recalls a fleet mission before it reaches destination.
    ///
    /// # Parameters
    /// - `mission_id`: ID of the mission to recall
    ///
    /// # Effects
    /// - Returns fleet to origin immediately (no travel time)
    /// - Removes mission records
    /// - Updates last active timestamp
    ///
    /// # Panics
    /// - If caller doesn't own the mission
    /// - If mission doesn't exist
    fn recall_fleet(ref self: TState, mission_id: usize);

    /// Docks a transport mission fleet at destination colony.
    ///
    /// # Parameters
    /// - `mission_id`: ID of the transport mission
    /// - `colony_id`: Destination colony ID to dock at
    ///
    /// # Effects
    /// - Adds fleet to destination colony
    /// - Removes mission records
    /// - Updates last active timestamp
    ///
    /// # Panics
    /// - If mission is not TRANSPORT type
    /// - If caller doesn't own the mission
    fn dock_fleet(ref self: TState, mission_id: usize, colony_id: u8);

    /// Collects debris from a debris field using scraper ships.
    ///
    /// # Parameters
    /// - `mission_id`: ID of the debris collection mission
    ///
    /// # Effects
    /// - Collects steel and quartz from debris field
    /// - Collection limited by scraper cargo capacity
    /// - Applies fleet decay if >2 hours since arrival
    /// - Transfers collected resources to caller
    /// - Returns fleet to origin
    /// - Removes mission records
    /// - Emits DebrisCollected event
    ///
    /// # Panics
    /// - If mission is not DEBRIS type
    /// - If fleet hasn't arrived yet
    /// - If debris field is empty
    /// - If fleet has no scrapers
    fn collect_debris(ref self: TState, mission_id: usize);

    /// Simulates a battle without executing it (for testing/planning).
    ///
    /// # Parameters
    /// - `attacker_fleet`: Attacking fleet composition
    /// - `defender_fleet`: Defending fleet composition
    /// - `defences`: Defender's defence structures
    ///
    /// # Returns
    /// - SimulationResult containing losses for attacker/defender fleets and defences
    ///
    /// # Notes
    /// - Uses default tech levels (all zero) for simulation
    /// - Does not modify any state
    fn simulate_attack(
        self: @TState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences,
    ) -> SimulationResult;

    /// Retrieves all active missions for a planet and its colonies.
    ///
    /// # Parameters
    /// - `planet_id`: ID of the planet to query
    ///
    /// # Returns
    /// - Array of Mission structs including missions from all colonies
    ///
    /// # Notes
    /// - Filters out zero/empty mission slots
    fn get_active_missions(self: @TState, planet_id: u32) -> Array<Mission>;

    /// Retrieves details of a specific mission.
    ///
    /// # Parameters
    /// - `planet_id`: ID of the planet that owns the mission
    /// - `mission_id`: ID of the mission to query
    ///
    /// # Returns
    /// - Mission struct with full details
    fn get_mission_details(self: @TState, planet_id: u32, mission_id: usize) -> Mission;

    /// Retrieves all incoming hostile missions targeting a planet.
    ///
    /// # Parameters
    /// - `planet_id`: ID of the planet to query
    ///
    /// # Returns
    /// - Array of IncomingMission structs showing enemy fleets en route
    ///
    /// # Notes
    /// - Filters out zero/empty mission slots
    fn get_incoming_missions(self: @TState, planet_id: u32) -> Array<IncomingMission>;
}

#[starknet::contract]
mod FleetMovements {
    use core::clone::Clone;
    use nogame::colony::contract::{IColonyDispatcher, IColonyDispatcherTrait};
    use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::defence::contract::IDefenceDispatcherTrait;
    use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
    use nogame::fleet_movements::{battle_settlement, library as fleet, orchestration};
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::game::interfaces::{IResourceManagerDispatcher, IResourceManagerDispatcherTrait};
    use nogame::libraries::colony_identity;
    use nogame::libraries::fleet_ops::{FleetOperation, update_fleet_levels};
    use nogame::libraries::names::Names;
    use nogame::libraries::types::{
        Debris, Defences, E18, ERC20s, Fleet, HOUR, IncomingMission, Mission, MissionCategory,
        PlanetPosition, SimulationResult, TechLevels,
    };
    use nogame::planet::contract::IPlanetDispatcherTrait;
    use nogame::tech::contract::ITechDispatcherTrait;
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_security::reentrancyguard::ReentrancyGuardComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent,
    );
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        game_manager: IGameDispatcher,
        active_missions: Map<(u32, u32), Mission>,
        active_missions_len: Map<u32, usize>,
        incoming_missions: Map<(u32, u32), IncomingMission>,
        incoming_missions_len: Map<u32, usize>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BattleReport: BattleReport,
        DebrisCollected: DebrisCollected,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
    }

    /// Battle report event emitted after an attack.
    ///
    /// # Indexed Fields (for efficient off-chain queries)
    /// - `attacker`: Attacker planet ID - Index by attacker for "my attacks" queries
    /// - `defender`: Defender planet ID - Index by defender for "attacks against me" queries
    /// - `time`: Battle timestamp - Index for time-based queries
    ///
    /// # Notes
    /// - Indexed fields enable efficient filtering in block explorers and indexers
    /// - Non-indexed fields contain detailed battle information
    #[derive(Drop, starknet::Event)]
    struct BattleReport {
        #[key]
        time: u64,
        #[key]
        attacker: u32,
        attacker_position: PlanetPosition,
        attacker_initial_fleet: Fleet,
        attacker_fleet_loss: Fleet,
        #[key]
        defender: u32,
        defender_position: PlanetPosition,
        defender_initial_fleet: Fleet,
        defender_fleet_loss: Fleet,
        initial_defences: Defences,
        defences_loss: Defences,
        loot: ERC20s,
        debris: Debris,
    }

    /// Debris collection event emitted when a player collects debris.
    ///
    /// # Indexed Fields (for efficient off-chain queries)
    /// - `planet_id`: Collector planet ID - Index for "my collections" queries
    /// - `debris_field_id`: Location of debris - Index for specific location queries
    ///
    /// # Notes
    /// - Enables efficient tracking of debris collection by player
    /// - Enables tracking of debris field activity by location
    #[derive(Drop, starknet::Event)]
    struct DebrisCollected {
        #[key]
        planet_id: u32,
        #[key]
        debris_field_id: u32,
        amount: Debris,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(owner);
        self.game_manager.write(IGameDispatcher { contract_address: game });
    }

    #[abi(embed_v0)]
    impl FleetMovementsImpl of super::IFleetMovements<ContractState> {
        fn send_fleet(
            ref self: ContractState,
            f: Fleet,
            destination: PlanetPosition,
            mission_type: u8,
            speed_modifier: u32,
            colony_id: u8,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            let caller = get_caller_address();
            let planet_id = contracts.planet.get_owned_planet(caller);
            let active_missions = self.get_active_missions(planet_id).len();
            let plan = orchestration::plan_send_mission(
                contracts,
                caller,
                f,
                destination,
                mission_type,
                speed_modifier,
                colony_id,
                active_missions,
                get_block_timestamp(),
            );
            let resource_manager = IResourceManagerDispatcher {
                contract_address: contracts.game.contract_address,
            };
            resource_manager.spend_resources(caller, plan.fuel_cost);

            self.record_mission(plan.planet_id, plan.incoming_bucket, plan.mission);
            contracts.planet.set_last_active(plan.planet_id);
            self.fleet_leave_planet(plan.origin_id, f);
        }

        fn attack_planet(ref self: ContractState, mission_id: usize) {
            self.reentrancyguard.start();

            // ========================================
            // PHASE 1: Validation and Setup
            // ========================================

            let caller = get_caller_address();
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            let origin = contracts.planet.get_owned_planet(caller);

            let mission = self.get_mission_details(origin, mission_id);
            let time_now = get_block_timestamp();
            let plan = orchestration::plan_attack(contracts, origin, mission, time_now);

            // Update the planet's debris field (can be collected by scrapers)
            let current_debries_field = contracts
                .planet
                .get_planet_debris_field(mission.destination);
            contracts
                .planet
                .set_planet_debris_field(
                    mission.destination, current_debries_field + plan.settlement.debris,
                );

            // ========================================
            // PHASE 5: Update Defender's Military
            // ========================================

            // Update defender's surviving fleet and defences
            if plan.target.is_colony {
                // Colony: only update defences (fleet stored in colony contract)
                contracts
                    .colony
                    .update_defences_after_attack(
                        plan.target.mother_planet_id,
                        plan.target.colony_id,
                        plan.settlement.defences,
                    );
            } else {
                // Home planet: update both fleet and defences
                self
                    .update_defender_fleet_levels_after_attack(
                        mission.destination, plan.target.colony_id, plan.settlement.defender_fleet,
                    );
                self
                    .update_defences_after_attack(
                        mission.destination, plan.target.colony_id, plan.settlement.defences,
                    );
            }

            // ========================================
            // PHASE 6: Calculate and Distribute Loot
            // ========================================

            // Burn defender's ERC20 tokens (spendable loot)
            if !plan.target.is_colony {
                self.process_loot_payment(mission.destination, plan.loot_spendable);
            }

            // Mint total loot to attacker
            let resource_manager = IResourceManagerDispatcher {
                contract_address: contracts.game.contract_address,
            };
            resource_manager.grant_resources(get_caller_address(), plan.total_loot);

            // ========================================
            // PHASE 7: Cleanup - Reset Timers and Return Fleet
            // ========================================

            // Reset defender's resource collection timer
            if plan.target.is_colony {
                contracts
                    .colony
                    .set_resource_timer(plan.target.mother_planet_id, plan.target.colony_id)
            } else {
                contracts.planet.set_resources_timer(mission.destination);
            }

            // Return surviving attacker fleet to origin
            self.fleet_return_planet(mission.origin, plan.settlement.attacker_fleet);

            self
                .clear_mission(
                    origin, mission_id, colony_identity::incoming_mission_bucket(plan.target),
                );

            // ========================================
            // PHASE 8: Update Planet Points and Emit Event
            // ========================================

            // Update points: attacker loses points for ships lost, defender for ships+defences lost
            self
                .update_points_after_attack(
                    origin, plan.settlement.attacker_loss, Zeroable::zero(),
                );
            if plan.target.is_colony {
                self
                    .update_points_after_attack(
                        plan.target.mother_planet_id,
                        plan.settlement.defender_loss,
                        plan.settlement.defences_loss,
                    );
            } else {
                self
                    .update_points_after_attack(
                        mission.destination,
                        plan.settlement.defender_loss,
                        plan.settlement.defences_loss,
                    );
            }

            // Update attacker's last active timestamp
            contracts.planet.set_last_active(origin);

            // Emit comprehensive battle report for frontend/indexing
            self
                .emit_battle_report(
                    time_now,
                    origin,
                    contracts.planet.get_planet_position(origin),
                    mission.fleet,
                    plan.settlement.attacker_loss,
                    mission.destination,
                    contracts.planet.get_planet_position(mission.destination),
                    plan.defender_assets.fleet,
                    plan.settlement.defender_loss,
                    plan.defender_assets.defences,
                    plan.settlement.defences_loss,
                    plan.total_loot,
                    plan.settlement.debris,
                );
        }

        fn recall_fleet(ref self: ContractState, mission_id: usize) {
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            let caller = get_caller_address();
            let origin = contracts.planet.get_owned_planet(caller);
            let mission = self.get_mission_details(origin, mission_id);
            assert!(!mission.is_zero(), "Fleet:E_MISSION_EMPTY");
            self.fleet_return_planet(mission.origin, mission.fleet);
            self
                .clear_mission(
                    origin, mission_id, self.incoming_mission_bucket(mission.destination),
                );
            contracts.planet.set_last_active(origin);
        }

        fn dock_fleet(ref self: ContractState, mission_id: usize, colony_id: u8) {
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            let caller = get_caller_address();
            let origin = contracts.planet.get_owned_planet(caller);
            let mission = self.get_mission_details(origin, mission_id);
            assert!(mission.category == MissionCategory::TRANSPORT, "Fleet:E_WRONG_CATEGORY");
            assert!(!mission.is_zero(), "Fleet:E_MISSION_EMPTY");
            self.fleet_return_planet(mission.destination, mission.fleet);
            self
                .clear_mission(
                    origin, mission_id, self.incoming_mission_bucket(mission.destination),
                );
            contracts.planet.set_last_active(origin);
        }

        fn collect_debris(ref self: ContractState, mission_id: usize) {
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            let caller = get_caller_address();
            let origin = contracts.planet.get_owned_planet(caller);

            let mission = self.get_mission_details(origin, mission_id);
            let debris = contracts.planet.get_planet_debris_field(mission.destination);
            let plan = orchestration::plan_debris_collection(
                mission, get_block_timestamp(), debris,
            );

            contracts.planet.set_planet_debris_field(mission.destination, plan.remaining_debris);

            let resource_manager = IResourceManagerDispatcher {
                contract_address: contracts.game.contract_address,
            };
            resource_manager.grant_resources(caller, plan.resource_grant);

            self.fleet_return_planet(mission.origin, plan.collector_fleet);
            self
                .clear_mission(
                    origin, mission_id, self.incoming_mission_bucket(mission.destination),
                );
            contracts.planet.set_last_active(origin);

            self
                .emit(
                    Event::DebrisCollected(
                        DebrisCollected {
                            planet_id: origin,
                            debris_field_id: mission.destination,
                            amount: plan.collectible_debris,
                        },
                    ),
                );
        }

        fn simulate_attack(
            self: @ContractState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences,
        ) -> SimulationResult {
            let techs: TechLevels = Default::default();
            let settlement = battle_settlement::settle(
                attacker_fleet, defender_fleet, defences, techs, techs, defences.celestia, 0,
            );
            SimulationResult {
                attacker_carrier: settlement.attacker_loss.carrier,
                attacker_scraper: settlement.attacker_loss.scraper,
                attacker_sparrow: settlement.attacker_loss.sparrow,
                attacker_frigate: settlement.attacker_loss.frigate,
                attacker_armade: settlement.attacker_loss.armade,
                defender_carrier: settlement.defender_loss.carrier,
                defender_scraper: settlement.defender_loss.scraper,
                defender_sparrow: settlement.defender_loss.sparrow,
                defender_frigate: settlement.defender_loss.frigate,
                defender_armade: settlement.defender_loss.armade,
                celestia: settlement.defences_loss.celestia,
                blaster: settlement.defences_loss.blaster,
                beam: settlement.defences_loss.beam,
                astral: settlement.defences_loss.astral,
                plasma: settlement.defences_loss.plasma,
            }
        }

        fn get_active_missions(self: @ContractState, planet_id: u32) -> Array<Mission> {
            let mut arr: Array<Mission> = array![];
            // Cache length read outside loop
            let len = self.active_missions_len.read(planet_id);
            if len > 0 {
                let mut i = 1;
                // Loop optimization: storage reads inside loop are necessary, but length is cached
                while i != len + 1 {
                    let mission = self.active_missions.read((planet_id, i));
                    if !mission.is_zero() {
                        arr.append(mission);
                    }
                    i += 1;
                }
            }

            // Cache contracts read to avoid redundant storage access
            let planet_colonies = self
                .game_manager
                .read()
                .get_contracts()
                .colony
                .get_colonies_for_planet(planet_id);
            let colonies_len = planet_colonies.len();
            if colonies_len > 0 {
                let mut i = 0;
                while i != colonies_len {
                    let (colony_id, _colony_position) = planet_colonies.at(i);
                    let adj_planet_id = colony_identity::encode_colony_id(planet_id, *colony_id);
                    let colony_len = self.active_missions_len.read(adj_planet_id);
                    let mut mission_id = 1;
                    while mission_id != colony_len + 1 {
                        let mission = self.active_missions.read((adj_planet_id, mission_id));
                        if !mission.is_zero() {
                            arr.append(mission);
                        }
                        mission_id += 1;
                    }
                    i += 1;
                }
            }
            arr
        }

        fn get_incoming_missions(self: @ContractState, planet_id: u32) -> Array<IncomingMission> {
            let mut arr: Array<IncomingMission> = array![];
            // Cache length read outside loop
            let len = self.incoming_missions_len.read(planet_id);
            if len > 0 {
                let mut i = 1;
                // Loop optimization: storage reads inside loop are necessary for mission data
                while i != len + 1 {
                    let mission = self.incoming_missions.read((planet_id, i));
                    if !mission.is_zero() {
                        arr.append(mission);
                    }
                    i += 1;
                }
            }
            arr
        }

        fn get_mission_details(self: @ContractState, planet_id: u32, mission_id: usize) -> Mission {
            self.active_missions.read((planet_id, mission_id))
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        /// Deducts fleet from origin planet or colony when departing.
        ///
        /// # Parameters
        /// - `planet_id`: Origin planet ID (or colony ID if >1000)
        /// - `fleet`: Fleet composition to remove
        ///
        /// # Notes
        /// - Uses shared utility library for consistent fleet operations
        /// - Handles both planet (ID < 1000) and colony (ID >= 1000) sources
        fn fleet_leave_planet(ref self: ContractState, planet_id: u32, fleet: Fleet) {
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            // Use shared utility to handle both planet and colony fleet updates
            update_fleet_levels(
                contracts.dockyard, contracts.colony, planet_id, fleet, FleetOperation::Remove,
            );
        }

        /// Adds fleet back to destination planet or colony when returning.
        ///
        /// # Parameters
        /// - `planet_id`: Destination planet ID (or colony ID if >1000)
        /// - `fleet`: Fleet composition to add
        ///
        /// # Notes
        /// - Uses shared utility library for consistent fleet operations
        /// - Handles both planet and colony destinations
        fn fleet_return_planet(ref self: ContractState, planet_id: u32, fleet: Fleet) {
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            // Use shared utility to handle both planet and colony fleet updates
            update_fleet_levels(
                contracts.dockyard, contracts.colony, planet_id, fleet, FleetOperation::Add,
            );
        }

        fn update_defender_fleet_levels_after_attack(
            ref self: ContractState, planet_id: u32, colony_id: u8, f: Fleet,
        ) {
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            if colony_id.is_zero() {
                // Batch set all ship levels
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::CARRIER, f.carrier);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::SCRAPER, f.scraper);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::SPARROW, f.sparrow);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::FRIGATE, f.frigate);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::ARMADE, f.armade);
            } else {
                // Batch set all colony ship levels
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::CARRIER, f.carrier);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::SCRAPER, f.scraper);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::SPARROW, f.sparrow);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::FRIGATE, f.frigate);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::ARMADE, f.armade);
            }
        }

        fn update_defences_after_attack(
            ref self: ContractState, planet_id: u32, colony_id: u8, d: Defences,
        ) {
            // Cache contracts read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            if colony_id.is_zero() {
                contracts
                    .defence
                    .set_defence_level(planet_id, Names::Defence::CELESTIA, d.celestia);
                contracts.defence.set_defence_level(planet_id, Names::Defence::BLASTER, d.blaster);
                contracts.defence.set_defence_level(planet_id, Names::Defence::BEAM, d.beam);
                contracts.defence.set_defence_level(planet_id, Names::Defence::ASTRAL, d.astral);
                contracts.defence.set_defence_level(planet_id, Names::Defence::PLASMA, d.plasma);
            } else {
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::CELESTIA, d.celestia);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::BLASTER, d.blaster);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::BEAM, d.beam);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::ASTRAL, d.astral);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::PLASMA, d.plasma);
            }
        }

        fn process_loot_payment(
            ref self: ContractState, destination_id: u32, loot_spendable: ERC20s,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            let resource_manager = IResourceManagerDispatcher {
                contract_address: contracts.game.contract_address,
            };
            if colony_identity::is_colony_id(destination_id) {
                let colony_mother_planet = contracts
                    .colony
                    .get_colony_mother_planet(destination_id);
                resource_manager.spend_planet_resources(colony_mother_planet, loot_spendable);
            } else {
                resource_manager.spend_planet_resources(destination_id, loot_spendable);
            }
        }

        fn update_points_after_attack(
            ref self: ContractState, planet_id: u32, fleet: Fleet, defences: Defences,
        ) {
            let resources_points = orchestration::battle_points(fleet, defences);
            if resources_points.is_zero() {
                return;
            }

            let contracts = self.game_manager.read().get_contracts();
            contracts.planet.update_planet_points(planet_id, resources_points, true);
        }

        fn emit_battle_report(
            ref self: ContractState,
            time: u64,
            attacker: u32,
            attacker_position: PlanetPosition,
            attacker_initial_fleet: Fleet,
            attacker_fleet_loss: Fleet,
            defender: u32,
            defender_position: PlanetPosition,
            defender_initial_fleet: Fleet,
            defender_fleet_loss: Fleet,
            initial_defences: Defences,
            defences_loss: Defences,
            loot: ERC20s,
            debris: Debris,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            let defender = if colony_identity::is_colony_id(defender) {
                contracts.colony.get_colony_mother_planet(defender)
            } else {
                defender
            };
            self
                .emit(
                    Event::BattleReport(
                        BattleReport {
                            time,
                            attacker,
                            attacker_position,
                            attacker_initial_fleet,
                            attacker_fleet_loss,
                            defender,
                            defender_position,
                            defender_initial_fleet,
                            defender_fleet_loss,
                            initial_defences,
                            defences_loss,
                            loot,
                            debris,
                        },
                    ),
                )
        }

        /// Adds a new active mission to storage using sparse array pattern.
        ///
        /// # Parameters
        /// - `planet_id`: Origin planet ID
        /// - `mission`: Mission data to store
        ///
        /// # Returns
        /// - Mission ID (1-indexed position in array)
        ///
        /// # Notes
        /// - Reuses empty slots from cancelled missions before extending array
        /// - Sets mission.id automatically before storing
        /// - Optimized for gas efficiency with slot reuse
        fn add_active_mission(
            ref self: ContractState, planet_id: u32, mut mission: Mission,
        ) -> usize {
            let len = self.active_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    mission.id = i;
                    self.active_missions.write((planet_id, i), mission);
                    self.active_missions_len.write(planet_id, i);
                    break;
                }
                let read_mission = self.active_missions.read((planet_id, i));
                if read_mission.is_zero() {
                    mission.id = i;
                    self.active_missions.write((planet_id, i), mission);
                    break;
                }
                i += 1;
            }
            i
        }

        fn incoming_mission_bucket(self: @ContractState, destination_id: u32) -> u32 {
            if colony_identity::is_colony_id(destination_id) {
                self
                    .game_manager
                    .read()
                    .get_contracts()
                    .colony
                    .get_colony_mother_planet(destination_id)
            } else {
                destination_id
            }
        }

        fn record_mission(
            ref self: ContractState, origin_planet_id: u32, incoming_bucket: u32, mission: Mission,
        ) -> usize {
            let mission_id = self.add_active_mission(origin_planet_id, mission);
            let incoming_mission = orchestration::incoming_mission(mission, mission_id);
            self.add_incoming_mission(incoming_bucket, incoming_mission);
            mission_id
        }

        fn clear_mission(
            ref self: ContractState, origin_planet_id: u32, mission_id: usize, incoming_bucket: u32,
        ) {
            self.set_mission(origin_planet_id, mission_id, Zeroable::zero());
            self.remove_incoming_mission(incoming_bucket, mission_id);
        }

        fn add_incoming_mission(
            ref self: ContractState, planet_id: u32, mut mission: IncomingMission,
        ) {
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    self.incoming_missions.write((planet_id, i), mission);
                    self.incoming_missions_len.write(planet_id, i);
                    break;
                }
                let read_mission = self.incoming_missions.read((planet_id, i));
                if read_mission.is_zero() {
                    self.incoming_missions.write((planet_id, i), mission);
                    break;
                }
                i += 1;
            }
        }

        /// Removes an incoming mission and compacts the array.
        ///
        /// # Parameters
        /// - `planet_id`: Target planet ID
        /// - `id_to_remove`: Mission ID at origin to remove
        ///
        /// # Notes
        /// - Uses linear search to find mission by id_at_origin
        /// - Compacts array by shifting subsequent elements forward
        /// - Clears last slot and decrements length
        /// - O(n) complexity but necessary for maintaining array integrity
        fn remove_incoming_mission(ref self: ContractState, planet_id: u32, id_to_remove: usize) {
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            let mut found = false;

            // First pass: find and remove the mission
            while i <= len {
                let mission = self.incoming_missions.read((planet_id, i));
                if mission.id_at_origin == id_to_remove {
                    self.incoming_missions.write((planet_id, i), Zeroable::zero());
                    found = true;
                    break;
                }
                i += 1;
            }

            // If we found and removed a mission, compact the array
            if found {
                // Move all non-zero missions to fill the gap
                let mut j = i;
                while j < len {
                    let next_mission = self.incoming_missions.read((planet_id, j + 1));
                    self.incoming_missions.write((planet_id, j), next_mission);
                    j += 1;
                }
                // Clear the last position and update length
                self.incoming_missions.write((planet_id, len), Zeroable::zero());
                self.incoming_missions_len.write(planet_id, len - 1);
            }
        }

        fn set_mission(
            ref self: ContractState, planet_id: u32, mission_id: usize, mission: Mission,
        ) {
            self.active_missions.write((planet_id, mission_id), mission);
        }
    }
}
