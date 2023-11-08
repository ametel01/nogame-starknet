#!/bin/sh

eth_addr=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
receiver=0x04b053f79a856f8ba34397b4dd540c3a9600aef13dddf5d976bc8547d1438e54
deployer=0x5f3d48b8a2df30975280ac3cb937f45b4d94694513a5b7353f23176182e1d92

echo 'deploying NoGame...'
stdout=$(sncast --profile testnet deploy  -g 0x584f395d29c8cb5ce7e3eaa7b299e71f7597f4b09f304912bff63320676eddf) 
nogame=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'NOGAME::'${nogame} > deployed_contracts.txt

echo 'deploying NFT...'
# sleep 20
stdout=$(sncast --profile testnet deploy   -g 0x61907b79a10d38817289f0efd0b53635d7dbad59c65b302aa388eaf7cb4d9f2 -c "0x4e6f47616d65207465737420506c616e6574 0x4e47744e4654 $nogame $deployer")
nft=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'NFT::'${nft} >> deployed_contracts.txt

echo 'deploying Steel...'
# sleep 20
stdout=$(sncast --profile testnet deploy --unique -g 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 -c "0x4e6f47616d65207465737420537465656 0x4e47745354 $nogame $nft")
steel=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'STEEL::'${steel} >> deployed_contracts.txt

echo 'deploying Quartz...'
# sleep 20
stdout=$(sncast --profile testnet deploy -g 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 -c "0x4e6f47616d6520746573742051756172747a 0x4e4774515a $nogame $nft")
quartz=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'QUARTZ::'${quartz} >> deployed_contracts.txt

echo 'deploying Tritium...'
# sleep 20
stdout=$(sncast --profile testnet deploy -g 0x07064396f8716cb704a001ab29876ab2b5a2ecf3a7ae6ee0ec85c7c12bea89e4 -c "0x4e6f47616d652074657374205472697469756d 0x4e47745454  $nogame $nft" )
tritium=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'TRITIUM::'${tritium} >> deployed_contracts.txt

echo 'deploying Xoroshiro...'
# sleep 20
stdout=$(sncast --profile testnet deploy -g  0x0266eb21b95149ebbbfe58c25b9a1a1b6e7e883d4e408000bbaee972f55624ec -c 0x1 )
rand=$(echo "$stdout" | grep -o 'contract_address: 0x[0-9a-fA-F]\+' | awk '{print $2}')
echo 'XOROSHIRO::'${rand} >> deployed_contracts.txt

printf 'all contracts are deployed, initializing NoGame...\n'
# sleep 20
sncast invoke --profile testnet --contract-address $nogame --function initializer --calldata $nft $steel $quartz $tritium $rand $eth_addr $deployer

printf '\n🚀 NoGame ready! 🚀\n'