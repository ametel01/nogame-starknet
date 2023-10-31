#!/bin/sh

eth_addr=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7

echo 'deploying NoGame...'
stdout=$(sncast --profile testnet deploy  -g 0x0629c91161e0284f039a945fef7812664ade56461cf9ada5fe377e102c2b42d1) 
nogame=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'NOGAME::'${nogame} > deployed_contracts.txt

echo 'deploying NFT...'
sleep 3
stdout=$(sncast --profile testnet deploy   -g 0x0688f127d8ae38093ed40d4efdf2e2a57ab2206959f0a3134dfc4d4997d15221 -c "0x4e6f47616d65207465737420506c616e6574 0x4e47744e4654 $nogame")
nft=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'NFT::'${nft} >> deployed_contracts.txt

echo 'deploying Steel...'
sleep 3
stdout=$(sncast --profile testnet deploy -g 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 -c "0x4e6f47616d65207465737420537465656c 0x4e47745354 $nogame $nft")
steel=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'STEEL::'${steel} >> deployed_contracts.txt

echo 'deploying Quartz...'
sleep 3
stdout=$(sncast --profile testnet deploy -g 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 -c "0x4e6f47616d6520746573742051756172747a 0x4e4774515a $nogame $nft")
quartz=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'QUARTZ::'${quartz} >> deployed_contracts.txt

echo 'deploying Tritium...'
sleep 3
stdout=$(sncast --profile testnet deploy -g 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 -c "0x4e6f47616d652074657374205472697469756d 0x4e47745454  $nogame $nft" )
tritium=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'TRITIUM::'${tritium} >> deployed_contracts.txt

echo 'deploying Xoroshiro...'
sleep 3
stdout=$(sncast --profile testnet deploy -g  0x0266eb21b95149ebbbfe58c25b9a1a1b6e7e883d4e408000bbaee972f55624ec -c 0x1 )
rand=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'XOROSHIRO::'${rand} >> deployed_contracts.txt

printf 'all contracts are deployed, initializing NoGame...\n'
sleep 3
sncast invoke --contract-address $nogame --function initializer --calldata $nft $steel $quartz $tritium $rand $eth_addr
printf '\n🚀 NoGame ready! 🚀\n'