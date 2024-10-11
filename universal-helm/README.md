# todo Universal Helm Chart

- [todo Universal Helm Chart](#todo-universal-helm-chart)
  - [Overview](#overview)
  - [Usage](#usage)
    - [Chart.yaml example](#chartyaml-example)
    - [values.yaml examples](#valuesyaml-examples)
  - [Components](#components)
    - [1. General information](#1-general-information)
    - [2. Deployment](#2-deployment)
    - [3. HPA](#3-hpa)
    - [4. Service](#4-service)
    - [5. Azure](#5-azure)
    - [6. Service account](#6-service-account)
    - [7. Secret provider class](#7-secret-provider-class)
  - [How to contribute](#how-to-contribute)
  - [FAQ](#faq)

## Overview

Glossary:

- **Helm**: is a package manager for Kubernetes that includes all the necessary code and resources needed to deploy an application to a cluster.
- **Cluster**: in our context, it's a multi-tenant AKS cluster.
- **Universal Helm**: a reusable Helm chart, that you can install any application without preparing your Kubernetes yaml manifest from scratch. Some Enterprise case studies can be found at:
  - [Why Nixys use Universal chart](https://medium.com/@nixys_io/nxs-universal-chart-lots-of-knowledge-one-helm-chart-875001373d66)
  - [DevOps Nirvana team Universal chart](https://github.com/DevOps-Nirvana/Universal-Kubernetes-Helm-Charts)

This is the centralized, universal chart repository which incrementally implements best practices to deploy workloads in AKS cluster.

It's suitable for your team if:

- You want to deploy workload into AKS cluster
- You already have container images for your application (Spring, Python, NodeJS,...)
- You want to follow AKS best practice without spending too much time on plain k8s manifest preparation.

It **may not be suitable** for your team if:

- You won't deploy your workload into AKS/k8s cluster (you use ACA/App Function/etc...)
- You already have predefined helm charts (from vendor/COTS/...)

## Usage

This helm chart will be used as a [dependency chart](https://helm.sh/docs/helm/helm_dependency/). Therefore, app team can leverage all the pre-built template yamls of this repository without spending too much time for building them from scratch.

In order to use it, you need to prepare some files. A sample directory structure will be:

```
your-dir
├─── Chart.yaml  <----- important
├─── values.yaml <----- important
├─── Chart.lock  <----- auto-generated
└─── charts      <----- auto-generated
     └── universal-chart-<version>.tgz
```

As a consumer of this universal helm chart, you only need to specify 2 files:

- ${\textsf{\color{red}Chart.yaml}}$: Metadata of your chart.
- ${\textsf{\color{red}values.yaml}}$: Override values to be used.

### Chart.yaml example

You can make a copy of this example and change fields that are marked as `mutable`.

```yaml
apiVersion: v2
name: test-a-chart # mutable
description: A Helm chart for team A # mutable
type: application
version: 0.0.0 # mutable

dependencies:
  - name: universal-chart
    version: 1.1.1 # mutable
    repository: oci://todo
```

### values.yaml examples

After providing necessary fields for ${\textsf{\color{red}Chart.yaml}}$, you can specify the values to use in ${\textsf{\color{red}values.yaml}}$. Below are 3 file examples for you to consider.

> [!CAUTION]
> If you don't provide a ${\textsf{\color{red}values.yaml}}$ file, the default file of this universal helm will be used [here](todo). All the fields will be explained in this [Components section](#components)

1. Simple usage with image name only

```yaml
universal-chart: # important
  applicationName: ultimate-app
  buName: bu1
  teamName: team-a
  namespace: team-a

  deployment:
    image:
      name: nginx
      tag: "1.16"
```

2. Adjust hpa scale up condition

```yaml
universal-chart: # important
  applicationName: ultimate-app
  buName: bu1
  teamName: team-a
  namespace: team-a

  deployment:
    image:
      name: nginx
      tag: "1.16"

  hpa:
    enabled: true
    minReplicas: 2 # there will always be 2 running pod
    maxReplicas: 50 # max number of pods can run is 50
    targetCPUUtilizationPercentage: 50 # scale up when any pod uses more than 50% of the requested CPU resource
    targetMemoryUtilizationPercentage: 50 # scale up when any pod uses more than 50% of the requested Memory resource
```

3. KV integration

```yaml
universal-chart: # important
  applicationName: ultimate-app
  buName: bu1
  teamName: team-a
  namespace: team-a

  deployment:
    image:
      name: nginx
      tag: "1.16"

  azure:
    workloadIdentity:
      userAssignedClientId: abc123 # Client ID of the user-managed identity, which has kv-reader role
    keyvaultIntegration:
      enabled: true
      kvName: kv-abc # keyvault name
      cloudName: "" # Optional, leave it empty to use the default value
      tenantId: tenant-124 # tenant id in which keyvault was provisioned
      object:
        array:
          - |
            objectName: secret1             # Set to the name of your secret
            objectType: secret              # object types: secret, key, or cert
            objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
          - |
            objectName: key1                # Set to the name of your key
            objectType: key
            objectVersion: ""
```

- After helm is successfully deployed, `secret1` and `key1` will be retrieved to folder /mnt/secrets-store ([explaination](#8-how-can-i-use-a-secret-from-keyvault-for-my-workload))
- Detailed keyvault integration mechanism and implementation can be found [here](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver). All the necessary components were installed in the cluster. You only need to provide the array of keys/secrets to be retrieved as the above example.

## Components

This section will explain in detail every value you can modify, their meanings, which are required and optional.

### 1. General information

- `applicationName` (required, string): identifier name of the workload.
- `buName` (required, string): Business unit identifier.
- `teamName` (required, string): team identifier.
- `namespace` (required, string): the exact namespace when the workload will be deployed.

### 2. Deployment

- `deployment.replicaCount` (optional, int): fixed number of replicas. Only applied if `hpa.enabled` = `false`. **If HPA is enabled, this value will be ignored.**

- `deployment.image`

  - `deployment.image.name` (required, string): full URL to the container image (registry path included).
  - `deployment.image.tag` (optional, string): tag of container image. Default is `latest`.

- `deployment.podAnnotations` (optional, object): optional annotation for pods. Default is `{}`.

- `deployment.livenessProbe` (optional, object): optional liveness probe check for the container. Default is `http://localhost:8080/`. The comprehensive guidance can be found at [k8s official doc](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).
- `deployment.readinessProbe` (optional, object): optional readiness probe check for container. Default is `{}`, which is disabled. The comprehensive guidance can be found at [k8s official doc](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).

- `deployment.resources` (required, object): [pod's resources request and limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).
  - `deployment.resources.requests` (required) Request of resources. AKS will use this information to find an appropriate node for pod.
    - `deployment.resources.requests.cpu` (required, float) (Min: 0.001, Max: number of cores) - number of cores that pod will be guaranteed to have. [Detail explanation](https://www.datadoghq.com/blog/kubernetes-cpu-requests-limits/)
    - `deployment.resources.requests.memory` (required, int) (Min: 1, Max: size of RAM) - number of ram that pod will be guaranteed to have. [Detail explanation](https://www.datadoghq.com/blog/kubernetes-cpu-requests-limits/)
  - `deployment.resources.limits` (required) Limit of resources. If the pod exceeds its limit, performance will be affected.
    - `deployment.resources.limits.cpu` (required, float) If the pod exceeds this value, CPU usage will be throttled.
    - `deployment.resources.limits.memory` (required, float) If the pod exceeds this value, **Pod will be killed with OOM signal**.

### 3. HPA

[Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/). It will monitor resource usage of pods and scale up/down based on metrics. In this universal helm, HPA is already integrated to monitor the above [Deployment](#2-deployment), in order to use it you only need to enable it by using the following values.

- `hpa.enabled` (required, bool): enabled or not. If it is enabled, `deployment.replicaCount` won't be used.

- `hpa.minReplicas` (required, int): minimum number of pods will be run (always guaranteed)
- `hpa.maxReplicas` (required, int): maximum number of pods can be scaled up (limit)

- `hpa.targetCPUUtilizationPercentage` (required, int): target CPU for pod scale-up. For example, `50` means, if the metric server finds any pod has `CPU usage / its CPU request >= 0.5 (50%)`, a new pod of the same deployment will be created to share the load and decrease the average CPU usage.
- `hpa.targetMemoryUtilizationPercentage` (required, int): target memory to
  pod scale-up. Same concept as the above value, but applied to memory usage.

### 4. Service

[Service to expose deployment/pod/...](https://kubernetes.io/docs/concepts/services-networking/service/). In this universal helm, we restrict to use only the ClusterIP service type. This service is ready integrated with the above [Deployment](#2-deployment), to use it you only need to provide the following values:

- `service.port` (required, int): port of service (which will listen for incoming traffic)
- `service.targetPort` (required, int): port of container

![ClusterIP-Service](https://learn.microsoft.com/vi-vn/azure/aks/media/concepts-network/aks-clusterip.png)

### 5. Azure

All related Azure resources integration (Keyvault, Workload Identity,...). In this universal helm, we already integrated with Keyvault, Workload Identity, in order to use it, you need to enable the Azure component and provide the following values:

- `azure.workloadIdentity.userAssignedClientId` (optional, string): Client ID of the User-managed Identity. [Detail implementation](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access). [Deployment](#2-deployment) will use this workload identity to connect with Azure resources without needing further authentication steps.

- `azure.keyvaultIntegration` Integration with Keyvault to retrieve secrets/objects/... [Detail implementation](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver).
  - `azure.keyvaultIntegration.enabled` (required, bool): enable Keyvault integration or not.
  - `azure.keyvaultIntegration.kvName` (optional, string): name of Azure Keyvault. Can only be used with `enabled=true`.
  - `azure.keyvaultIntegration.cloudName` (optional, string): name of cloud. Can only be used with `enabled=true`.
  - `azure.keyvaultIntegration.tenantId` (optional, string): tenant id where Keyvault is provisioned. Can only be used with `enabled=true`.
  - `azure.keyvaultIntegration.object.array` (optional, array): All secrets/objects need to be retrieved from Keyvault.

### 6. Service account

Each team will have a dedicated Service Account and will be automatically bound with an [Azure Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview?tabs=dotnet#service-account-annotations). In this universal helm, that binding implementation is already finished and enabled. If you want to have additional annotations for the service account, you can provide value for:

- `serviceAccount.annotations` (optional, object): optional [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) for the service account.

### 7. Secret provider class

A customer resource definition that is needed for [Keyvault integration](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver). We already implemented it in this universal helm and will be enabled with the above [Azure Keyvault Integration](#5-azure). You won't need to provide any specific values for it.
![SecretProviderClass](https://secrets-store-csi-driver.sigs.k8s.io/images/diagram.png)

## How to contribute

1. Prerequisites:
   - [Helm CLI](https://helm.sh/docs/intro/install/)
   - [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
2. **Step 1**: Clone this repository.
3. **Step 2**: Checkout a new feature branch (we follow trunk-based git-flow so all changes need to be included in a PR before merging to main).
4. **Step 3**: Update templates, values, helpers,... as you want.
5. **Step 4**: Frequently verify syntax with `helm lint charts/universal-chart` and `helm template charts/universal-chart`.
6. **Step 5**: Update file `test/test-helm-deployment.sh` with appropriate tests which reflect your new changes.
7. **Step 6**: Update the version in file `Chart.yaml` with an appropriate value. Please check [the official semver documentation](https://github.com/semver/semver/blob/master/semver.md) for more details.
8. **Step 7**: Create PR and request for review. The PR should pass CI linting and testing, it also **MUST** have screenshots of result deployment (you can find a test cluster and deploy your helm there).
9. **Step 8**: After the PR gets approved and merged, your changes will be packaged and released as a new version (which you updated in **`step 6`**).

## FAQ

### 1. How to pull this universal helm chart package to local machine? <!-- omit in toc -->

- Prerequisites
  - Helm CLI
  - Github PAT with read package permission
- Step 1: GHCR login by using
  ```bash
  helm registry login todo --username <your username> --password <your PAT>
  ```
- Step 2: Pull and install the chart by using
  ```bash
  helm install oci://todo/test/universal-chart --version <chart version>
  ```

### 2. How to use package as dependency (in local machine)<!-- omit in toc -->

- Prerequisites
  - Helm CLI
  - Github PAT with read package permission
- Step 1: Define `Chart.yaml` and `values.yaml` by following [this instruction](#usage)
- Step 2: GHCR login by using
  ```bash
  helm registry login todo --username <your username> --password <your PAT>
  ```
- Step 3: Update dependency by using

  ```bash
  helm dependency update
  ```

- Step 4: After running the previous command successfully, the ${\textsf{\color{red}Chart.lock}}$ and ${\textsf{\color{red}chart}}$ directory will be updated with the appropriate contents. You can now run this command to install the helm chart with your customized values (in ${\textsf{\color{red}values.yaml}}$ file)

  ```bash
  helm install <your_deployment_name> .
  ```

### 3. Failed to install because some namespace error <!-- omit in toc -->

- If you face some issues related to namespace (not found, existing,...) you may want to:
- Check if the `namespace` value in your ${\textsf{\color{red}values.yaml}}$ file already exists on the cluster.
- If the namespace you want to deploy doesn't exist. You can run this command to both create namespace & deploy helm to that namespace:

  ```bash
  helm install <your_deployment_name> . -n <your_desired_namespace> --create-namespace
  ```

### 4. Failed CI - Testing <!-- omit in toc -->

- After you modify the template, make sure you update the corresponding test cases in the file ${\textsf{\color{red}test/test-helm-deployment.sh}}$ in order to reflect the correct expected behaviors.
- When we install helm inside KinD in the Github Runner machine, we don’t have a connection to todo Azure Infrastructure, so **it will reasonable to disable Azure component to make the test pass** (for example set `azure.keyvaultIntegration.enabled` to `false`).
- If you update anything related to Azure resources integration. Please try to deploy a test version into a dev cluster to verify it can work seamlessly without breaking other components. And take a screenshot of the successful deployment to include in the PR as a POC.

### 5. How can I use container images which are stored in a private container registry? <!-- omit in toc -->

- We have integrated in this universal helm an ${\textsf{\color{red}imagePullSecret}}$ secret, which can pull images from the centralized private ghcr of todo. Therefore, you just need to provide the URL of the container image and it can be pulled to cluster's pod.
- If you need to pull the container image from another private container registry.
  - Option 1: You should consider moving your container images to the centralized ghcr, which we are using for centralized management.
  - Option 2: Contact us for more specific assistance.

### 6. I am facing an `ErrPullImage` when trying to deploy a pod <!-- omit in toc -->

- You **can't** pull images from public docker registry.
- You **can** pull image from mcr registry.
- If you pull an image from an internal private ghcr, please check the URL to see if it's correct.
- Check [question 5](#5-how-can-i-use-container-images-which-are-stored-in-a-private-container-registry) to see if you are pulling the image from the centralized ghcr.

### 7. I can’t find a suitable component to use in this universal helm <!-- omit in toc -->

- You can check [Contribution](#how-to-contribute) section to make your changes.
- If you are not confident in making a change, **please contact this repository's maintainer team**, we will help to make the changes and release a new version for your use case.

### 8. How can I use a secret from keyvault for my workload? <!-- omit in toc -->

- If you want to use Keyvault's secrets in your application code, we recommend you to use [the corresponding SDK](https://learn.microsoft.com/en-us/azure/key-vault/general/developers-guide#apis-and-sdks-for-key-vault-management) to retrieve them.
- If you can't use the SDK, we have integrated in this universal helm a ${\textsf{\color{red} SecretProviderClass}}$ ([References](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)), you just need to fill all the necessary fields belong to Keyvault in this [Azure component section](#5-azure). And make sure the user-managed identity (todo placeholder to workload identity workflow).
- After filling all appropriate fields and your workload is successfully deployed into the cluster. All secrets/objects will be mounted inside the temporary `/mnt/secrets-store` directory as files.
