# helm/

> **Optional.** Only relevant for the optional leaderboards/cloud-save backend.
> Packages (mostly) the same resources as `infra/k8s/base/`, for teams that
> prefer `helm install` over `kubectl apply -k`. Pick one, don't run both
> against the same cluster/namespace.

```bash
helm lint infra/helm/mobile-fortress
helm install mobile-fortress infra/helm/mobile-fortress -f infra/helm/mobile-fortress/values.yaml
```
