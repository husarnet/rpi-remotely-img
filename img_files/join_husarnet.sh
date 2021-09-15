#!/bin/bash

echo "joinging Husarnet as ${HUSARNET_HOSTNAME}:"
sudo husarnet join ${HUSARNET_JOINCODE} ${HUSARNET_HOSTNAME}