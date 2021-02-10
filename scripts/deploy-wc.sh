#!/bin/bash

set -euo pipefail

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
# shellcheck disable=SC1090 # Can't follow non-constant source.
source "${SCRIPTS_PATH}/../bin/common.bash"

: "${config[config_file_wc]:?Missing config}"
: "${secrets[secrets_file]:?Missing secrets}"

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${1:-""}

echo "Creating Elasticsearch and fluentd secrets" >&2
elasticsearch_password=$(pwgen 12 1)

kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${elasticsearch_password}" --dry-run -o yaml | kubectl apply -f -
kubectl -n fluentd create secret generic elasticsearch \
    --from-literal=password="${elasticsearch_password}" --dry-run -o yaml | kubectl apply -f -

echo "Installing helm charts" >&2
cd "${SCRIPTS_PATH}/../helmfile"
declare -a helmfile_opt_flags
[[ -n "$INTERACTIVE" ]] && helmfile_opt_flags+=("$INTERACTIVE")
helmfile -f . -e workload_cluster "${helmfile_opt_flags[@]}" apply --suppress-diff

# Add example resources.
# We use `create` here instead of `apply` to avoid overwriting any changes the
# user may have done.
kubectl create -f "${SCRIPTS_PATH}/../manifests/examples/fluentd/fluentd-extra-config.yaml" \
    2> /dev/null || echo "fluentd-extra-config configmap already in place. Ignoring."
kubectl create -f "${SCRIPTS_PATH}/../manifests/examples/fluentd/fluentd-extra-plugins.yaml" \
    2> /dev/null || echo "fluentd-extra-plugins configmap already in place. Ignoring." >&2

echo "Deploy wc completed!" >&2
