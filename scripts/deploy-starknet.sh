#!/bin/bash

# Ensure the script stops on the first error
set -e
set -o pipefail

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'
RED='\033[0;31m'

# Store the original directory
ORIGINAL_DIR="$(pwd)"

# Default build flag (true means we will build)
BUILD=true

# Update the environment file with new addresses
update_env_var() {
    local env_file=$1
    local var_name=$2
    local var_value=$3

    if grep -q "^$var_name=" "$env_file"; then
        echo -e "${BLUE}$var_name already exists, replacing in $env_file...${NC}"
        sed -i.bak "s|^$var_name=.*|$var_name=$var_value|" "$env_file" && rm "${env_file}.bak"
    else
        echo -e "${BLUE}Appending $var_name to $env_file...${NC}"
        echo "$var_name=$var_value" >>"$env_file"
    fi
}

load_env_file() {
    local env_file=$1
    local line_number=0
    local line
    local key
    local value

    while IFS= read -r line || [ -n "$line" ]; do
        line_number=$((line_number + 1))

        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        if [[ ! "$line" =~ ^([A-Z0-9_]+)=(.*)$ ]]; then
            echo -e "${RED}Error: unsupported env line in $env_file:$line_number. Use plain KEY=VALUE entries.${NC}"
            exit 1
        fi

        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"

        if [[ ! "$key" =~ ^[A-Z0-9_]+$ ]]; then
            echo -e "${RED}Error: unsupported env variable name '$key' in $env_file:$line_number${NC}"
            exit 1
        fi

        if [[ ${#value} -ge 2 ]]; then
            if [[ ${value:0:1} == \" && ${value: -1} == \" ]]; then
                value="${value:1:${#value}-2}"
            elif [[ ${value:0:1} == "'" && ${value: -1} == "'" ]]; then
                value="${value:1:${#value}-2}"
            fi
        fi

        case "$key" in
        STARKNET_PRIVATE_KEY | STARKNET_ACCOUNT | STARKNET_RPC_URL | STARKNET_ACCOUNT_ADDRESS | \
            GAME_ADDRESS | COLONY_ADDRESS | COMPOUND_ADDRESS | DEFENCE_ADDRESS | DOCKYARD_ADDRESS | \
            FLEET_ADDRESS | PLANET_ADDRESS | TECH_ADDRESS | ERC721_ADDRESS | STEEL_ADDRESS | \
            QUARTZ_ADDRESS | TRITIUM_ADDRESS | ETH_ADDRESS | UNI_SPEED | TOKEN_PRICE)
            printf -v "$key" '%s' "$value"
            ;;
        STARKNET_PUBLIC_KEY | STARKNET_ACCOUNT_[0-9]* | STARKNET_PRIVATE_KEY_[0-9]* | STARKNET_PUBLIC_KEY_[0-9]*)
            ;;
        *)
            echo -e "${RED}Error: unsupported env variable '$key' in $env_file:$line_number${NC}"
            exit 1
            ;;
        esac
    done <"$env_file"
}

parse_hash_from_output() {
    local label=$1
    local output=$2
    local parsed

    parsed=$(printf '%s\n' "$output" | grep -o '0x[a-fA-F0-9]\{64\}' | head -1 || true)
    if [ -z "$parsed" ]; then
        echo -e "${RED}Error: failed to parse $label from starkli output:${NC}" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi

    printf '%s\n' "$parsed"
}

declare_contract() {
    local contract_path=$1
    local label=$2
    local output

    if ! output=$(starkli declare "$contract_path" --account "$STARKNET_ACCOUNT" --rpc "$STARKNET_RPC_URL" "${PRIVATE_KEY_ARGS[@]}" -w 2>&1); then
        echo -e "${RED}Error: starkli declare failed for $label:${NC}" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi

    parse_hash_from_output "$label class hash" "$output"
}

deploy_contract() {
    local label=$1
    shift
    local output

    if ! output=$(starkli deploy "$@" --account "$STARKNET_ACCOUNT" --rpc "$STARKNET_RPC_URL" "${PRIVATE_KEY_ARGS[@]}" -w 2>&1); then
        echo -e "${RED}Error: starkli deploy failed for $label:${NC}" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi

    parse_hash_from_output "$label address" "$output"
}

invoke_contract() {
    local label=$1
    shift
    local output

    if ! output=$(starkli invoke "$@" --account "$STARKNET_ACCOUNT" --rpc "$STARKNET_RPC_URL" "${PRIVATE_KEY_ARGS[@]}" -w 2>&1); then
        echo -e "${RED}Error: starkli invoke failed for $label:${NC}" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --no-build)
        BUILD=false
        shift
        ;;
    local | sepolia | mainnet | docker)
        ENV_TYPE="$1"
        shift
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--no-build] <environment>"
        echo "Available environments: local, sepolia, mainnet, docker"
        exit 1
        ;;
    esac
