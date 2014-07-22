set -o nounset

if (( ${BASH_VERSINFO[0]} != 4 ))
then
  errexit 'bash version 4 is required.'
fi

declare -i debug=0

# declare -ar nodes=(8098 8099 8100)
# NB: devrel
declare -ar nodes=(10018 10028 10038)
declare -i num_procs=4 # 24
declare -i sleep_seconds=120 # NB: not less than 5 seconds to ensure delete_mode seconds exceeded.
declare -i object_count=1000 # 2500

function now
{
  date '+%Y-%m-%d %H:%M:%S'
}

function pdebug
{
  if (( debug > 0 ))
  then
    echo "$(now):[debug]:$@"
  fi
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
  local -i curl_exit=0

  curl_output=$(curl --silent --output /dev/null --write-out "%{http_code}" "$@")
  curl_exit=$?
  while [[ $curl_output != 20[0-9] ]] && (( retry_count < 5 ))
  do
    # if [[ $curl_output == '000' || $curl_output == '300' ]] || (( curl_exit != 0 ))
    if [[ $curl_output == 30[0-9] || $curl_output == 40[0-9] ]]
    then
      break
    else
      pwarn "$id:$@:$curl_output:$curl_exit"
      sleep 1
      curl_output=$(curl --silent --output /dev/null --write-out "%{http_code}" "$@")
      curl_exit=$?
      (( ++retry_count ))
    fi
  done

  if [[ $curl_output != 20[0-9] ]] || (( curl_exit != 0 ))
  then
    perr "$id:$@:$curl_output:$curl_exit"
    return 1
  fi
  return 0
}

function object_deleter_no_retry
{
  local -i deleter_id=$1
  pinfo "starting deleter with id: $deleter_id"

  local -i j=0
  for ((j=0; j < object_count; ++j))
  do
    local host="$(curl_host)"
    # PW: curl --silent --output /dev/null -XDELETE "$host/buckets/bucket-$deleter_id/keys/$j?pw=3"
    # NO PW: curl --silent --output /dev/null -XDELETE "$host/buckets/bucket-$deleter_id/keys/$j"
    curl --silent --output /dev/null -XDELETE "$host/buckets/bucket-$deleter_id/keys/$j"
  done

  pinfo "done - deleter with id: $deleter_id"
}

function nuke_all_objects
{
  declare -i i=0
  for ((i=0; i < num_procs; ++i))
  do
    object_deleter_no_retry $i &
  done

  wait
  pinfo 'nuke done'
}

