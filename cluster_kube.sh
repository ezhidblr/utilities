# exec into all kubernetes containers and run commands on all
# while keeping terminal windows open to each

source .env
SHELL='bash'

# commands to run in each container
CMDS=(

  "apt-get update && apt-get -y install vim net-tools strace tcpdump lsof redis-tools"
  "export ENVCONSUL_PID=\$(ps auxw| grep /usr/bin/envconsul | grep -v grep | grep -v /bin/sh | awk '{print \$2}')"
  "netstat -p | grep cache | grep ESTABLISHED"
)


osascript 2>/dev/null <<EOF
tell application "System Events"
  tell process "Terminal" to keystroke "n" using command down
end
EOF

window=1
pods=`kubectl get pods -n ${NAMESPACE} | grep "${CONTAINER}" | grep Running | awk '{print $1}'`
for pod in $pods
do 
    exec_cmd="kubectl exec -it ${pod} -n ${NAMESPACE} ${SHELL}"
    all_cmds=$(printf "%s; " "${CMDS[@]}")

    osascript 2>/dev/null <<EOF
    tell application "System Events"
      tell process "Terminal" to keystroke "t" using command down
    end
    tell application "Terminal"
      activate
      do script with command "${exec_cmd}" in window ${window}
      do script with command "${all_cmds}" in window ${window}
    end tell
EOF
done