done

# Check if environment argument is provided
if [ -z "$ENV_TYPE" ]; then
    echo "Usage: $0 [--no-build] <environment>"
    echo "Available environments: local, sepolia, mainnet, docker"
    exit 1
fi

# Validate environment argument
case "$ENV_TYPE" in
"local" | "sepolia" | "mainnet")
    ENV_FILES=("$ORIGINAL_DIR/.env.$ENV_TYPE")
    echo "Using environment: $ENV_TYPE (${ENV_FILES[0]})"
    ;;
"docker")
    # Update docker env first, then copy values to local env
    ENV_FILES=("$ORIGINAL_DIR/.env.docker")
    SECONDARY_ENV="$ORIGINAL_DIR/.env.local"
    echo "Using environment: $ENV_TYPE (updating ${ENV_FILES[0]} and will sync to $SECONDARY_ENV)"
    ;;
*)
    echo "Invalid environment. Must be one of: local, sepolia, mainnet, docker"
    exit 1
    ;;
esac

# Check if environment files exist, if not create them
for env_file in "${ENV_FILES[@]}"; do
    if [ ! -f "$env_file" ]; then
        echo "Creating environment file $env_file"
        touch "$env_file"
    fi
done

# Load the primary environment file if it has content
if [ -s "${ENV_FILES[0]}" ]; then
    load_env_file "${ENV_FILES[0]}"
fi

# Determine if we should use private key based on environment
PRIVATE_KEY_ARGS=()
if [ "$ENV_TYPE" = "local" ] || [ "$ENV_TYPE" = "docker" ]; then
    echo -e "${BLUE}Using local/docker deployment - omitting --private-key flag for built-in accounts${NC}"
else
    if [ -z "$STARKNET_PRIVATE_KEY" ]; then
        echo -e "${RED}Error: STARKNET_PRIVATE_KEY not set in ${ENV_FILES[0]}${NC}"
        exit 1
    fi
    PRIVATE_KEY_ARGS=(--private-key "$STARKNET_PRIVATE_KEY")
    echo -e "${BLUE}Using remote deployment - including --private-key flag${NC}"
fi

# Conditionally build the contracts
if [ "$BUILD" = true ]; then
    echo -e "\n${BLUE}${BOLD}Building NoGame contracts...${NC}"
    scarb build
else
    echo -e "\n${BLUE}${BOLD}Skipping build step as --no-build flag was provided...${NC}"
fi

echo -e "\n${BLUE}${BOLD}Deploying NoGame contracts...${NC}"

# Set deployer account (use Katana account #0 for local/docker)
if [ "$ENV_TYPE" = "local" ] || [ "$ENV_TYPE" = "docker" ]; then
    DEPLOYER_ADDRESS="0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec"
    STARKNET_ACCOUNT="${STARKNET_ACCOUNT:-katana-0}"
    STARKNET_RPC_URL="${STARKNET_RPC_URL:-http://localhost:5050}"
