#!/bin/sh
eth_addr=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
receiver=0x04b053f79a856f8ba34397b4dd540c3a9600aef13dddf5d976bc8547d1438e54
deployer=0x482e3154eeec94b161d40ac49b29d1da71d7184e004f3f752b7aea57991cf2

export STARKNET_RPC="https://starknet-goerli.infura.io/v3/25371764a3e44191b39d3b3b98a8c55d"
export STARKNET_KEYSTORE=".keystore.json" 
export STARKNET_ACCOUNT="testnet.json"

echo 'deploying NoGame...'
stdout=$(starkli deploy --watch 0x662ba500782fad9a355418076c74336334340d7691cb94a183977597a4a16f) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NOGAME::'${nogame} > deployed_contracts.txt

echo 'deploying NFT...'
stdout=$(starkli deploy --watch 0x61907b79a10d38817289f0efd0b53635d7dbad59c65b302aa388eaf7cb4d9f2 0x4e6f47616d65207465737420506c616e6574 0x4e47744e4654 $nogame $receiver)
nft=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NFT::'${nft} >> deployed_contracts.txt

echo 'deploying Steel...'
stdout=$(starkli deploy --watch 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 0x4e6f47616d65205465737420537465656c 0x4e47745354  $nogame $nft)
steel=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'STEEL::'${steel} >> deployed_contracts.txt

echo 'deploying Quartz...'
stdout=$(starkli deploy --watch 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4  0x4e6f47616d6520746573742051756172747a 0x4e4774515a  $nogame $nft)
quartz=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'QUARTZ::'${quartz} >> deployed_contracts.txt

echo 'deploying Tritium...'
stdout=$(starkli deploy --watch 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4  0x4e6f47616d652074657374205472697469756d 0x4e47745454  $nogame $nft)
tritium=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'TRITIUM::'${tritium} >> deployed_contracts.txt

echo 'deploying Xoroshiro...'
stdout=$(starkli deploy --watch 0x0266eb21b95149ebbbfe58c25b9a1a1b6e7e883d4e408000bbaee972f55624ec  0x31 )
rand=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'XOROSHIRO::'${rand} >> deployed_contracts.txt

echo 'initializing NoGame...'
starkli invoke --watch $nogame initializer $nft $steel $quartz $tritium $rand $eth_addr $receiver
printf '\n🚀 all contracts are deployed! 🚀\n'