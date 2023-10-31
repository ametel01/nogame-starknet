#!/bin/sh

export STARKNET_RPC="https://starknet-goerli.infura.io/v3/25371764a3e44191b39d3b3b98a8c55d"
export STARKNET_KEYSTORE=".keystore.json" 
export STARKNET_ACCOUNT="testnet.json"

echo 'deploying NoGame...'
stdout=$(starkli deploy  0x0629c91161e0284f039a945fef7812664ade56461cf9ada5fe377e102c2b42d1) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NOGAME::'${nogame} > deployed_contracts.txt
echo '\n'

echo 'deploying NFT...'
sleep(5)
stdout=$(starkli deploy  0x0688f127d8ae38093ed40d4efdf2e2a57ab2206959f0a3134dfc4d4997d15221  0x4e6f47616d65207465737420506c616e6574 0x4e4774504e54  $nogame)
nft=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NFT::'${nft} >> deployed_contracts.txt
echo '\n'

echo 'deploying Steel...'
sleep(5)
stdout=$(starkli deploy 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 0x4e6f47616d65205465737420537465656c 0x4e47745354  $nogame)
steel=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'STEEL::'${steel} >> deployed_contracts.txt
echo '\n'

echo 'deploying Quartz...'
sleep(5)
stdout=$(starkli deploy  0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4  0x4e6f47616d6520746573742051756172747a 0x4e4774515a  $nogame )
quartz=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'QUARTZ::'${quartz} >> deployed_contracts.txt
echo '\n'

echo 'deploying Tritium...'
sleep(5)
stdout=$(starkli deploy  0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4  0x4e6f47616d652074657374205472697469756d 0x4e47745454  $nogame )
tritium=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'TRITIUM::'${tritium} >> deployed_contracts.txt
echo '\n'

echo 'deploying Xoroshiro...'
sleep(5)
stdout=$(starkli deploy  0x0266eb21b95149ebbbfe58c25b9a1a1b6e7e883d4e408000bbaee972f55624ec  0x1 )
rand=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'XOROSHIRO::'${rand} >> deployed_contracts.txt
echo '\n'

echo 'initializing NoGame'
sleep(5)
starkli invoke $nogame initializer $nft $steel $quartz $tritium $rand
echo '\n'
printf '\n🚀 all contracts are deployed! 🚀\n'