else
    if [ -z "$STARKNET_ACCOUNT_ADDRESS" ]; then
        echo -e "${RED}Error: STARKNET_ACCOUNT_ADDRESS not set in ${ENV_FILES[0]}${NC}"
        exit 1
    fi
    DEPLOYER_ADDRESS="$STARKNET_ACCOUNT_ADDRESS"
fi

echo -e "${BLUE}Using deployer address: $DEPLOYER_ADDRESS${NC}"
echo -e "${BLUE}Using RPC URL: $STARKNET_RPC_URL${NC}"

# Deploy Game contract
echo -e "\n${YELLOW}Declaring Game contract...${NC}"
GAME_HASH=$(declare_contract "./target/dev/nogame_Game.contract_class.json" "Game")
echo -e "${GREEN}Game class hash: ${BOLD}$GAME_HASH${NC}"

echo -e "${YELLOW}Deploying Game contract...${NC}"
GAME_ADDRESS=$(deploy_contract "Game" "$GAME_HASH" "$DEPLOYER_ADDRESS")
echo -e "${GREEN}Game deployed at: ${BOLD}$GAME_ADDRESS${NC}"

# Deploy Colony contract
echo -e "\n${YELLOW}Declaring Colony contract...${NC}"
COLONY_HASH=$(declare_contract "./target/dev/nogame_Colony.contract_class.json" "Colony")
echo -e "${GREEN}Colony class hash: ${BOLD}$COLONY_HASH${NC}"

echo -e "${YELLOW}Deploying Colony contract...${NC}"
COLONY_ADDRESS=$(deploy_contract "Colony" "$COLONY_HASH" "$DEPLOYER_ADDRESS" "$GAME_ADDRESS")
echo -e "${GREEN}Colony deployed at: ${BOLD}$COLONY_ADDRESS${NC}"

# Deploy Compound contract
echo -e "\n${YELLOW}Declaring Compound contract...${NC}"
COMPOUND_HASH=$(declare_contract "./target/dev/nogame_Compound.contract_class.json" "Compound")
echo -e "${GREEN}Compound class hash: ${BOLD}$COMPOUND_HASH${NC}"

echo -e "${YELLOW}Deploying Compound contract...${NC}"
COMPOUND_ADDRESS=$(deploy_contract "Compound" "$COMPOUND_HASH" "$DEPLOYER_ADDRESS" "$GAME_ADDRESS")
echo -e "${GREEN}Compound deployed at: ${BOLD}$COMPOUND_ADDRESS${NC}"

# Deploy Defence contract
echo -e "\n${YELLOW}Declaring Defence contract...${NC}"
DEFENCE_HASH=$(declare_contract "./target/dev/nogame_Defence.contract_class.json" "Defence")
echo -e "${GREEN}Defence class hash: ${BOLD}$DEFENCE_HASH${NC}"

echo -e "${YELLOW}Deploying Defence contract...${NC}"
DEFENCE_ADDRESS=$(deploy_contract "Defence" "$DEFENCE_HASH" "$DEPLOYER_ADDRESS" "$GAME_ADDRESS")
echo -e "${GREEN}Defence deployed at: ${BOLD}$DEFENCE_ADDRESS${NC}"

# Deploy Dockyard contract
echo -e "\n${YELLOW}Declaring Dockyard contract...${NC}"
DOCKYARD_HASH=$(declare_contract "./target/dev/nogame_Dockyard.contract_class.json" "Dockyard")
echo -e "${GREEN}Dockyard class hash: ${BOLD}$DOCKYARD_HASH${NC}"

echo -e "${YELLOW}Deploying Dockyard contract...${NC}"
DOCKYARD_ADDRESS=$(deploy_contract "Dockyard" "$DOCKYARD_HASH" "$DEPLOYER_ADDRESS" "$GAME_ADDRESS")
echo -e "${GREEN}Dockyard deployed at: ${BOLD}$DOCKYARD_ADDRESS${NC}"

