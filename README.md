# Task 2 - Deploy llama with argocd


Generate base64 encoding for Secret:
```bash
echo "mega_secret_key" | base64
```

Let argocd manage itself:
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd
