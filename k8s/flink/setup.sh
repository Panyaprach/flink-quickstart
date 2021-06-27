#!/bin/bash
kubectl create ns flink

kubectl create -f flink-configuration-configmap.yaml

kubectl create -f jobmanager-service.yaml

kubectl create -f jobmanager-rest-service.yaml

kubectl create -f jobmanager-session-deployment-ha.yaml

kubectl create -f taskmanager-session-deployment.yaml

kubectl create -f taskmanager-service.yaml