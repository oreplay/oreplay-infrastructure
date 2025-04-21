# oreplay-infrastructure

### Use Kubernetes

Install (if needed) Lightweight Kuberenetes with [K3s](https://docs.k3s.io/installation)

```bash
curl -sfL https://get.k3s.io | sh -
# Check for Ready node, takes ~30 seconds 
sudo k3s kubectl get node 
# /usr/local/bin/k3s-uninstall.sh
```

Note all kubectl commands can be run using `k3s` (as root) without need to special authentication or context change.

Install ArgoCD in k8s (remember to run `k3s` as root or run `kubectl` directly if not using `k3s`)

```bash
# install ArgoCD in k8s
k3s kubectl create namespace argocd
k3s kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# access ArgoCD UI
k3s kubectl get svc -n argocd
k3s kubectl port-forward svc/argocd-server 8080:443 -n argocd

# login with admin user and below token (as in documentation):
k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo

# you can change and delete init password
```

Finally, to configure the application from in ArgoCD for the cluster we need to run `kubectl apply`:

```bash
sudo k3s kubectl apply -f application.yaml
```

Sealed secrets will be installed in the cluster, grab the encrypt key with:

```bash
k3s kubectl -n kube-system get secret sealed-secrets-key -o yaml
k3s kubeseal --fetch-cert \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  > sealed-secrets-public.pem
```
