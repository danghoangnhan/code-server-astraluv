# Kubeflow Dashboard UI Integration

Add code-server-astraluv to the Kubeflow "New Notebook" form so users can create VS Code notebooks from the Dashboard.

## Quick Start

### 1. Add images to the Dashboard dropdown

Patch the Jupyter Web App ConfigMap to include code-server-astraluv images:

```bash
kubectl patch configmap jupyter-web-app-config -n kubeflow \
  --patch-file kubeflow/dashboard/spawner-config-patch.yaml
```

Then restart the JWA pod:

```bash
kubectl rollout restart deployment jupyter-web-app -n kubeflow
```

### 2. Deploy PodDefaults to user namespaces

PodDefaults add optional "configurations" (checkboxes) in the New Notebook form.

```bash
# Deploy to a specific user namespace
kubectl apply -k kubeflow/dashboard/ -n kubeflow-user

# Or deploy individually
kubectl apply -f kubeflow/dashboard/poddefault-ssh.yaml -n kubeflow-user
kubectl apply -f kubeflow/dashboard/poddefault-shm.yaml -n kubeflow-user
```

### 3. Create SSH key secret (required for SSH PodDefault)

```bash
# Generate or use an existing SSH key pair
kubectl create secret generic notebook-ssh-key \
  --from-file=jovyan=$HOME/.ssh/id_ed25519.pub \
  -n kubeflow-user
```

### 4. Create a notebook from the Dashboard

1. Open the Kubeflow Dashboard
2. Go to **Notebooks** > **New Notebook**
3. Select a `code-server-astraluv` image from the dropdown
4. Check **Enable SSH access** under Configurations (if needed)
5. Check **Mount /dev/shm** under Configurations (if using GPU)
6. Click **Launch**

### 5. Create SSH Service (for SSH access)

Kubeflow only auto-creates an HTTP Service. For SSH, run:

```bash
scripts/create-ssh-service.sh <notebook-name> <namespace>
```

## Files

| File | Description |
|------|-------------|
| `spawner-config-patch.yaml` | ConfigMap patch for JWA image dropdown |
| `poddefault-ssh.yaml` | PodDefault for SSH key injection |
| `poddefault-shm.yaml` | PodDefault for /dev/shm (GPU) |
| `kustomization.yaml` | Kustomize overlay for PodDefaults + SSH secret |

## Compatibility

| Kubeflow | Format | Notes |
|----------|--------|-------|
| 1.7 | String list | Default format used |
| 1.8+ | Object list | See comments in spawner-config-patch.yaml |

## See Also

- [Kubeflow Deployment Guide](../../wiki/Kubeflow-Deployment.md)
- [SSH Access Documentation](../../wiki/Usage-Guide.md)
