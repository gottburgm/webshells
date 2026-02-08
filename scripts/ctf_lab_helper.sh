#!/bin/bash

###
### Global variabels
###

SCRIPT_PATH=$(readlink -f """${0}""")
SCRIPT_DIRECTORY=$(dirname """${SCRIPT_PATH}""")
INSTALL_SCRIPT_DIRECTORY="""${SCRIPT_DIRECTORY}/install"""
BUILDERS_SCRIPT_DIRECTORY="""${SCRIPT_DIRECTORY}/builders"""
BASE_DIRECTORY=$(dirname `readlink -f """${SCRIPT_DIRECTORY}/.."""`)

WEBSHELLS_DIRECTORY="""${BASE_DIRECTORY}/webshells"""
BINARIES_DIRECTORY="""${BASE_DIRECTORY}/bin"""


if [[ ! -z """${1}""" ]]
then
    export TARGET="${1}"
    export LAB_USERNAME=""
    export LAB_PASSWORD=""
    export DEFAULT_INTERFACE=$(ip -o -4 route show to default | awk '/dev/ {print $5}')
    export DEFAULT_INTERFACE_ADDRESS=$(ifconfig ${DEFAULT_INTERFACE_ADDRESS}  | grep -o -h -U -P 'inet\s[^0-9]*([^\s]*)' | sed "s#inet\s[^0-9]*##gi" | head -n 1)

        export MSFCONSOLE_START_SCRIPT=$(cat<<SCRIPT
set -g VERBOSE true
set -g HttpTrace true
set -g ANONYMOUS_LOGIN true
set -g RECORD_GUEST true
set -g THREADS 16

set -g RHOST ${TARGET}
set -g RHOSTS ${TARGET}

set -g LHOST ${DEFAULT_INTERFACE_ADDRESS}

set -g CreateSession true

SCRIPT
)

    if [[ ! -z """${2}""" ]]
    then
        LAB_USERNAME="""${2}"""
        MSFCONSOLE_START_SCRIPT=$(cat<<SCRIPT
${MSFCONSOLE_START_SCRIPT}
set -g USERNAME ${LAB_USERNAME}
SCRIPT
)
        if [[ ! -z """${3}""" ]]
        then
            LAB_PASSWORD="""${3}"""
            MSFCONSOLE_START_SCRIPT=$(cat<<SCRIPT
${MSFCONSOLE_START_SCRIPT}
set -g PASSWORD ${LAB_PASSWORD}
SCRIPT
)
        fi
    fi

    export MSFCONSOLE_START_SCRIPT
    export NMAP_BASE_SCAN=$(cat<<SCRIPT
#!/bin/bash

sudo nmap -v -sT -sV -O -A --open --reason -Pn -p- -T4 -vvv ${TARGET} --script "smb2-capabilities.nse,smb2-security-mode.nse,smb2-time.nse,smb2-vuln-uptime.nse,smb-double-pulsar-backdoor.nse,smb-enum-domains.nse,smb-enum-groups.nse,smb-enum-processes.nse,smb-enum-services.nse,smb-enum-sessions.nse,smb-enum-shares.nse,smb-enum-users.nse,smb-ls.nse,smb-mbenum.nse,smb-os-discovery.nse,smb-print-text.nse,smb-protocols.nse,smb-psexec.nse,smb-security-mode.nse,smb-server-stats.nse,smb-system-info.nse,smb-vuln-conficker.nse,smb-vuln-cve2009-3103.nse,smb-vuln-cve-2017-7494.nse,smb-vuln-ms06-025.nse,smb-vuln-ms07-029.nse,smb-vuln-ms08-067.nse,smb-vuln-ms10-054.nse,smb-vuln-ms10-061.nse,smb-vuln-ms17-010.nse,smb-vuln-webexec.nse,smb-webexec-exploit.nse" -oA ${TARGET}_tcp_scan
SCRIPT
)

    echo """[*] [GENERATORS] creating NMap scan script: ${HOME}/nmap_tcp_scan.sh ...."""
    echo """${NMAP_BASE_SCAN}""" > """${HOME}/nmap_tcp_scan.sh"""
    chmod +x """${HOME}/nmap_tcp_scan.sh"""

    echo """[*] setting up system base ..."""

    if [[ ! -d """${INSTALL_SCRIPT_DIRECTORY}""" ]]
    then
        echo """[!] [SETUP] missing install scripts directory: ${INSTALL_SCRIPT_DIRECTORY}"""
    else
        echo "[*] [SETUP] starting by fixing sudoers file ..."
        SUDOERS_FIXING_FILE="""${INSTALL_SCRIPT_DIRECTORY}/fix_sudoers.sh"""

        if [[ -f """${INSTALL_SCRIPT_DIRECTORY}""" ]]
        then
            chmod +x """${SUDOERS_FIXING_FILE}"""
            sh """${SUDOERS_FIXING_FILE}"""
        else
            echo """[!] [SETUP] missing sudoers fixing script: ${INSTALL_SCRIPT_DIRECTORY}/fix_sudoers.sh"""
        fi

        for file in $(find """${INSTALL_SCRIPT_DIRECTORY}/""" -type f -iname "setup*")
        do
            echo """[*] [SETUP] executing installation script: ${file} ..."""
            chmod +x """${file}"""
            sudo sh """${file}"""
        done

        sudo apt update -y
        sudo apt install unar gobuster armitage -y
        
        echo "[*] [SETUP] starting services ..."
        sudo systemctl start postgresql

        echo "[*] [SETUP] initializing MSF ..."
        sudo msfdb init
        sudo msfdb start &>/dev/null
    fi

    if [[ ! -d """${BUILDERS_SCRIPT_DIRECTORY}""" ]]
    then
        echo """[!] [GENERATORS] missing builders scripts directory: ${BUILDERS_SCRIPT_DIRECTORY}"""
    else
        echo """[*] [GENERATORS] creating msf starting script: ${HOME}/msfconsole.startup.rc ...."""
        echo """${MSFCONSOLE_START_SCRIPT}""" > """${HOME}/msfconsole.startup.rc"""

        echo "[*] [GENERATORS] running payloads/webshelles generators scripts ..."
        for file in $(find """${BUILDERS_SCRIPT_DIRECTORY}""" -type f)
        do
            echo """[*] [GENERATORS] executing generator script: ${file} ..."""
            chmod +x """${file}"""
            sh """${file}"""
        done
    fi
else
    echo "Usage: ${0} <TARGET>"
fi
