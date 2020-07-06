#!/usr/bin/env bash
set -x

_github_sha=$1

whitelist_dirs=(
    admin
    kube-system
    kube-public
    knode-system
    neuvector)

[ -z "$_github_sha" ] && echo "Error: github commit sha missing." && exit 1

_errors=""

for f in $(git diff-tree --no-commit-id --name-only -r $_github_sha)
do
  # check if whitelisted
  for wd in "${whitelist_dirs[@]}"
  do 
    echo "$f" | grep -E -q "k8s/(aat|prod)/(common|cluster-00|cluster-01)/${wd}"
    [ $? -eq 0 ] && continue 2
  done
  # check if automated
  fgrep -E -q '(flux\.weave\.works|fluxcd\.io)/automated: *"true"' "$f"
  [ $? -ne 0 ] && _errors="${_errors}${f}: automated must be set to true\n"
  # check if prod tag
  fgrep -E -q '(filter\.fluxcd\.io|flux\.weave\.works)/(tag\.)*(java|nodejs): glob:prod-\*' "$f"
  [ $? -ne 0 ] && _errors="${_errors}${f}: must use a prod-* tag\n"
done  

[ ! -z "$_errors" ] && echo "$_errors" > /dev/stderr && exit 2

exit 0