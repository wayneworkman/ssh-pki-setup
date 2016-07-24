#!/bin/bash
dots() {
    local pad=$(printf "%0.1s" "."{1..70})
    printf " * %s%*.*s" "$1" 0 $((70-${#1})) "$pad"
    return 0
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
    echo "Done"
}
checkPkiAccess() {
    address="$1"
    account="$2"
    dots "Checking access to $address using account $account"
    pkiSet=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $nodeUser@$ngmHostname "echo 'true'" 2>&1)
    if [[ "$pkiSet" == "true" ]]; then
        echo "Authorized"
        return 0
    elif [[ "$pkiSet" == "Permission denied"* ]]; then
        echo "Not Authorized"
        return 1
    else
        echo "Error!"
        return 2
    fi
}
setupPki() {
    address="$1"
    account="$2"
    pass="$3"
    ping -i 5 -c 1 $address > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        userHasRoot=$(sshpass -p$pass ssh $account@$address "echo $pass | sudo -i > /dev/null 2>&1;echo \$?")


        if [[ "$userHasRoot" == "0" ]]; then
            #The user given can be root, setup ssh pki.
            destinationDir=$(sshpass -p$pass ssh $account@$address "echo ~")
            sshpass -p$pass scp $HOME/.ssh/id_rsa.pub $account@$address:$destinationDir
            rootDir=$(sshpass -p$pass ssh $account@$address "echo $pass | sudo -i > /dev/null 2>&1;echo ~")
            sshpass -p$pass ssh $account@$address "echo $pass | sudo -i > /dev/null 2>&1;mkdir -p $rootDir/.ssh;cat $destinationDir/id_rsa.pub >> /.ssh/authorized_keys;rm -f $destinationDir/id_rsa.pub"
            checkPkiAccess
        else
            echo
            echo "  Account \"$account\" cannot become root on \"$address\"."
            echo "  You must to provide a different account for this address."
            echo
        fi
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
