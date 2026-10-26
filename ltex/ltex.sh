#! /bin/bash

set -euo pipefail

[ -z "${CI+1}" ] || exit 0

ltex_dir=$(dirname "$0")
ltex_version=""
ltex_timeout=${LTEX_TIMEOUT:-300}
container_name="ltex-$$"
watchdog_pid=""

ltex_tag=$(cd "$ltex_dir"; tar -cf - ./ | md5sum  | cut -d' ' -f1)
ltex_version="ltex:$ltex_tag"

function build_image() {
  if docker buildx version &>/dev/null; then
    docker buildx build --load . -t "$ltex_version" -t 'ltex:latest'
  else
    docker build . -t "$ltex_version" -t 'ltex:latest'
  fi
}

if ! docker inspect "$ltex_version" &>/dev/null; then
  if ! (cd "$ltex_dir" && build_image > /dev/null); then
    echo "Failed to build the LTeX Docker image. Make sure Docker or Podman is running, then try again."
    exit 1
  fi
fi

files_to_clean=()
files_to_process=()

function cleanup() {
  if (( ${#files_to_clean[@]} )); then
    rm -f "${files_to_clean[@]}"
  fi

  if [ -n "$watchdog_pid" ]; then
    pkill -P "$watchdog_pid" &>/dev/null || true
    watchdog_pid=""
  fi
}

trap cleanup EXIT
trap 'exit 1' SIGHUP SIGINT SIGTERM

for file in "$@"; do
  new_file=${file/%.mdx/.md}

  if [ "$file" != "$new_file" ]; then
    cp "$file" "$new_file"
    files_to_process+=( "$new_file" )
    files_to_clean+=( "$new_file" )
  else
    files_to_process+=( "$file" )
  fi
done

( sleep "$ltex_timeout" && docker kill "$container_name" ) &>/dev/null &
watchdog_pid=$!

SECONDS=0
status=0
output=$(docker run --rm \
  --name "$container_name" \
  --user "$UID" \
  --volume "$(pwd):/src:rw,Z" \
  --workdir /src \
  "$ltex_version" "${files_to_process[@]}" 2>&1) || status=$?

cleanup

output=$(echo "$output" | sed -E 's|(app/javascript/documentation/.*?\.md):|\1x:|g')

case "$status" in
  0|3)
    output=$(echo "$output" | sed -E '/^[A-Z][a-z]{2} [0-9]{1,2}, [0-9]{4} .* org\.eclipse\.lsp4j\./,$d')
    [ -z "$output" ] || echo "$output"
    exit 0
    ;;
  125|126|127)
    echo "$output"
    echo "Docker could not run LTeX (exit code $status). Make sure Docker or Podman is running, then try again."
    exit 1
    ;;
  137)
    echo "$output"
    if (( SECONDS >= ltex_timeout )); then
      echo "LTeX was stopped after ${ltex_timeout}s without finishing. This usually means the Docker or Podman VM ran out of memory and killed the LTeX server."
    else
      echo "LTeX was killed, most likely because the Docker or Podman VM ran out of memory."
    fi
    echo "Give the VM more memory (with Podman: podman machine stop && podman machine set --memory 4096 && podman machine start), or raise LTEX_TIMEOUT for very large changes."
    exit 1
    ;;
  *)
    echo "$output"
    echo "LTeX failed (exit code $status), see the output above."
    exit 1
    ;;
esac
