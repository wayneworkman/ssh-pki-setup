#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/functions.sh"
banner
checkOrInstallPackage ssh-keygen
checkOrInstallPackage sshpass
checkSelfForCerts
readHosts

for ((i=0;i<${#allAddress[@]};++i)); do
    checkPkiAccess "${allAddress[i]}" "${allAccount[i]}" "${allPort[i]}"
    if [[ $? -eq 1 ]]; then
        password="${allPass[i]}"
        if [[ -z $password ]]; then
            askForPassword "${allAddress[i]}" "${allAccount[i]}" "${allPort[i]}"
            password="$?"
        else
            userHasRoot "${allAddress[i]}" "${allAccount[i]}" "$password" "${allPort[i]}"
        fi
        if [[ $? -eq 0 ]]; then
            echo "Here 1"
            password="${allPass[i]}"
            if [[ ! -z $password ]]; then
                echo "Here 2"
                setupPki "${allAddress[i]}" "${allAccount[i]}" "${allPass[i]}" "${allPort[i]}"
                checkPkiAccess "${allAddress[i]}" "${allAccount[i]}" "${allPort[i]}"
                [[ $? -eq 0 ]] && writeAlias "${allAddress[i]}" "${allAccount[i]}" "${allPort[i]}" "${allAlias[i]}"
else
echo "Here 3"
            fi
        fi
    fi
done

echo
echo "Setup complete."
echo
