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
#################################################################################
function installTerraform()
{
    if [[ ! -f "/etc/apt/sources.list.d/hashicorp.list" ]]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    fi
    sudo apt update -y && sudo apt install -y terraform

}

question "Would you like to install terraform" "installTerraForm"

function installTerragrunt
{
    sudo -u $userName /home/linuxbrew/.linuxbrew/bin/brew install terragrunt
}

question "Would you like to install terragrunt" "installTerragrunt"

#################################################################################
function installAzureCli()
{
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo -E bash
}

question "Would you like to install AzureCli" "installAzureCli"

#################################################################################
