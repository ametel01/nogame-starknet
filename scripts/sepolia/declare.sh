export STARKNET_RPC="https://starknet-sepolia.blastapi.io/e88cff07-b7b6-48d0-8be6-292f660dc735/rpc/v0_6"
export STARKNET_KEYSTORE="sepolia-keystore.json" 
export STARKNET_ACCOUNT="sepolia-account.json"

cd scripts/sepolia

echo 'declaring NoGame...'
stdout=$(starkli  declare ../../target/release/nogame_NoGame.contract_class.json  --watch ) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NOGAME::'${nogame} > declared_contracts.txt

echo 'declaring ERC20NoGame...'
stdout=$(starkli  declare  ../../target/release/nogame_ERC20NoGame.contract_class.json  --watch ) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'ERC20NoGame::'${nogame} >> declared_contracts.txt

echo 'declaring ERC721NoGame...'
stdout=$(starkli  declare ../../target/release/nogame_ERC721NoGame.contract_class.json  --watch ) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'ERC721NoGame::'${nogame} >> declared_contracts.txt