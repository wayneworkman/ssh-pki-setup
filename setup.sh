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
        [[ -z $password ]] && askForPassword "${allAddress[i]}" "${allAccount[i]}" "${allPort[i]}" || userHasRoot "${allAddress[i]}" "${allAccount[i]}" "$password" "${allPort[i]}"
        if [[ $? -eq 0 ]]; then
            if [[ ! -z $password ]]; then
                setupPki "${allAddress[i]}" "${allAccount[i]}" "$password" "${allPort[i]}"
                checkPkiAccess "${allAddress[i]}" "${allAccount[i]}" "${allPort[i]}"
                [[ $? -eq 0 ]] && writeAlias "${allAddress[i]}" "${allAccount[i]}" "${allPort[i]}" "${allAlias[i]}"
            fi
        fi
    fi
done

echo
echo "Setup complete."
echo
