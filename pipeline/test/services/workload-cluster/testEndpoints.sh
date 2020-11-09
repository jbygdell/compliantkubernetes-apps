#!/bin/bash

INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC1090 # Can't follow non-constant source
source "${INNER_SCRIPTS_PATH}/../funcs.sh"

echo
echo
echo "Testing endpoints"
echo "=================="

base_domain=$(yq r -e "${CONFIG_FILE}" 'global.baseDomain')
enable_ck8sdash=$(yq r -e "${CONFIG_FILE}" 'ck8sdash.enabled')
enable_user_alertmanager_ingress=$(yq r -e "${CONFIG_FILE}" 'user.alertmanager.ingress.enabled')
enable_user_alertmanager=$(yq r -e "${CONFIG_FILE}" 'user.alertmanager.enabled')

testEndpoint Prometheus-wc "https://prometheus.${base_domain}/"
if [[ "${enable_user_alertmanager_ingress}" == "true" && "${enable_user_alertmanager}" == "true" ]]
then
    testEndpoint Alertmanager-user "https://alertmanager.${base_domain}/"
fi

if [ "$enable_ck8sdash" = "true" ]; then
    testEndpoint ck8sdash "https://ck8sdash.${base_domain}/"
fi

echo
echo
echo "Testing endpoints protection"
echo "============================="

testEndpointProtected Prometheus-wc "https://prometheus.${base_domain}/" 401
if [[ "${enable_user_alertmanager_ingress}" == "true" && "${enable_user_alertmanager}" == "true" ]]
then
    testEndpointProtected Alertmanager-user "https://alertmanager.${base_domain}/" 401
fi