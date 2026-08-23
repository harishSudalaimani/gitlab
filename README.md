# Kubernetes Homelab GitOps

## Project operating procedure

This homelab is being rebuilt from a completely clean baseline as a production-style GitOps bootstrap.

### Current baseline

- Kubernetes is running.
- Cilium is installed and healthy.
- The Cilium Gateway API controller is enabled.
- `gateway/public-gateway` exists and is `Programmed=True`.
- Argo CD, GitLab, Longhorn, PostgreSQL, Valkey, MinIO, cert-manager, and Sealed Secrets are not yet installed.

### Architecture

- GitLab is the Git hosting platform.
- Argo CD is the GitOps controller.
- Git is the single source of truth for persistent infrastructure configuration.
- Cilium provides networking and Gateway API.
- Gateway API and `HTTPRoute` are used instead of Kubernetes Ingress.
- Cloudflare Tunnel/DNS provides external access where appropriate.
- cert-manager and Let’s Encrypt provide TLS.
- Sealed Secrets manages secrets committed to Git.
- Longhorn provides persistent storage.
- CloudNativePG provides PostgreSQL.
- Valkey provides Redis-compatible caching.
- MinIO provides S3-compatible object storage.
- GitLab is installed only after all dependencies are healthy.

### Installation order

1. Bootstrap Argo CD.
2. Move Argo CD management into GitOps.
3. Install Sealed Secrets.
4. Install cert-manager.
5. Configure Let’s Encrypt.
6. Install Longhorn.
7. Install CloudNativePG.
8. Install MinIO.
9. Install Valkey.
10. Install GitLab.
11. Configure GitLab as the homelab Git repository.
12. Make Argo CD continuously reconcile the repository.

### Rules

- Do not manually create permanent application resources unless explicitly required for bootstrap.
- Prefer Git/YAML and Argo CD.
- Never commit plaintext Kubernetes Secrets.
- Use Sealed Secrets for credentials that must be stored in Git.
- Do not delete or recreate healthy infrastructure unnecessarily.
- Verify the previous component is healthy before installing the next component.
- Use exact commands and exact YAML.
- Handle one component at a time and stop for verification after each component.
- Explain destructive operations before giving a command.
- Inspect the cluster before assuming resources exist.
- Prefer Gateway API/`HTTPRoute` over Ingress.
- Keep namespaces and ownership clean.
- Avoid duplicated controllers and unnecessary Helm dependencies.
- Use Argo CD automated sync, prune, and self-heal after GitOps ownership is established.

## Phase 1 — Argo CD bootstrap

Scope is intentionally limited to Argo CD. There is no PostgreSQL, Longhorn, GitLab, or committed secret in this phase.

### Preflight

Run these commands first and confirm that the selected context is the intended cluster:

```sh
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
kubectl get namespace argocd --ignore-not-found
kubectl get pods -A
kubectl get gateway -A
```

If `kubectl config current-context` fails or the API endpoint is `localhost:8080`, stop and configure `KUBECONFIG` or select the correct context. Do not run the installation command against an unknown cluster.

### Bootstrap command

The official Argo CD stable installation is used for bootstrap. It creates the `argocd` namespace and Argo CD's own installation resources; it does not create an application or commit any secret to Git.

```sh
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Verification

```sh
kubectl -n argocd wait --for=condition=Available deployment --all --timeout=10m
kubectl -n argocd get pods -o wide
kubectl -n argocd get deployments,statefulsets,services
kubectl get crd applications.argoproj.io appprojects.argoproj.io
```

For local access only, use a port-forward; do not expose Argo CD through Gateway API in this phase:

```sh
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

The generated initial admin credential is read locally when needed and must never be committed:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode; printf '\n'
```

After verification, stop. Phase 2 will move Argo CD management into GitOps; no other platform component should be installed before that review.
