#!/bin/bash
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$cwd/functions.sh"
banner
checkOrInstallPackage ssh-keygen
checkOrInstallPackage sshpass
checkSelfForCerts
readHosts

for ((i=0;i<${#allAddress[@]};++i)); do
    checkPkiAccess ${allAddress[i]} ${allAccount[i]} ${allPort[i]}
    if [[ "$?" -eq "1" ]]; then
        if [[ "${allPass[i]}" == "" ]]; then
            askForPassword ${allAddress[i]} ${allAccount[i]} ${allPort[i]}
        else
            password=${allPass[i]}
            userHasRoot ${allAddress[i]} ${allAccount[i]} $password ${allPort[i]}
        fi
        if [[ "$?" == "0" && ! -z "$password" ]]; then
            setupPki ${allAddress[i]} ${allAccount[i]} $password ${allPort[i]}
            checkPkiAccess ${allAddress[i]} ${allAccount[i]} ${allPort[i]}
        fi
    fi
done

echo
echo "Setup complete."
echo
