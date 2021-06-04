#!/bin/bash
kubectl apply -f prometheus-rbac.yaml

kubectl apply -f prometheus-configuration-configmap.yaml

kubectl apply -f prometheus-service.yaml

kubectl apply -f prometheus-server.yaml

kubectl rollout restart deployment/prometheus-server -n prometheus