#!/bin/bash

# Cluster Pool
# Master Nodes: 172.16.4.201 - 172.16.4.203
# Worker Nodes: 172.16.4.204 - 172.16.4.205
# Load Balancers: 172.16.4.206 - 172.16.4.210

master_01=172.16.4.201
master_02=172.16.4.202
master_03=172.16.4.203

worker_01=172.16.4.204
worker_02=172.16.4.205

master_nodes={$master_02 $master_03}
worker_nodes={$worker_01 $worker_02}

curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server --cluster-init --disable=servicelb