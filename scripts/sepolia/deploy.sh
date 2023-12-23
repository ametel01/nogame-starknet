#!/bin/sh
eth_addr=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
receiver=0x00d5b7d5883c00d106c9df28f24a7c46472ef3006f1460d0649a4256f188b906
speed=2
price=0

export STARKNET_RPC="https://starknet-sepolia.blastapi.io/e88cff07-b7b6-48d0-8be6-292f660dc735/rpc/v0_6"
export STARKNET_KEYSTORE="sepolia-keystore.json" 
export STARKNET_ACCOUNT="sepolia-account.json"

echo 'deploying NoGame...'
stdout=$(starkli deploy --watch 0x03e95016c42fd9b3ce620c4f88d16feea383e78f778e6cd3d747844120ea5997) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NOGAME::'${nogame} > deployed_contracts.txt

echo 'deploying NFT...'
stdout=$(starkli deploy --watch 0x03beecc92434a1796590c70028c455c625693ff224aad5af0f34c1744b3f7e25 0x4e6f47616d65207465737420506c616e6574 0x4e47744e4654 $nogame $receiver)
nft=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NFT::'${nft} >> deployed_contracts.txt

echo 'deploying Steel...'
stdout=$(starkli deploy --watch 0x01dc68462b510175c098d918f4b620ce5a52c0ebfd35450678db8f6c9476ef19 0x4e6f47616d65205465737420537465656c 0x4e47745354  $nogame $nft)
steel=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'STEEL::'${steel} >> deployed_contracts.txt

echo 'deploying Quartz...'
stdout=$(starkli deploy --watch 0x01dc68462b510175c098d918f4b620ce5a52c0ebfd35450678db8f6c9476ef19  0x4e6f47616d6520746573742051756172747a 0x4e4774515a  $nogame $nft)
quartz=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'QUARTZ::'${quartz} >> deployed_contracts.txt

echo 'deploying Tritium...'
stdout=$(starkli deploy --watch 0x01dc68462b510175c098d918f4b620ce5a52c0ebfd35450678db8f6c9476ef19  0x4e6f47616d652074657374205472697469756d 0x4e47745454  $nogame $nft)
tritium=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'TRITIUM::'${tritium} >> deployed_contracts.txt

echo 'initializing NoGame...'
starkli invoke --watch $nogame initializer $nft $steel $quartz $tritium $eth_addr $receiver $speed $price
printf '\n🚀 all contracts are deployed! 🚀\n'