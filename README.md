
# BTC Price Microservice

This project provides a microservice to fetch and store Bitcoin prices in EUR and CZK, calculate daily and monthly averages, and expose this data via a REST API.

## Project Structure

```plaintext
msd-homework/
├── .git/
├── .gitignore
├── app/
│   ├── __init__.py
│   └── app.py
├── charts/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       └── service.yaml
├── scripts/
│   └── deploy.sh
├── Dockerfile
└── README.md
```

## Setup and Deployment

### Prerequisites

- Docker
- Kubernetes
- Helm
- Minikube (for local testing)

### Deployment

Use the `deploy.sh` script to deploy the microservice. The project was tested with Minikube.

1. For Minikube:
   ```bash
   ./scripts/deploy.sh --minikube
   ```

2. Manual setup:
   ```bash
    helm package ./charts
    kubectl create namespace niakimychev-msd-homework
    helm repo update
    helm upgrade --install btc-price-microservice ./btc-price-microservice-0.1.0.tgz --namespace niakimychev-msd-homework --create-namespace
   ```

### Endpoints

- `curl -H "Authorization: Bearer tS5nFh64u7" http://localhost:5000/current_price`: Fetch the current Bitcoin price.
- `curl -H "Authorization: Bearer tS5nFh64u7" http://localhost:5000/averages`: Fetch daily and monthly average Bitcoin prices.
