# helm/

> **Optional.** Only relevant for the optional leaderboards/cloud-save backend.
> Packages (mostly) the same resources as `infra/global/k8s/base/`, for teams that
> prefer `helm install` over `kubectl apply -k`. Pick one, don't run both
> against the same cluster/namespace.

```bash
helm lint infra/global/helm/mobile-fortress
helm install mobile-fortress infra/global/helm/mobile-fortress -f infra/global/helm/mobile-fortress/values.yaml
```
