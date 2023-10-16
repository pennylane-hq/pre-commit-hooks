#! /bin/bash

set -euo pipefail

[ -z "${CI+1}" ] || exit 0

ltex_dir=$(dirname "$0")
ltex_version=""

ltex_tag=$(cd $ltex_dir; tar -cf - ./ | md5sum  | cut -d' ' -f1)
ltex_version="ltex:$ltex_tag"

(
  cd $ltex_dir
  docker inspect "$ltex_version" > /dev/null || docker build . -t "$ltex_version" -t 'ltex:latest'
)

files_to_clean=()
files_to_process=()

function cleanup() {
  if (( ${#files_to_clean[@]} )); then
    rm "${files_to_clean[@]}"
  fi
}

trap cleanup SIGHUP SIGINT SIGTERM

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

echo "${files_to_process[@]}" |
  xargs docker run --rm -i \
    --user "$UID" \
    --volume "$(pwd):/src:rw,Z" \
    --workdir /src \
    "$ltex_version" |
  sed -E 's|(app/javascript/documentation/.*?\.md):|\1x:|g' || true

cleanup

exit 0
