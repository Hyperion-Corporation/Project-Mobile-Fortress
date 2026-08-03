# helm/

> **Optional.** Only relevant for the optional leaderboards/cloud-save backend.
> Packages (mostly) the same resources as `infra/k8s/base/`, for teams that
> prefer `helm install` over `kubectl apply -k`. Pick one, don't run both
> against the same cluster/namespace.

```bash
helm lint infra/helm/mobile-game-template
helm install mobile-game-template infra/helm/mobile-game-template -f infra/helm/mobile-game-template/values.yaml
```
