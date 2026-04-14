# Harbor — Local container registry

Harbor runs in the Minikube cluster as the target of the GitOps pipeline: **build image -> push to Harbor -> ArgoCD picks up chart change -> pulls from Harbor -> deploys**.

## Why Harbor (vs. plain registry:2)

- Multi-tenant projects (can have `aduanext/server`, `aduanext/web`, `aduanext-cr/*`, etc. with separate permissions once the multi-hacienda platform ships)
- Built-in web UI for image catalog browsing + audit
- Same registry choice as the sibling repos (vertivolatam/monorepo, altrupets/monorepo) — consistent tooling across the org
- Vulnerability scanning via Trivy (disabled by default on minikube for RAM reasons; enable in production)

## Setup

Requires Minikube running (`make minikube-up` — VRTV-56).

```bash
# 1. Install Harbor (~3-5 min on first run; Harbor has many components)
make harbor-install

# 2. Get the admin password (default: Harbor12345 — change for anything beyond local dev)
make harbor-admin-password

# 3. Open the UI
make harbor-ui
# -> minikube service will print an http://192.168.x.x:30002 URL
```

## First-time configuration

1. Log in to the UI as `admin` / `Harbor12345`
2. Create a project named `aduanext` (public or private)
3. Note the URL — something like `http://192.168.49.2:30002`

## Pushing an image

The Makefile target `harbor-push-server` is a placeholder until the real Serverpod build pipeline lands. For now, a manual push looks like:

```bash
# Get the Harbor URL from minikube
HARBOR_URL=$(minikube -p aduanext service harbor -n harbor --url | head -1 | sed 's|http://||')

# Tag any image as an aduanext/<repo> image
docker tag nginx:alpine $HARBOR_URL/aduanext/test:v1

# Authenticate
docker login $HARBOR_URL -u admin -p Harbor12345

# Push
docker push $HARBOR_URL/aduanext/test:v1
```

## Wiring Helm to pull from Harbor

Once an image has been pushed:

1. Create an `imagePullSecret` in the `aduanext` namespace (see `imagepullsecret-template.yaml`)
2. In `infrastructure/helm-charts/aduanext/values.yaml`, set:
   ```yaml
   global:
     imagePullSecrets:
       - name: harbor-pull-secret
   server:
     enabled: true
     image:
       repository: <HARBOR_URL>/aduanext/server
       tag: dev
   ```
3. Push the values change to `main` — ArgoCD picks it up within ~3 minutes

## Troubleshooting

- **`x509: certificate signed by unknown authority` on `docker push`**: Harbor is configured HTTP-only (no TLS) locally. Add the registry to the `insecure-registries` list in Docker daemon config:
  ```json
  { "insecure-registries": ["192.168.49.2:30002"] }
  ```
  Restart Docker daemon.
- **`unauthorized` on `docker push`**: re-run `make harbor-login` to refresh the session.
- **Pods `ImagePullBackOff` after chart change**: check the `imagePullSecret` is in the right namespace and the secret's `docker-server` matches the actual Harbor URL (minikube NodePort can rotate if you re-create the cluster).

## Uninstall

```bash
make harbor-uninstall
kubectl delete pvc --all -n harbor  # frees disk
kubectl delete namespace harbor
```

## Production hardening

This Helm values file is a **local dev profile**. For production:

- Enable TLS (`expose.tls.enabled: true`) with a real cert (cert-manager + Let's Encrypt)
- Set `harborAdminPassword` via a sealed-secret, not plaintext
- Enable Trivy scanning + schedule nightly scans
- Point at external object storage (S3 / GCS) instead of `persistentVolumeClaim` for registry data
- Enforce `tag retention` rules
