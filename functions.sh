#!/bin/bash
dots() {
    local pad=$(printf "%0.1s" "."{1..70})
    printf " * %s%*.*s" "$1" 0 $((70-${#1})) "$pad"
    return 0
}
readHosts() {
    hostsFile="${cwd}/hosts.csv"
    OLDIFS=$IFS
    IFS=","
    dots "Reading $hostsFile"
    [ ! -f $hostsFile ] && { echo "$hostsFile file not found"; exit 99; }
    while read alias user address port
    do
        allAlias+=($alias)
        allUser+=($user)
        allAddress+=($address)
        allPort+=($port)
    done < $hostsFile
    IFS="$OLDIFS"
    echo "Done"
}
checkPkiAccess() {
    address="$1"
    account="$2"
    dots "Checking access to $address using account $account"
    pkiSet=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $nodeUser@$ngmHostname "echo 'true'" 2>&1)
    if [[ "$pkiSet" == "true" ]]; then
        echo "Authorized"
    elif [[ "$pkiSet" == "Permission denied"* ]]; then
        echo "Not Authorized"
    else
        echo "Error!"
    fi
}
checkOrInstallPackage() {
    package="$1"
    packageLocation=""
    dots "Checking package $package"
    packageLocation=$(command -v $package)
    if [[ -e "$packageLocation" ]]; then
        echo "Already Installed"
    else
        useYum=$(command -v yum)
        useAptGet=$(command -v apt-get)
        useDnf=$(command -v dnf)
        if [[ -e "$useDnf" ]]; then
            dnf install $package -y > /dev/null 2>&1
            if [[ "$?" -eq "0" ]]; then
                echo "Installed"
            else
                echo "Failed"
            fi
        elif [[ -e "$useYum" ]]; then
            yum install $package -y > /dev/null 2>&1
            if [[ "$?" -eq "0" ]]; then
                echo "Installed"
            else
                echo "Failed"
            fi
        elif [[ -e "$useAptGet" ]]; then
            apt-get install $package -y  > /dev/null 2>&1
            if [[ "$?" -eq "0" ]]; then
                echo "Installed"
            else
                echo "Failed"
            fi
        else
            echo "Unable to determine repository manager"
        fi
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
