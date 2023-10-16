#!/bin/sh

export STARKNET_RPC="https://starknet-goerli.g.alchemy.com/v2/cBpydqGslyhRC5kv3OKrH3uZENE7ngr3"
export STARKNET_KEYSTORE=".keystore.json" 
export STARKNET_ACCOUNT=".account.json"

echo 'deploying NoGame...'
stdout=$(starkli deploy  0x04ce3397e5617fcd35aba484cabb8ec24c4ff0da1875befb65880107dcefb6a7) 
nogame=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NOGAME::'${nogame} > deployed_contracts.txt
echo '\n'

echo 'deploying NFT...'
sleep(5)
stdout=$(starkli deploy  0x062efe1b16895e2dac359fafbc144697dff05fed3d9bb1506b270f16f8498fba  0x4e6f47616d65207465737420506c616e6574 0x4e4774504e54  $nogame)
nft=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'NFT::'${nft} >> deployed_contracts.txt
echo '\n'

echo 'deploying Steel...'
sleep(5)
stdout=$(starkli deploy 0x006e4f027a6ac23f72d4e93e0969a66953c8e00710e1b9aae218f59f763a887b 0x4e6f47616d65205465737420537465656c 0x4e47745354  $nogame)
steel=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'STEEL::'${steel} >> deployed_contracts.txt
echo '\n'

echo 'deploying Quartz...'
sleep(5)
stdout=$(starkli deploy  0x006e4f027a6ac23f72d4e93e0969a66953c8e00710e1b9aae218f59f763a887b  0x4e6f47616d6520746573742051756172747a 0x4e4774515a  $nogame )
quartz=$(echo "$stdout" | grep -o '0x[0-9a-fA-F]\+')
echo 'QUARTZ::'${quartz} >> deployed_contracts.txt
echo '\n'

echo 'deploying Tritium...'
sleep(5)
stdout=$(starkli deploy  0x006e4f027a6ac23f72d4e93e0969a66953c8e00710e1b9aae218f59f763a887b  0x4e6f47616d652074657374205472697469756d 0x4e47745454  $nogame )
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