# Deploy FleetMovements contract
echo -e "\n${YELLOW}Declaring FleetMovements contract...${NC}"
FLEET_HASH=$(declare_contract "./target/dev/nogame_FleetMovements.contract_class.json" "FleetMovements")
echo -e "${GREEN}FleetMovements class hash: ${BOLD}$FLEET_HASH${NC}"

echo -e "${YELLOW}Deploying FleetMovements contract...${NC}"
FLEET_ADDRESS=$(deploy_contract "FleetMovements" "$FLEET_HASH" "$DEPLOYER_ADDRESS" "$GAME_ADDRESS")
echo -e "${GREEN}FleetMovements deployed at: ${BOLD}$FLEET_ADDRESS${NC}"

# Deploy Planet contract
echo -e "\n${YELLOW}Declaring Planet contract...${NC}"
PLANET_HASH=$(declare_contract "./target/dev/nogame_Planet.contract_class.json" "Planet")
echo -e "${GREEN}Planet class hash: ${BOLD}$PLANET_HASH${NC}"

echo -e "${YELLOW}Deploying Planet contract...${NC}"
PLANET_ADDRESS=$(deploy_contract "Planet" "$PLANET_HASH" "$DEPLOYER_ADDRESS" "$GAME_ADDRESS")
echo -e "${GREEN}Planet deployed at: ${BOLD}$PLANET_ADDRESS${NC}"

# Deploy Tech contract
echo -e "\n${YELLOW}Declaring Tech contract...${NC}"
TECH_HASH=$(declare_contract "./target/dev/nogame_Tech.contract_class.json" "Tech")
echo -e "${GREEN}Tech class hash: ${BOLD}$TECH_HASH${NC}"

echo -e "${YELLOW}Deploying Tech contract...${NC}"
TECH_ADDRESS=$(deploy_contract "Tech" "$TECH_HASH" "$DEPLOYER_ADDRESS" "$GAME_ADDRESS")
echo -e "${GREEN}Tech deployed at: ${BOLD}$TECH_ADDRESS${NC}"

# Deploy ERC721NoGame contract
echo -e "\n${YELLOW}Declaring ERC721NoGame contract...${NC}"
ERC721_HASH=$(declare_contract "./target/dev/nogame_ERC721NoGame.contract_class.json" "ERC721NoGame")
echo -e "${GREEN}ERC721NoGame class hash: ${BOLD}$ERC721_HASH${NC}"

echo -e "${YELLOW}Deploying ERC721NoGame contract...${NC}"
ERC721_ADDRESS=$(deploy_contract "ERC721NoGame" "$ERC721_HASH" "str:NoGamePlanet" "str:NGPL" "str:https://nogame.com/planet/" "$PLANET_ADDRESS" "$DEPLOYER_ADDRESS")
echo -e "${GREEN}ERC721NoGame deployed at: ${BOLD}$ERC721_ADDRESS${NC}"

# Deploy Steel ERC20 contract
echo -e "\n${YELLOW}Declaring ERC20NoGame contract...${NC}"
ERC20_HASH=$(declare_contract "./target/dev/nogame_ERC20NoGame.contract_class.json" "ERC20NoGame")
echo -e "${GREEN}ERC20NoGame class hash: ${BOLD}$ERC20_HASH${NC}"

echo -e "${YELLOW}Deploying Steel ERC20...${NC}"
STEEL_ADDRESS=$(deploy_contract "Steel ERC20" "$ERC20_HASH" "str:NoGameSteel" "str:NGST" "$PLANET_ADDRESS" "$DEPLOYER_ADDRESS")
echo -e "${GREEN}Steel deployed at: ${BOLD}$STEEL_ADDRESS${NC}"

# Deploy Quartz ERC20 contract
echo -e "${YELLOW}Deploying Quartz ERC20...${NC}"
QUARTZ_ADDRESS=$(deploy_contract "Quartz ERC20" "$ERC20_HASH" "str:NoGameQuartz" "str:NGQZ" "$PLANET_ADDRESS" "$DEPLOYER_ADDRESS")
echo -e "${GREEN}Quartz deployed at: ${BOLD}$QUARTZ_ADDRESS${NC}"

