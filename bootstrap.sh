#!/bin/bash

kubectl apply -k infra/argocd
kubectl -n argocd apply -f infra/app-of-apps
