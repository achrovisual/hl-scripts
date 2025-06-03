<div align="center">
  <h1>K3s</h1>
</div>


## K3s Installation
Below are the commands to install K3s. You can read more in the [official documentation](https://docs.k3s.io/quick-start).

### Master Node
For master nodes, install K3s in server mode.
```console
$ curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --cluster-init \
    --tls-san=<FIXED_IP> # Optional, needed if using a fixed registration address
```

### Worker Node
For worker nodes, install K3s in agent mode.
```console
$ curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - agent --server https://<ip or hostname of server>:6443
```

## Setup Scripts

### k3s/server/setup.sh
This sets up Argo CD, MetalLB, and OpenTelemetry Collector. To get the login password for Argo CD, run the command below.
```console
$ sudo kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```