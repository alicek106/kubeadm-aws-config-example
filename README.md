# kubeadm Configuration for AWS

## 0. Provision Infrastructure (Optional)

```
$ cd terraform && terraform init
$ terraform apply
```

## 1. Master Configuration

In extraArgs, **cloud-provider: aws** shoud exists for (1) controller, (2) API server and (3) kubelet.

```
controllerManager:
  extraArgs:
    cloud-provider: aws
```

```
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: aws
```

```
apiServer:
  extraArgs:
    authorization-mode: Node,RBAC
    cloud-provider: aws
```

apiEndpoint should be same to master (corresponding to --apiserver-advertise-address of kubeadm init)

```
apiEndpoints:
  ip-10-43-0-20.ap-northeast-2.compute.internal: # Private DNS of Master Instance
    advertiseAddress: 10.43.0.20 # Join Advertise Address
```



## 2. Worker Configuration

token, caCertHashed should match to join secrets. Also, apiServerEndpoint shoud be set to API Server.

```
discovery:
  bootstrapToken:
    token: <DETACTED>
    apiServerEndpoint: "10.43.0.20:6443" # API Server endpoint of master. It can be LB Public DNS
    caCertHashes:
      - "<DETACTED>"
nodeRegistration:
  name: ip-10-43-0-31.ap-northeast-2.compute.internal # Private DNS name of each AWS Worker instances.
  kubeletExtraArgs:
    cloud-provider: aws
```

Of cource, **cloud-provider: aws** exists in kubeletExtraArgs

## 3. Initiate Cluster
In master,
```
kubeadm init --config master-config.yaml
```
In worker,
```
kubeadm init --config node-config.yaml
```
