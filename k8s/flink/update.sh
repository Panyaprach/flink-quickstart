#!/bin/bash
kubectl apply -f flink-configuration-configmap.yaml

kubectl apply -f jobmanager-service.yaml

kubectl apply -f jobmanager-rest-service.yaml

kubectl apply -f jobmanager-session-deployment-non-ha.yaml

kubectl apply -f taskmanager-session-deployment.yaml

kubectl apply -f taskmanager-service.yaml

kubectl rollout restart deployment/flink-jobmanager -n flink
kubectl rollout restart deployment/flink-taskmanager -n flink