#!/bin/bash

#
# Upgrades a package. Assumes that Sui is running.
#

env=$(cat .env)
if [ -n "${env}" ]; then
    export $(echo "${env}" | xargs)
fi

budget="30000"
if [ -z "${GAS}" ]; then
    sui client upgrade \
        --upgrade-capability "${UPGRADE_CAP_TESTNET}" \
        --gas-budget "${budget}" .
else
    sui client upgrade \
        --upgrade-capability "${UPGRADE_CAP_TESTNET}" \
        --gas "${GAS}" \
        --gas-budget "${budget}" .
fi