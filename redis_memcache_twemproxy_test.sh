#set -x

if [ -z "$1" ]; then
   echo "No host sent"
   exit 1
fi

HOST=$1

MAIN_REDIS=6379
MAIN_MEMCACHE=11211

TWEM_REDIS=22121
TWEM_MEMCACHE=22122

MEMCACHE_EXPIRE=900

KEY='twemtest_02'

generate_rand_string() {
  len=20
  RAND=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${len} | head -n 1`
}

twemproxy_cluster_test() {
  # this function will write/update a k/w on a node within the twemproxy pool
  # then it will read that value from all nodes in the twemproxy pool
  echo "Twemproxy Cluster test"

  # the node this runs on ($self) should be a node defined in /etc/nutcracker.yml
  # HOSTS array should be ALL nodes defined in /etc/nutcracker.yml
  self=`ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
  HOSTS=(
    "node1"
    "node2"
    "nodeX"
  )

  generate_rand_string
  echo -e "\nREDIS HOST ${HOST} TEST 1: write ${RAND} to local TWEM_REDIS read from external TWEM_REDIS"
  printf "set ${KEY} '${RAND}'" | redis-cli -h ${self} -p ${TWEM_REDIS}

  for host in "${HOSTS[@]}"; do
      printf "get ${KEY}" | redis-cli -h ${host} -p ${TWEM_REDIS}
      echo from $host
  done

  generate_rand_string
  echo -e "\nMEMCACHE HOST ${HOST} TEST 1: write ${RAND} to local TWEM_MEMCACHE read from external TWEM_MEMCACHE"
  printf "set ${KEY} 0 ${MEMCACHE_EXPIRE} ${#RAND}\r\n${RAND}\r\n" | nc ${self} ${TWEM_MEMCACHE}

  for host in "${HOSTS[@]}"; do
      printf "get ${KEY}\r\n" | nc ${host} ${TWEM_MEMCACHE}
      echo from $host
  done
}


redis() {
  generate_rand_string
  echo -e "\nREDIS HOST ${HOST} TEST 1: write ${RAND} to MAIN_REDIS read from MAIN_REDIS, TWEM_REDIS"
  printf "set ${KEY} '${RAND}'" | redis-cli -h ${HOST} -p ${MAIN_REDIS}
  printf "get ${KEY}" | redis-cli -h ${HOST} -p ${MAIN_REDIS} # from MAIN_REDIS
  printf "get ${KEY}" | redis-cli -h ${HOST} -p ${TWEM_REDIS} # from TWEM_REDIS

  generate_rand_string
  echo -e "\nREDIS HOST ${HOST} TEST 2: write ${RAND} to TWEM_REDIS read from MAIN_REDIS, TWEM_REDIS"
  printf "set ${KEY} '${RAND}'" | redis-cli -h ${HOST} -p ${TWEM_REDIS}
  printf "get ${KEY}" | redis-cli -h ${HOST} -p ${MAIN_REDIS} # from MAIN_REDIS
  printf "get ${KEY}" | redis-cli -h ${HOST} -p ${TWEM_REDIS} # from TWEM_REDIS
}

memcache() {
  set -x
  generate_rand_string
  echo -e "\nMEMCACHE HOST ${HOST} TEST 1: write ${RAND} to MAIN_MEMCACHE read from MAIN_MEMCACHE, TWEM_MEMCACHE"
  printf "set ${KEY} 0 ${MEMCACHE_EXPIRE} ${#RAND}\r\n${RAND}\r\n" | nc ${HOST} ${MAIN_MEMCACHE}
  printf "get ${KEY}\r\n" | nc ${HOST} ${MAIN_MEMCACHE}
  printf "get ${KEY}\r\n" | nc ${HOST} ${TWEM_MEMCACHE}


  generate_rand_string
  echo -e "\nMEMCACHE HOST ${HOST} TEST 2: write ${RAND} to TWEM_MEMCACHE read from MAIN_MEMCACHE, TWEM_MEMCACHE"
  printf "set ${KEY} 0 ${MEMCACHE_EXPIRE} ${#RAND}\r\n${RAND}\r\n" | nc ${HOST} ${TWEM_MEMCACHE}
  printf "get ${KEY}\r\n" | nc ${HOST} ${MAIN_MEMCACHE}
  printf "get ${KEY}\r\n" | nc ${HOST} ${TWEM_MEMCACHE}
}

twemproxy_cluster_test
#redis
#memcache
