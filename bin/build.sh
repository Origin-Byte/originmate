#!/bin/bash

if [ "$1" = "remote" ]; then
    echo "Running script in remote setup"
    sui="./../sui"
else
    echo "Running script in local setup"
    sui="sui"
fi

${sui} move build