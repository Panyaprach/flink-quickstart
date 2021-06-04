#!/bin/bash
kubectl create ns prometheus

kubectl create -f prometheus-rbac.yaml

kubectl create -f prometheus-configuration-configmap.yaml

kubectl create -f prometheus-service.yaml

kubectl create -f prometheus-server.yaml