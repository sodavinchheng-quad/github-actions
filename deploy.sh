#!/bin/bash
readonly NAME="$(basename "$0")"
readonly CURRENT_DIR="$(cd $(dirname "$0") && pwd)"

usage() {
  cat << __USAGE__
  Usage: ${NAME} <mode>
    Build and deploy the create-react-app artifact to GCS.

    => mode: local, development, production
    Note: ensure that .env.mode contain a variable name REACT_APP_GCS_BUCKET

  Options:
    -c: if the option specified, the script will ignore Cache-Control on gsutil
    -path: if mode = local, path is required
__USAGE__
}

# gsutil is not installed
if ! command -v gsutil &> /dev/null
then
  echo "gsutil is not installed"
  exit
fi

# --- parse arguments ---
[ "$#" -lt 1 ] && { usage; exit 1; }
[ "$1" == "${1#-}" ] && { MODE="$1"; shift; }
[[ -z "$MODE" ]] && { echo "ERROR: please specify a mode"; exit 1; }

set -o allexport
. $CURRENT_DIR/.env."$MODE"

# bucket name is not specified
bucket="$REACT_APP_GCS_BUCKET"
echo "$bucket"
[[ -z "$bucket" ]] && { echo "ERROR: bucket name not found. Please check .env file"; exit 1; }

FLAG_CACHE=0
LOCAL_PATH=""
while getopts p:c OPT
do
  case $OPT in
    c)
      FLAG_CACHE=1
      ;;
    p)
      LOCAL_PATH="$OPTARG"
      ;;
  esac
done

function _main() {
  yarn run build --mode "$MODE"

  # if local, deploy to local path
  if [[ "$MODE" == "local" ]]; then
    [[ -z "$LOCAL_PATH" ]] && { echo "ERROR: please specify a local path"; exit 1; }
    rsync -avE ./build/* "$LOCAL_PATH"
  else
    if [ "$FLAG_CACHE" -gt 0 ]; then
        echo "Uploading to GCS with cache enabled"
        gsutil cp -r ./build/* gs://"$bucket"
      else
        echo "Uploading to GCS with cache disabled"
        gsutil -h "Cache-Control:max-age=0, no-store" cp -r ./build/* gs://"$bucket"
      fi
  fi
}

set -Eeu
_main
exit 0