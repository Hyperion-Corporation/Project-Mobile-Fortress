# k8s/

> **Optional.** Only relevant if you deploy the optional leaderboards/cloud-save
> backend (`infra/global/docker/`) to a Kubernetes cluster. A purely offline game
> needs none of this.

Kustomize-based Kubernetes manifests: a `base/` layer plus per-environment
`overlays/`.

```bash
kubectl apply -k infra/global/k8s/overlays/dev
kubectl apply -k infra/global/k8s/overlays/prod
```

| Directory | Purpose |
| --- | --- |
| `base/` | Environment-agnostic Deployment/Service/ConfigMap/Ingress for the backend API |
| `overlays/dev/` | Dev patches: single replica, dev host |
| `overlays/prod/` | Prod patches: replica count, resource limits, prod host |

> **TODO:** Point the `image:` field in `base/deployment.yaml` at your real
> container registry once the backend exists (see `infra/global/docker/`). The Helm
> chart in `infra/global/helm/` packages the same resources for teams that prefer
> `helm install` over `kubectl apply -k`.
