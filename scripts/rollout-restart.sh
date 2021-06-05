#!/bin/sh
namespace=$1
echo "Restarting Deployments in $namespace"
if [ -n namespace ]
then
    deploys=`kubectl get deployments -n $namespace | tail -n1 | cut -d ' ' -f 1`

    for deploy in $deploys; do
        kubectl rollout restart deployments/$deploy -n $namespace
    done
else
    echo 'usage: rollout-restart.sh $namespace'
fi