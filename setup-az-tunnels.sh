#!/bin/bash

userName=$(whoami)
echo "Hello $userName"
if [[ "$userName" == "root" ]]; then    
    echo -e '\e[7mDont run this script as root!'
    exit 
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

while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to reconfigure DNS and resolv[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi
    case $userInput in
        [Yy]* ) updateDns;break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

#################################################################################
function updateCerts()
{
    DIRECTORY=~/tmp

    if [ ! -d "$DIRECTORY" ]; then
        mkdir ~/tmp        
    fi    

    #echo "Do we need to detect if Zscaler is in play here?"
    zScalerTest = openssl s_client -showcerts -verify 5 -connect brew.sh:443 < /dev/null 2> /dev/null| grep -i "O = Zscaler Inc."
    if [[ "$zScaler" == "" ]]; then 
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

done="false"

while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to update your certificates[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi
    case $userInput in
        [Yy]* ) updateCerts;break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

#################################################################################
function upgradeUbuntu() 
{
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y bash-completion net-tools sshuttle
}

done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to upgrade Ubuntu[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi
    case $userInput in
        [Yy]* ) upgradeUbuntu; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

#################################################################################
function installTerraform()
{
    if [[ ! -f "/etc/apt/sources.list.d/hashicorp.list" ]]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    fi
    sudo apt update -y && sudo apt install -y terraform

}


done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to install terraform[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installTerraform; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

#################################################################################
function installBrew
{
    sudo apt-get install -y build-essential procps curl file git
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    #(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> ~/.bash_profile
    #eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile
    . ~/.profile
}

done="false"
while [ "$done" != "true" ]
do
read -p $'\e[7mWould you like to install Brew[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installBrew; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

#################################################################################
function installTerragrunt
{
    sudo -u $userName /home/linuxbrew/.linuxbrew/bin/brew install terragrunt
}

done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to install terragrunt[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installTerragrunt; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

#################################################################################
function installAzureCli()
{
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo -E bash
}

done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to install AzureCli[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installAzureCli; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

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

done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to install Chrome for Linux[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installChrome; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

#################################################################################

function installDBeaver()
{
    sudo apt update
    sudo apt -y install default-jdk
    java -version
    curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/dbeaver.gpg
    echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
    sudo apt update && sudo apt install dbeaver-ce
    apt policy dbeaver-ce
}

done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to install DBeaver[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installDBeaver; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done

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

done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to install VSCode[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installVSCode; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done


#################################################################################

function installIntellij()
{
    sudo snap install intellij-idea-ultimate --classic
}

done="false"
while [ "$done" != "true" ]
do
    read -p $'\e[7mWould you like to install IntelliJ[y/n]? \e[0m' userInput

    if [[ -z "$userInput" ]]; then
        printf '%s\n' "No input entered"
        exit 1
    fi

    case $userInput in
        [Yy]* ) installIntellij; break;;
        [Nn]* ) done="true";;
        * ) echo "Please answer y or n";;
    esac
done


#################################################################################
echo "All done!"
