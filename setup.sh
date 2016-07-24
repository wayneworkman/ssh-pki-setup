#!/bin/bash
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$cwd/functions.sh"
banner
checkOrInstallPackage ssh-keygen
checkOrInstallPackage sshpass
checkSelfForCerts
readHosts

cnt=0
for i in "${allAddress[@]}"; do
    checkPkiAccess $i ${allAccount[$cnt]};
    [[ ! $? -eq 0 ]] && echo "need pki"
    let cnt+=1
done
cnt=0
