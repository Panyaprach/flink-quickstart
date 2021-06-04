#!/bin/bash
kubectl delete -f flink-configuration-configmap.yaml

kubectl delete -f jobmanager-service.yaml

kubectl delete -f jobmanager-rest-service.yaml

kubectl delete -f jobmanager-session-deployment-non-ha.yaml

kubectl delete -f taskmanager-session-deployment.yaml

kubectl delete -f taskmanager-service.yaml

kubectl delete ns flink