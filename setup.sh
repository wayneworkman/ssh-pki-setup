#!/bin/bash
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$cwd/functions.sh"
banner
checkOrInstallPackage ssh-keygen
checkOrInstallPackage sshpass
checkSelfForCerts
readHosts
for ((i=0;i<${#allAddress[@]};++i)); do
    checkPkiAccess ${allAddress[i]} ${allAccount[i]}
    if [[ "$?" -eq "1" ]]; then
        askForPassword ${allAddress[i]} ${allAccount[i]}
        if [[ "$password" != "1" && ! -z "$password" ]]; then
            setupPki ${allAddress[i]} ${allAccount[i]} $password
            checkPkiAccess ${allAddress[i]} ${allAccount[i]}
        fi
    fi
done
