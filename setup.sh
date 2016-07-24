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
    [[ ! $? -eq 0 ]] && echo "need pki"
done
