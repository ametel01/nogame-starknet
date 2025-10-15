# Quick Start - NoGame Deployment

This guide will help you quickly deploy NoGame contracts to Katana for local development.

## Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) v2.12.2
- [Starkli](https://book.starkli.rs/)
- [Docker](https://www.docker.com/) (for Katana in Docker)
- OR [Katana](https://book.dojoengine.org/toolchain/katana) (for local Katana)

## Quick Start (3 Steps)

### 1. Start Katana

**Option A: Local Katana**
```bash
katana --accounts 10 --seed 0 --disable-fee
```

**Option B: Docker Katana (in your frontend repo)**
```bash
cd nogame-app
docker-compose up katana
```

### 2. Copy Environment File

```bash
cd nogame-starknet
cp .env.local.example .env.local
```

### 3. Deploy Contracts

```bash
./scripts/deploy-starknet.sh local
```

That's it! The script will:
- Build all contracts
- Deploy them to Katana
- Initialize the game
- Save contract addresses to `.env.local`

## Integration with Frontend

### Add as Git Submodule

From your frontend repository:

```bash
cd nogame-app
git submodule add https://github.com/ametel01/nogame-starknet.git contracts/nogame-starknet
git submodule update --init --recursive
```

### Docker Compose Setup

The Katana service has already been added to your `docker-compose.yml`:

```yaml
katana:
  image: ghcr.io/dojoengine/katana:latest
  container_name: nogame-katana
  ports:
    - "5050:5050"
  command: --host 0.0.0.0 --accounts 10 --seed 0 --disable-fee
  networks:
    - nogame-network
```

### Deploy in Docker

```bash
# From nogame-app directory
docker-compose up -d katana

# From nogame-starknet directory (as submodule)
cd contracts/nogame-starknet
cp .env.docker.example .env.docker
./scripts/deploy-starknet.sh docker
```

## Using the Deployed Contracts

After deployment, your `.env.local` will contain all contract addresses:

```bash
GAME_ADDRESS=0x...
PLANET_ADDRESS=0x...
COLONY_ADDRESS=0x...
# ... etc
```

### Test the Deployment

Generate a test planet:

```bash
source .env.local

# Approve ETH spending
starkli invoke $ETH_ADDRESS approve \
  $PLANET_ADDRESS u256:2000000000000000000 \
  --account katana-0 \
  --rpc $STARKNET_RPC_URL

# Generate planet
starkli invoke $PLANET_ADDRESS generate_planet \
  --account katana-0 \
  --rpc $STARKNET_RPC_URL
```

## Available Accounts

Katana provides 10 pre-funded accounts (with `--seed 0`):

**Account #0 (Default deployer)**
- Address: `0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec`
- Private: `0xc5b2fcab997346f3ea1c00b002ecf6f382c5f9c9659a3894eb783c5320f912`

See `.env.local.example` for additional test accounts.

## Development Workflow

```bash
# Make changes to contracts
vim src/planet/contract.cairo

# Rebuild and redeploy
./scripts/deploy-starknet.sh local

# Run tests
scarb test
```

## Troubleshooting

**Katana not responding?**
```bash
curl http://localhost:5050
```

**Starkli account not found?**
```bash
# Create Katana account file
starkli account fetch 0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec \
  --rpc http://localhost:5050 \
  --output ~/.starkli-wallets/deployer/katana-0.json
```

**Need to redeploy?**
```bash
# Restart Katana to reset state
docker-compose restart katana
# OR
pkill katana && katana --accounts 10 --seed 0 --disable-fee

# Redeploy
./scripts/deploy-starknet.sh local
```

## Advanced Options

### Skip Build

```bash
./scripts/deploy-starknet.sh --no-build local
```

### Deploy to Testnet

```bash
# Create .env.sepolia
cp .env.local.example .env.sepolia

# Edit with your testnet account details
vim .env.sepolia

# Deploy
./scripts/deploy-starknet.sh sepolia
```

## Next Steps

- Read [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed architecture
- Explore test examples in `tests/` directory
- Check contract interfaces in `src/` directory

## Resources

- [NoGame Docs](https://docs.nogame.io)
- [Starknet Book](https://book.starknet.io)
- [Katana Docs](https://book.dojoengine.org/toolchain/katana)
- [Starkli Docs](https://book.starkli.rs)
