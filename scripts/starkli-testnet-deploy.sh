#!/bin/sh
eth_addr=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
receiver=0x04b053f79a856f8ba34397b4dd540c3a9600aef13dddf5d976bc8547d1438e54
deployer=0x482e3154eeec94b161d40ac49b29d1da71d7184e004f3f752b7aea57991cf2
speed=100
price=0

export STARKNET_RPC="https://starknet-goerli.infura.io/v3/25371764a3e44191b39d3b3b98a8c55d"
export STARKNET_KEYSTORE=".keystore.json" 
export STARKNET_ACCOUNT="testnet.json"

echo 'deploying NoGame...'
stdout=$(starkli deploy --watch 0x07d59df63ad1ed4ec8adb122e6c15ac0288f5319e78bcbf1587d0cc5c324d975) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NOGAME::'${nogame} > deployed_contracts.txt

echo 'deploying NFT...'
stdout=$(starkli deploy --watch 0x04bd8ee9efaf20e299720f26a6afc0cdead980a37d1f7fe60c98610874160a0f 0x4e6f47616d65207465737420506c616e6574 0x4e47744e4654 $nogame $receiver)
nft=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NFT::'${nft} >> deployed_contracts.txt

echo 'deploying Steel...'
stdout=$(starkli deploy --watch 0x05683b6ebacb63eec5751ea388f9b9379891932a8dc2458e815a777d48bd75d0 0x4e6f47616d65205465737420537465656c 0x4e47745354  $nogame $nft)
steel=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'STEEL::'${steel} >> deployed_contracts.txt

echo 'deploying Quartz...'
stdout=$(starkli deploy --watch 0x05683b6ebacb63eec5751ea388f9b9379891932a8dc2458e815a777d48bd75d0  0x4e6f47616d6520746573742051756172747a 0x4e4774515a  $nogame $nft)
quartz=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'QUARTZ::'${quartz} >> deployed_contracts.txt

echo 'deploying Tritium...'
stdout=$(starkli deploy --watch 0x05683b6ebacb63eec5751ea388f9b9379891932a8dc2458e815a777d48bd75d0  0x4e6f47616d652074657374205472697469756d 0x4e47745454  $nogame $nft)
tritium=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'TRITIUM::'${tritium} >> deployed_contracts.txt

echo 'initializing NoGame...'
starkli invoke --watch $nogame initializer $nft $steel $quartz $tritium $eth_addr $receiver $speed $price
printf '\n🚀 all contracts are deployed! 🚀\n'