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
sudo k3s kubectl apply -f k8s/system/sealed-secrets-app.yaml
sudo k3s kubectl apply -f k8s/application.yaml
## if Kubernetes Web-UI is needed:
sudo k3s kubectl apply -f k8s/system/k8s-web-ui-app.yaml
## login to Kubernetes Web-UI with:
k3s kubectl -n kube-system create token oke-admin && k3s kubectl proxy --address=0.0.0.0
```

If needed, remove apps with: `k3s kubectl delete application the-app-name -n argocd`


Sealed secrets will be installed in the cluster, grab the encrypt key with:

```bash
k3s kubectl -n kube-system get secret
# check the name of sealed-secrets-key in the previous command and replace it in the next one
k3s kubectl get secret -n kube-system sealed-secrets-key6jgf9 -o jsonpath="{.data['tls\.crt']}" | base64 -d > secrets/sealed-secrets-public.pem
```

You will need to install kubeseal locally

```bash
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.17.5/kubeseal-0.17.5-linux-amd64.tar.gz -O kubeseal.tar.gz
tar -xvzf kubeseal.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm kubeseal kubeseal.tar.gz LICENSE README.md
```

Seal the secrets with:

```bash
kubeseal --cert secrets/sealed-secrets-public.pem --format yaml < secrets/slack-webhook-secrets.yaml > k8s/apps/post-sync/sealed-secrets-slack-webhook.yaml
kubectl -n oreplay create secret generic secrets-main-app --dry-run=client --from-env-file="secrets/oreplay.env" --output json | kubeseal --cert secrets/sealed-secrets-public.pem --format yaml | tee k8s/apps/sealed-secrets-main-app.yaml
```

Read the secrets with 
```bash
k3s kubectl get secret slack-webhook -n oreplay -o jsonpath="{.data.SLACK_WEBHOOK_URL}" | base64 -d
```