# Deploy Tritium ERC20 contract
echo -e "${YELLOW}Deploying Tritium ERC20...${NC}"
TRITIUM_ADDRESS=$(deploy_contract "Tritium ERC20" "$ERC20_HASH" "str:NoGameTritium" "str:NGTR" "$PLANET_ADDRESS" "$DEPLOYER_ADDRESS")
echo -e "${GREEN}Tritium deployed at: ${BOLD}$TRITIUM_ADDRESS${NC}"

# Deploy ETH token (for local/docker use Katana's ETH, for testnet deploy a test token)
if [ "$ENV_TYPE" = "local" ] || [ "$ENV_TYPE" = "docker" ]; then
    # Use Katana's pre-deployed ETH token
    ETH_ADDRESS="0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
    echo -e "${GREEN}Using Katana pre-deployed ETH at: ${BOLD}$ETH_ADDRESS${NC}"
else
    # Deploy test ETH token for testnet
    echo -e "\n${YELLOW}Declaring ERC20Upgradeable contract...${NC}"
    ETH_HASH=$(declare_contract "./target/dev/openzeppelin_token_erc20_ERC20Upgradeable.contract_class.json" "ERC20Upgradeable")
    echo -e "${GREEN}ERC20Upgradeable class hash: ${BOLD}$ETH_HASH${NC}"

    echo -e "${YELLOW}Deploying ETH token...${NC}"
    ETH_SUPPLY="u256:1000000000000000000000"
    ETH_ADDRESS=$(deploy_contract "ETH token" "$ETH_HASH" "str:Ether" "str:ETH" "$ETH_SUPPLY" "$DEPLOYER_ADDRESS" "$DEPLOYER_ADDRESS")
    echo -e "${GREEN}ETH deployed at: ${BOLD}$ETH_ADDRESS${NC}"
fi

# Initialize Game contract
echo -e "\n${YELLOW}Initializing Game contract...${NC}"
UNI_SPEED="u128:1"
TOKEN_PRICE="u128:1000000000000000000"

invoke_contract "Game initialization" "$GAME_ADDRESS" initialize \
    "$COLONY_ADDRESS" \
    "$COMPOUND_ADDRESS" \
    "$DEFENCE_ADDRESS" \
    "$DOCKYARD_ADDRESS" \
    "$FLEET_ADDRESS" \
    "$PLANET_ADDRESS" \
    "$TECH_ADDRESS" \
    "$ERC721_ADDRESS" \
    "$STEEL_ADDRESS" \
    "$QUARTZ_ADDRESS" \
    "$TRITIUM_ADDRESS" \
    "$ETH_ADDRESS" \
    "$UNI_SPEED" \
    "$TOKEN_PRICE"

echo -e "${GREEN}Game contract initialized successfully!${NC}"

echo -e "\n${GREEN}${BOLD}All NoGame contracts deployed!${NC}"

# Update environment files
for env_file in "${ENV_FILES[@]}"; do
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Warning: $env_file not found, skipping...${NC}"
        continue
    fi
    update_env_var "$env_file" "GAME_ADDRESS" "$GAME_ADDRESS"
    update_env_var "$env_file" "COLONY_ADDRESS" "$COLONY_ADDRESS"
    update_env_var "$env_file" "COMPOUND_ADDRESS" "$COMPOUND_ADDRESS"
    update_env_var "$env_file" "DEFENCE_ADDRESS" "$DEFENCE_ADDRESS"
    update_env_var "$env_file" "DOCKYARD_ADDRESS" "$DOCKYARD_ADDRESS"
    update_env_var "$env_file" "FLEET_ADDRESS" "$FLEET_ADDRESS"
    update_env_var "$env_file" "PLANET_ADDRESS" "$PLANET_ADDRESS"
    update_env_var "$env_file" "TECH_ADDRESS" "$TECH_ADDRESS"
    update_env_var "$env_file" "ERC721_ADDRESS" "$ERC721_ADDRESS"
    update_env_var "$env_file" "STEEL_ADDRESS" "$STEEL_ADDRESS"
    update_env_var "$env_file" "QUARTZ_ADDRESS" "$QUARTZ_ADDRESS"
    update_env_var "$env_file" "TRITIUM_ADDRESS" "$TRITIUM_ADDRESS"
    update_env_var "$env_file" "ETH_ADDRESS" "$ETH_ADDRESS"
    update_env_var "$env_file" "STARKNET_RPC_URL" "$STARKNET_RPC_URL"
