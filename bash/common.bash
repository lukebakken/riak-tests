set -o nounset

if (( ${BASH_VERSINFO[0]} != 4 ))
then
  errexit 'bash version 4 is required.'
fi

declare -ar nodes=(8098 8099 8100)
declare -i num_procs=1 # 24
declare -i sleep_seconds=1 # 15
declare -i object_count=10 # 2500

function now
{
  date '+%Y-%m-%d %H:%M:%S'
}

function pinfo
{
  echo "$(now):[info]:$@"
}

function perr
{
  echo "$(now):[error]:$@" 1>&2
}

function pwarn
{
  echo "$(now):[warning]:$@"
}

function curl_host
{
  local -i idx=$(( RANDOM % 3 ))
  local -i port=${nodes[$idx]}
  echo "localhost:$port"
}

function curl_exec
{
  local id="$1"
  shift

  local -i retry_count=0
  local host="$(curl_host)"
  curl_output=$(curl --silent --output /dev/null --write-out "%{http_code}" "$@")
  while [[ $curl_output != 20[0-9] ]] && (( retry_count < 5 ))
  do
    pwarn "$id:$@:$curl_output:$?"
    sleep 1
    curl_output=$(curl --silent --output /dev/null --write-out "%{http_code}" "$@")
    (( ++retry_count ))
  done
  if [[ $curl_output != 20[0-9] ]]
  then
    perr "$id:$@:$curl_output:$?"
  fi
}

