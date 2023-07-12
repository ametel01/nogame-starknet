#! /bin/bash
ADMIN='0x041cee10524412d87d1c9e539419b5ed70bcd28fd2a4834a66ef32ec53cdef38'


deploy() {
    source ~/cairo_env/bin/activate
    touch deployed_contracts.txt

    echo 'deploying Steel...'
    stdout=$(starknet deploy --class_hash 0x627a761a6ddfbb6fd3a370e3bddffb501e13a4852bcc0d8c425517ea139084 --inputs 0x4e6f47616d65205465737420537465656c 0x4e47745354 0x041cee10524412d87d1c9e539419b5ed70bcd28fd2a4834a66ef32ec53cdef38 --account v0.12)
    steel=$(echo ${stdout}  | grep -o -P '(?<=Contract address: ).*(?= Transaction hash:)')
    echo 'STEEL::'${steel}
    echo 'STEEL::'${steel} > deployed_contracts.txt
    sleep 5

    echo 'deploying Quartz...'
    stdout=$(starknet deploy --class_hash 0x627a761a6ddfbb6fd3a370e3bddffb501e13a4852bcc0d8c425517ea139084 --inputs 0x4e6f47616d6520746573742051756172747a 0x4e4774515a 0x041cee10524412d87d1c9e539419b5ed70bcd28fd2a4834a66ef32ec53cdef38 --account v0.12)
    quartz=$(echo ${stdout}  | grep -o -P '(?<=Contract address: ).*(?= Transaction hash:)')
    echo 'QUARTZ::'${quartz}
    echo 'QUARTZ::'${quartz} >> deployed_contracts.txt
    sleep 5

    echo 'deploying Tritium...'
    stdout=$(starknet deploy --class_hash 0x627a761a6ddfbb6fd3a370e3bddffb501e13a4852bcc0d8c425517ea139084 --inputs 0x4e6f47616d652074657374205472697469756d 0x4e47745454 0x041cee10524412d87d1c9e539419b5ed70bcd28fd2a4834a66ef32ec53cdef38 --account v0.12)
    tritium=$(echo ${stdout}  | grep -o -P '(?<=Contract address: ).*(?= Transaction hash:)')
    echo 'TRITIUM::'${tritium}
    echo 'TRITIUM::'${tritium} >> deployed_contracts.txt
    sleep 5

    echo 'deploying NFT...'
    stdout=$(starknet deploy --class_hash 0x5a96e53f2bc94f0d31ebdd18aebebb68b8e9983ce0a2731aedeb10ef43201d4 --inputs 0x4e6f47616d65207465737420506c616e6574 0x4e4774504e54 0x041cee10524412d87d1c9e539419b5ed70bcd28fd2a4834a66ef32ec53cdef38 --account v0.12)
    nft=$(echo ${stdout}  | grep -o -P '(?<=Contract address: ).*(?= Transaction hash:)')
    echo 'NFT::'${nft}
    echo 'NFT::'${nft} >> deployed_contracts.txt
    sleep 5

    echo 'deploying NoGame...'
    stdout=$(starknet deploy --class_hash 0x4fc21e24f926099169cb6296c1f52efd8fb4b3bd4f184e58dc77797c77a2784 --account v0.12 --inputs $nft $steel $quartz $tritium 2>&1) 
    nogame=$(echo ${stdout}  | grep -o -P '(?<=Contract address: ).*(?= Transaction hash:)')
    echo 'NOGAME::'${nogame}
    echo 'NOGAME::'${nogame} >> deployed_contracts.txt


}

main() {
    case "$1" in
        "deploy") deploy ;;
    esac
}

main $@