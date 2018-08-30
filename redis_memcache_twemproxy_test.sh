#set -x

# requires redis-cli to be installed 

if [ -z "$1" ]; then
   echo "No host sent"
   exit 1
fi

HOST=$1

MAIN_REDIS=6379
MAIN_MEMCACHE=11211

TWEM_REDIS=22121
TWEM_MEMCACHE=22122

generate_rand_string() {
  len=20
  RAND=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${len} | head -n 1`
}

redis() {
  generate_rand_string
  echo -e "\nREDIS HOST ${HOST} TEST 1: write ${RAND} to MAIN_REDIS read from MAIN_REDIS, TWEM_REDIS"
  printf "set foo '${RAND}'" | redis-cli -h ${HOST} -p ${MAIN_REDIS}
  printf "get foo" | redis-cli -h ${HOST} -p ${MAIN_REDIS} # from MAIN_REDIS
  printf "get foo" | redis-cli -h ${HOST} -p ${TWEM_REDIS} # from TWEM_REDIS

  generate_rand_string
  echo -e "\nREDIS HOST ${HOST} TEST 2: write ${RAND} to TWEM_REDIS read from MAIN_REDIS, TWEM_REDIS"
  printf "set foo '${RAND}'" | redis-cli -h ${HOST} -p ${TWEM_REDIS}
  printf "get foo" | redis-cli -h ${HOST} -p ${MAIN_REDIS} # from MAIN_REDIS
  printf "get foo" | redis-cli -h ${HOST} -p ${TWEM_REDIS} # from TWEM_REDIS
}

memcache() {
  generate_rand_string
  echo -e "\nMEMCACHE HOST ${HOST} TEST 1: write ${RAND} to MAIN_MEMCACHE read from MAIN_MEMCACHE, TWEM_MEMCACHE"
  printf "set foo 0 60 ${#RAND}\r\n${RAND}\r\n" | nc ${HOST} ${MAIN_MEMCACHE}
  printf "get foo\r\n" | nc ${HOST} ${MAIN_MEMCACHE}
  printf "get foo\r\n" | nc ${HOST} ${TWEM_MEMCACHE}


  generate_rand_string
  echo -e "\nMEMCACHE HOST ${HOST} TEST 2: write ${RAND} to TWEM_MEMCACHE read from MAIN_MEMCACHE, TWEM_MEMCACHE"
  printf "set foo 0 60 ${#RAND}\r\n${RAND}\r\n" | nc ${HOST} ${TWEM_MEMCACHE}
  printf "get foo\r\n" | nc ${HOST} ${MAIN_MEMCACHE}
  printf "get foo\r\n" | nc ${HOST} ${TWEM_MEMCACHE}
}

redis
memcache
