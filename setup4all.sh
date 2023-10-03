#!/bin/bash

## Arg 1 is the question
## Arg 2 is the function to execute
function question() {
    RESET="\033[0m"
    BOLD="\033[1m"
    YELLOW="\033[38;5;11m"
    REVERSE="\033[7m"

    done="false"
    while [ "$done" != "true" ]
    do
        read -p "$(echo -e $REVERSE $1  [y/n]? $RESET)" userInput

        if [[ -z "$userInput" ]]; then
            printf '%s\n' "No input entered"
            exit 1
        fi

        case $userInput in
            [Yy]* ) $2; break;;
            [Nn]* ) done="true";;
            * ) echo "Please answer y or n";;
        esac
    done
    done="false"
}
userName=$(whoami)
echo "Hello $userName"
if [[ "$userName" == "root" ]]; then    
    echo -e '\e[7mDont run this script as root!'
    exit 
fi    

#################################################################################
function setupSSH() 
{
    ln -s $winHome/.ssh $DIRECTORY 
}

DIRECTORY=~/.ssh
winHome=$(wslpath "$(wslvar USERPROFILE)")
echo "You should have a ssh key configured in GitHub.... If not then do it now!!!!!"
if [ ! -d "$DIRECTORY" ]; then
    echo "I can use the same SSH public keys from Windows home directory" $winHome/.ssh
    question "Shall I use the windows ssh keys" "setupSSH"
else
    echo "This installation already has .ssh configuration"
    echo "TODO: ssh-keygen and instructions for github setup"
    if [ ! -e ~/.ssh/id_rsa.pub ]; then
        echo "No local id_rsa.pub we could copy one from windows if it exists"
        if [ -e $winHome/.ssh/id_rsa.pub ]; then
            cp $winHome/.ssh/id_rsa.pub $DIRECTORY            
        fi
    fi
fi

#################################################################################
function updateDns()
{
    echo Updating DNS....
    sudo mv /etc/wsl.conf /etc/wsl.conf."$(date +"%m-%d-%y")"
    sudo mv /etc/resolv.conf /etc/resolv.conf."$(date +"%m-%d-%y")"

    echo "[boot]" | sudo tee -a /etc/wsl.conf
    echo "systemd=true" | sudo tee -a /etc/wsl.conf
    echo "[network]" | sudo tee -a /etc/wsl.conf
    echo "generateResolvConf=false" | sudo tee -a /etc/wsl.conf

    echo "nameserver 156.24.14.42" | sudo tee -a /etc/resolv.conf
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf

    echo DNS update complete!
}

question "Shall I configure DNS and WSL" "updateDns"

#################################################################################
function updateCerts()
{
    DIRECTORY=~/tmp

    if [ ! -d "$DIRECTORY" ]; then
        mkdir ~/tmp        
    fi    

    #echo "Do we need to detect if Zscaler is in play here?"
    zScalerTest=$(openssl s_client -showcerts -verify 5 -connect brew.sh:443 < /dev/null 2> /dev/null| grep -i "O = Zscaler Inc.")
    if [[ "$zScalerTest" == "" ]]; then 
        echo -e "\e[4mError: It looks like your not connected to the VPN or not using Zscaler.  Either way you should have skipped this step.\e[0m"
        return
    fi
    echo "Retrieve Zscaler cert from brew.sh"
    SITE=brew.sh
    openssl s_client -showcerts -verify 5 -connect $SITE:443 < /dev/null |  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".pem"; print >out}'
    echo "found certs"
    ls *.pem
    sudo cp cert3.pem /usr/local/share/ca-certificates/$SITE.crt
    rm *.pem
    echo "here are your certs"
    #ls /usr/local/share/ca-certificates/

    echo "Retrieve private cert from Wiki"
    SITE=wiki.gtech.com
    openssl s_client -showcerts -verify 5 -connect $SITE:443 < /dev/null |  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".pem"; print >out}'
    echo "found certs"
    ls *.pem
    sudo cp cert3.pem /usr/local/share/ca-certificates/$SITE.crt
    rm *.pem
    echo "here are your certs"
    ls /usr/local/share/ca-certificates/

    sudo update-ca-certificates

    export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
    echo 'export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt' >> ~/.bashrc
}

question "Would you like to update your certificates" "updateCerts"

#################################################################################
function upgradeUbuntu() 
{
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y bash-completion net-tools sshuttle
}

question "Would you like to upgrade Ubuntu" "upgradeUbuntu"

#################################################################################
function installBrew
{
    sudo apt-get install -y build-essential procps curl file git
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile
    . ~/.profile
}

question "Would you like to install Brew" "installBrew"

#################################################################################
function installAzureCli()
{
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo -E bash
}

question "Would you like to install AzureCli" "installAzureCli"

#################################################################################

function installChrome()
{
    DIRECTORY=~/tmp

    if [ ! -d "$DIRECTORY" ]; then
        mkdir ~/tmp
    fi

    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb
    sudo apt install --fix-broken -y
    sudo dpkg -i google-chrome-stable_current_amd64.deb
}

question "Would you like to install Chrome for Linux" "installChrome"

#################################################################################

function installVSCode()
{
    sudo apt-get install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    sudo apt install -y apt-transport-https
    sudo apt update -y
    sudo apt install -y code # or code-insiders

}

question "Would you like to install VSCode" "installVSCode"

#################################################################################