done

# If in docker mode, sync addresses to .env.local
if [ "$ENV_TYPE" = "docker" ] && [ -f "$SECONDARY_ENV" ]; then
    echo -e "${BLUE}Syncing addresses to $SECONDARY_ENV...${NC}"
    update_env_var "$SECONDARY_ENV" "GAME_ADDRESS" "$GAME_ADDRESS"
    update_env_var "$SECONDARY_ENV" "COLONY_ADDRESS" "$COLONY_ADDRESS"
    update_env_var "$SECONDARY_ENV" "COMPOUND_ADDRESS" "$COMPOUND_ADDRESS"
    update_env_var "$SECONDARY_ENV" "DEFENCE_ADDRESS" "$DEFENCE_ADDRESS"
    update_env_var "$SECONDARY_ENV" "DOCKYARD_ADDRESS" "$DOCKYARD_ADDRESS"
    update_env_var "$SECONDARY_ENV" "FLEET_ADDRESS" "$FLEET_ADDRESS"
    update_env_var "$SECONDARY_ENV" "PLANET_ADDRESS" "$PLANET_ADDRESS"
    update_env_var "$SECONDARY_ENV" "TECH_ADDRESS" "$TECH_ADDRESS"
    update_env_var "$SECONDARY_ENV" "ERC721_ADDRESS" "$ERC721_ADDRESS"
    update_env_var "$SECONDARY_ENV" "STEEL_ADDRESS" "$STEEL_ADDRESS"
    update_env_var "$SECONDARY_ENV" "QUARTZ_ADDRESS" "$QUARTZ_ADDRESS"
    update_env_var "$SECONDARY_ENV" "TRITIUM_ADDRESS" "$TRITIUM_ADDRESS"
    update_env_var "$SECONDARY_ENV" "ETH_ADDRESS" "$ETH_ADDRESS"
    update_env_var "$SECONDARY_ENV" "STARKNET_RPC_URL" "$STARKNET_RPC_URL"
fi

echo -e "\n${GREEN}${BOLD}Contract addresses saved to ${ENV_FILES[0]}${NC}"

# Print summary
echo -e "\n${BLUE}${BOLD}Deployment Summary:${NC}"
echo -e "${YELLOW}Game:${NC} $GAME_ADDRESS"
echo -e "${YELLOW}Colony:${NC} $COLONY_ADDRESS"
echo -e "${YELLOW}Compound:${NC} $COMPOUND_ADDRESS"
echo -e "${YELLOW}Defence:${NC} $DEFENCE_ADDRESS"
echo -e "${YELLOW}Dockyard:${NC} $DOCKYARD_ADDRESS"
echo -e "${YELLOW}Fleet:${NC} $FLEET_ADDRESS"
echo -e "${YELLOW}Planet:${NC} $PLANET_ADDRESS"
echo -e "${YELLOW}Tech:${NC} $TECH_ADDRESS"
echo -e "${YELLOW}ERC721:${NC} $ERC721_ADDRESS"
echo -e "${YELLOW}Steel:${NC} $STEEL_ADDRESS"
echo -e "${YELLOW}Quartz:${NC} $QUARTZ_ADDRESS"
echo -e "${YELLOW}Tritium:${NC} $TRITIUM_ADDRESS"
echo -e "${YELLOW}ETH:${NC} $ETH_ADDRESS"
