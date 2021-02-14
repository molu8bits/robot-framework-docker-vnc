#!/bin/bash

# Robot Smoke-Test Variables
if [ -z "$browser" ]; then export browser=Firefox; fi
if [ -z "$UseChromeOptions" ]; then export UseChromeOptions=No; fi
if [ -z "$TESTENV" ]; then export TESTENV=environment; fi
if [ -z "$TESTNAME" ]; then export TESTNAME=Smoke; fi
if [ -z "$XWIDTH" ]; then export XWIDTH=1440; fi
if [ -z "$XHEIGHT" ]; then export XHEIGHT=900; fi
if [ -z "${DNSSERVER}" ]; then export DNSSERVER=8.8.8.8; fi
if [ -z "${username}" ]; then export username=USER; fi
if [ -z "${password}" ]; then export password=PASS; fi
if [ -z "${VNCPASS}" ]; then export VNCPASS=1234; fi


if [ -z "$http_proxy" ] || [ -z "$https_proxy" ]
then
        echo "*******************************************************"
        echo "http_proxy and https_proxy are empty. No proxy will be used to connect."
        echo "http_proxy = $http_proxy"
        echo "https_proxy = $httsp_proxy"
        export http_proxy=
        export https_proxy=
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "http_proxy and https_proxy are set as follow. Will be used to connect to the tested URLs."
        echo "http_proxy = $http_proxy"
        echo "https_proxy = $https_proxy"
        export http_proxy=$http_proxy
        export https_proxy=$https_proxy
        echo "*******************************************************"
fi


# Debugging variables
#echo "VARIABLES: browser       |       UseChromeOptions        |       TESTENV         |       username        |       password        "
#echo "VARIABLES: $browser      |       $UseChromeOptions       |       $TESTENV        |       $username       |       $password       "
#exit 0


set -e

#RES="1440x900x24"
#RES="1280x1024x24"
#RES="1920x1200x24"
#RES="1366x768x24"
export RES="${XWIDTH}x${XHEIGHT}x24"
DISPLAY=":99"


LOGFILEROBOT=/opt/reports/robot_logfile.txt
LOGFILEVNC=/opt/reports/vnc_logfile.txt

# Calculate DELAY (if not in range MIN:MAX then defaults to 30)
MIN=3
MAX=180
if (( "$DELAY" < "$MAX" )) && (( "$DELAY" > "$MIN")) ; then
        ROBODELAY=$DELAY
else
        ROBODELAY=30
fi


# Setup VNC password
x11vnc -storepasswd ${VNCPASS} ~/.vnc/passwd

# Start Xvfb
echo -e "Starting Xvfb on display ${DISPLAY} with res ${RES}"
Xvfb ${DISPLAY} -ac +iglx -screen 0 ${RES} -nolisten tcp &
sleep $ROBODELAY
#x11vnc -forever -usepw -display :99 -auth guess &
x11vnc -alwaysshared -forever -usepw -display :99 -ncache 10 -loop -o $LOGFILEVNC &
sleep $ROBODELAY
echo "You can connect now via VNC to DOCKER_HOST_IP:5900 to view execution of Robot tests  ..."
echo "*** vnc password: ${VNCPASS}"
export DISPLAY=${DISPLAY}
sleep $ROBODELAY

# Resize Browser Window to max WIDTH and HEIGHT
unset WINDOWS
while [[ -z ${WINDOWS} ]]; do eval `xdotool search --shell --onlyvisible --name ${browser}`; if [[ ! -z ${WINDOWS} ]]; then xdotool windowsize ${WINDOWS} ${XWIDTH} ${XHEIGHT}; echo "Window ${browser} resized to ${XWIDTH} ${XHEIGHT}"; fi; sleep 5; done &

echo -e "Executing robot tests"
DATESTART=`date +%Y-%m-%d_%H:%M`
echo "***** ROBOT TEST START TIME : ${DATESTART}    *****" | tee -a $LOGFILEROBOT
cd /opt/tests
# TEMPORARY EXCLUDE
xeyes -display :99 &
xterm &

pybot -d /opt/reports/ -v browser:${browser} -v TESTENV:${TESTENV} -v username:${username} -v password:${password} -v RunLocally:Yes -v UseChromeOptions:${UseChromeOptions} Tests/${TESTNAME}.robot

DATESTOP=`date +%Y-%m-%d_%H:%M`
echo "*****   ROBOT TEST END TIME :  ${DATESTOP}    *****" | tee -a $LOGFILEROBOT

if [ -n "$HOLD" ] && [ "$HOLD" == "yes" ]
then
    echo "HOLD set to 'yes' value. XServer/VNC still listen"
    echo "Stop docker container or connect via VNC and close Web Browser"
    echo " waiting 999 sec ..."
    sleep 999
else
    echo "XServer/VNC shutdown. Exiting "
    # Stop Xvfb
    kill -9 $(pgrep Xvfb)
fi
