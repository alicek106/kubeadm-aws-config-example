# kubeadm Configuration for AWS

## 0. Provision Infrastructure (Optional)

```
$ cd terraform && terraform init
$ terraform apply
```
## Warning!

By default, kubeadm recognizes AWS internal address, so hostname should be same. 
Login to all each node, and execute below command to set hostname as AWS internal DNS.

```
root@ip-10-43-0-20:~# hostnamectl set-hostname $(curl http://169.254.169.254/latest/meta-data/local-hostname)
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    45  100    45    0     0   6049      0 --:--:-- --:--:-- --:--:--  6428

root@ip-10-43-0-20:~# hostname
ip-10-43-0-20.ap-northeast-2.compute.internal
```

## 1. Master Configuration
You can find fully described YAML file in below link.

> https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2

..or, you can manually print example YAML using below command.

> kubeadm config print init-default

Explanation for all YAML options can be found in below link.

> https://github.com/kubernetes/kubernetes/blob/master/cmd/kubeadm/app/apis/kubeadm/types.go

---

Anyway, let's see `--cloud-provider` option in YAML file.

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
You can find fully described YAML file in node-config.yaml.

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
kubeadm join --config node-config.yaml
```

## 4. Reload configuration for specific component
You can reload configuration of each component (or all). 

For example, you can update api-server's configuration using below command. master.yaml is configuration file.

```
$ kubeadm init phase control-plane apiserver --config master.yaml
```

For more description of this command, see 

```
$ kubeadm init phase --help
```

But, `kubeadm-config` configmap of `kube-system` namespace doesn't changed automatically. :D

### Reference
- https://blog.scottlowe.org/2019/02/18/kubernetes-kubeadm-and-the-aws-cloud-provider/
- https://github.com/kubernetes/cloud-provider-aws
- https://blog.heptio.com/setting-up-the-kubernetes-aws-cloud-provider-6f0349b512bd
- https://stackoverflow.com/questions/46810779/kubernetes-unable-to-register-node-with-cloud-provider-aws
