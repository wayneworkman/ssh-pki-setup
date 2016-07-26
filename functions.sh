#!/bin/bash
dots() {
    local pad=$(printf "%0.1s" "."{1..70})
    printf " * %s%*.*s" "$1" 0 $((70-${#1})) "$pad"
    return 0
}
setupPki() {
    local address="$1"
    local account="$2"
    local password="$3"
    local port="$4"
    dots "Setting up ssh pki for \"$account\"@\"$address\""
    doPing "$address"
    if [[ $? -eq 0 ]]; then
        sshpass -p"$password" ssh -q -t -o "Port=$port" "$account@$address" "echo $password | sudo -S sed -i.old '/requiretty/d' /etc/sudoers"
        local destinationDir=$(sshpass -p"$password" ssh -q -o "Port=$port" "$account@$address" "echo ~")
        sshpass -p$password scp -o "Port=$port" $HOME/.ssh/id_rsa.pub "$account@$address:$destinationDir"
        local rootDir=$(sshpass -p"$password" ssh -q -o "Port=$port" "$account@$address" "echo $password | sudo -S echo ~")
        local destinationFile="$destinationDir/id_rsa.pub"
        local rootSsh="$rootDir/.ssh"
        local rootFile="$rootDir/.ssh/authorized_keys"
        sshpass -p"$password" ssh -q -o "Port=$port" $account@$address "echo $password | sudo -i > /dev/null 2>&1;mkdir -p $rootSsh;cat $destinationFile >> $rootFile;rm -f $destinationFile"
        echo "Complete"
    else
        echo "No Response from $address!"
    fi
}
banner() {
    clear
    echo "          _             _    _            _               ";
    echo "         | |           | |  (_)          | |              ";
    echo "  ___ ___| |__    _ __ | | ___   ___  ___| |_ _   _ _ __  ";
    echo " / __/ __| '_ \  | '_ \| |/ / | / __|/ _ \ __| | | | '_ \ ";
    echo " \__ \__ \ | | | | |_) |   <| | \__ \  __/ |_| |_| | |_) |";
    echo " |___/___/_| |_| | .__/|_|\_\_| |___/\___|\__|\__,_| .__/ ";
    echo "                 | |                               | |    ";
    echo "                 |_|                               |_|    ";
    echo
    echo
    echo
}
readHosts() {
    hostsFile="${cwd}/hosts.csv"
    dots "Reading \"$hostsFile\""
    [ ! -f $hostsFile ] && { echo "$hostsFile file not found"; exit 99; }
    readarray -t allAlias < <(cut -d, -f1 $hostsFile)
    readarray -t allAccount < <(cut -d, -f2 $hostsFile)
    readarray -t allAddress < <(cut -d, -f3 $hostsFile)
    readarray -t allPort < <(cut -d, -f4 $hostsFile)
    readarray -t allPass < <(cut -d, -f5 $hostsFile)
    allAlias=("${allAlias[@]:1}")
    allAccount=("${allAccount[@]:1}")
    allAddress=("${allAddress[@]:1}")
    allPort=("${allPort[@]:1}")
    allPass=("${allPass[@]:1}")
    echo "Done"
}
userHasRoot() {
    local address="$1"
    local account="$2"
    local password="$3"
    local port="$4"
    local userHasRoot=$(sshpass -p$password ssh -t -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -o Port=$port $account@$address "echo $password | sudo -S 'whoami'")
    local userHasRoot=$(echo $userHasRoot | sed 's/[^a-z]*//g')
    if [[ "$userHasRoot" == "root" ]]; then
        return 0
    else
        return 1
    fi
}
askForPassword() {
    local address="$1"
    local account="$2"
    local password=""
    local port="$3"
    local i="$4"
    while [[ -z $password ]]; do
        echo
        echo "  Please provide the password for the account \"$account\" at"
        echo "  the address \"$address\""
        echo
        echo "  Type [Enter] to skip."
        echo
        echo -n "  Password: "
        read password
        echo
        if [[ -z $password ]]; then
            echo
            echo "  You have chosen to skip providing the password."
            echo "  Be aware that this may not work properly!"
            return 0
        else
            allPass[$i]="$password"
            userHasRoot "$address" "$account" "$password" "$port"
            [[ $? -eq 0 ]] && return 0
            echo
            echo "  Either account \"$account\" cannot become root, or"
            echo "  the password is bad/required. Please try again."
            echo
            password=""
        fi
    done
}
checkPkiAccess() {
    local address="$1"
    local account="$2"
    local port="$3"
    dots "Checking access to $address using account $account"
    doPing "$address"
    if [[ $? -eq 0 ]]; then
        pkiSet=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o "Port=$port" "$account@$address" "echo 'true'" 2>&1)
        if [[ $pkiSet == true ]]; then
            echo "Authorized"
            return 0
        else
            echo "Not Authorized"
            return 1
        fi
    else
        echo "No Response from $address!"
        return 2
    fi
}
doPing() {
    local address="$1"
    ping -i 5 -c 1 "$address" > /dev/null 2>&1
    return $?
}
checkOrInstallPackage() {
    local package="$1"
    local packageLocation=""
    dots "Checking package $package"
    local packageLocation=$(command -v $package)
    if [[ -e "$packageLocation" ]]; then
        echo "Already Installed"
    else
        local useYum=$(command -v yum)
        local useAptGet=$(command -v apt-get)
        local useDnf=$(command -v dnf)
        if [[ -e "$useDnf" ]]; then
            dnf install "$package" -y > /dev/null 2>&1
        elif [[ -e "$useYum" ]]; then
            yum install "$package" -y > /dev/null 2>&1
            [[ $? -eq 0 ]] && echo "Installed" || echo "Failed"
        elif [[ -e "$useAptGet" ]]; then
            apt-get install "$package" -y  > /dev/null 2>&1
        else
            echo "Unable to determine repository manager"
            return 1
        fi
        [[ $? -eq 0 ]] && echo "Installed" || echo "Failed"
    fi
}
checkSelfForCerts() {
    #Check for ssh pki files, if none, make them.
    dots "Checking for SSH PKI files on self"
    if [[ ! -e $HOME/.ssh/id_rsa || ! -s $HOME/.ssh/id_rsa || ! -e $HOME/.ssh/id_rsa.pub || ! -s $HOME/.ssh/id_rsa.pub ]]; then
        echo "Not present"
        dots "Creating SSH PKI files on self"
        mkdir -p $HOME/.ssh > /dev/null 2>&1
        rm -f $HOME/.ssh/id_rsa > /dev/null 2>&1
        rm -f $HOME/.ssh/id_rsa.pub > /dev/null 2>&1
        ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/id_rsa -N '' > /dev/null 2>&1
        chmod -R 700 $HOME/.ssh > /dev/null 2>&1
        chmod 600 $HOME/.ssh/id_rsa > /dev/null 2>&1
        echo "Done"
    else
        echo "Present"
    fi
}
writeAlias() {
    local address="$1"
    local account="$2"
    local port="$3"
    local alias="$4"
    dots "Creating alias \"$alias\" for \"$address\""
    local outfile="$HOME/.ssh/config"
    echo "Host $alias" >> $outfile
    echo "    User $account" >> $outfile
    echo "    HostName $address" >> $outfile
    echo "    Port $port" >> $outfile
    echo "Done"
}
