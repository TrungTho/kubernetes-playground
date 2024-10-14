#! /bin/bash

set -xe

# Install and wait until helm successfully deployed
helm install --atomic --debug -n universal-helm \
    --create-namespace test-universal-helm ../charts/universal-chart \
    --set hpa.minReplicas=2;

# Switch working namespace 
kubectl config set-context --current --namespace=universal-helm;

# Wait 30s for pods to come up
sleep 30;

kubectl get deploy,pod,sa,svc,ep,hpa;

# Get pod name
podName=$(kubectl get pod -oyaml | yq ".items[0].metadata.name");

# Exec curl inside pod container
kubectl exec $podName -- curl localhost:8080;

# Get container status
containerStatus1=$(kubectl get pod -oyaml | yq ".items[0].status.containerStatuses[0].ready");
echo "container 1 status: " $containerStatus1;

containerStatus2=$(kubectl get pod -oyaml | yq ".items[1].status.containerStatuses[0].ready");
echo "container 2 status: " $containerStatus;

# Get SA name
saName=$(kubectl get pod -oyaml | yq ".items[0].spec.serviceAccountName");
echo "mounted service account: " $saName;

# Check statuses
if [ $containerStatus1 != true ]; then echo "Container 1 is not healthy" && exit 1; fi;
if [ $containerStatus2 != true ]; then echo "Container 2 is not healthy" && exit 1; fi;

if [ $saName = "default" ]; then echo "Service account is incorrect" exit 1; fi;

echo "Helm deployment tested succesfully!!!";