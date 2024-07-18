#!/bin/bash

usage() {
    echo "Usage: $0 [--minikube]"
    exit 1
}

MINIKUBE=false
if [ "$#" -eq 1 ]; then
    if [ "$1" == "--minikube" ]; then
        MINIKUBE=true
    else
        usage
    fi
elif [ "$#" -gt 1 ]; then
    usage
fi

cleanup_minikube() {
    read -p "Do you want to clean up the current Minikube clusters? (yes/no): " choice
    case "$choice" in 
        yes|Yes|y|Y )
            echo "Stopping and deleting Minikube cluster..."
            minikube stop
            minikube delete
            ;;
        * )
            echo "Proceeding without cleaning up Minikube cluster..."
            ;;
    esac
}

NAMESPACE="niakimychev-msd-homework"
CHART_NAME="btc-price-microservice"
CHART_VERSION="0.1.0"
CHART_PATH="./charts"
PACKAGED_CHART="$CHART_PATH/$CHART_NAME-$CHART_VERSION.tgz"

if [ ! -f "$PACKAGED_CHART" ]; then
    echo "Packaging the Helm chart..."
    helm package "$CHART_PATH" --destination "$CHART_PATH"
    if [ $? -ne 0 ]; then
        echo "Helm chart packaging failed"
        exit 1
    fi
fi

if $MINIKUBE; then
    echo "Setting up for Minikube environment"
    cleanup_minikube

    minikube start
else
    echo "Setting up for Cloud environment"
fi

kubectl create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists"

helm repo update

helm upgrade --install "$CHART_NAME" "$PACKAGED_CHART" --namespace $NAMESPACE --create-namespace

if [ $? -eq 0 ]; then
    echo "Deployment successful"
    kubectl get pods -n $NAMESPACE
    kubectl get services -n $NAMESPACE

    echo "Waiting for the pod to be in Running state..."
    while [[ $(kubectl get pods -n $NAMESPACE -l app=btc-price-microservice -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
        echo "Pod is not yet in Running state. Waiting for 10 seconds..."
        sleep 10
    done

    if $MINIKUBE; then
        echo "Setting up port forwarding for Minikube environment"
        kubectl port-forward service/btc-price-microservice-service 5000:5000 -n $NAMESPACE &
        echo "Port forwarding set up. You can access the service at http://localhost:5000"
    else
        echo "Please set up your cloud environment to access the service"
    fi
else
    echo "Deployment failed"
    exit 1
fi
