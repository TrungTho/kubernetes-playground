# Kubernetes playground

Declarative approach for all experimental exploration of me while learning and working with Kubernetes

## argocd-app-of-apps

Backbone of this repository, where I declare all the manifests in the format of ArgoCD "app of apps" pattern and let ArgoCD help to deploy all the resources

### app-links

Entrypoint for all application, including ArgoCD operator

### argocd-configs

All the customized configuration for cluster and argocd specifically
For example we want to patch, amend a resource, just put them here and argo will pick that up

### workloads

Manifests of testing applications, each sub-directory here should have 1 registration record in the [app-links](#app-links) sub-directory above.

## universal-helm

Helm template with the idea of build once, reuse every where 😀, which will be used as a dependency chart to reduce duplication and centralize management & maintenance to one source of truth
