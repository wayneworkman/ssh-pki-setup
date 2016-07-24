#!/bin/bash
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$cwd/functions.sh"
banner
checkOrInstallPackage ssh-keygen
checkOrInstallPackage sshpass
checkSelfForCerts
readHosts

for i in "${allAddress[@]}"
do

    checkPkiAccess ${allAddress[$i]} ${allAccount[$i]}
    if [[ "$?" -eq "1" ]]; then
        echo "need pki"




    fi
    #    "${allAddress[$i]}"
    #    "${allPort[$i]}"

done
