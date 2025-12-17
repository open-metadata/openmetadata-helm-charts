# Open Metadata Helm Dependencies

A Helm chart for installing components required to run Open Metadata.

## Components

This chart installs the following dependencies:
- **MySQL 8.0** - Database for OpenMetadata and Airflow
- **Apache Airflow 3** (via official Apache Airflow Helm chart) - Workflow orchestration for data ingestion
- **OpenSearch** - Search and indexing engine

## Airflow 3 Compatibility

This chart uses **Apache Airflow 3** with the official Apache Airflow Helm chart. Key configurations for Airflow 3:

- **KubernetesExecutor**: Configured by default to use KubernetesExecutor for production deployments with scalable task execution across multiple worker pods
- **MySQL Backend**: Airflow 3 with MySQL requires downgrading the FAB provider to v2.4.4 to avoid `CREATE INDEX IF NOT EXISTS` syntax incompatibility
- **Shared DAGs Volume**: The api-server and scheduler pods share the same PVC for dynamic DAG generation by OpenMetadata
- **Static Secret Key**: A static `webserverSecretKey` is configured by default to ensure JWT token authentication works correctly between Airflow components. While not strictly mandatory, it's strongly recommended to prevent authentication failures

## Install OpenMetadata Dependencies

Assuming kubectl context points to the correct kubernetes cluster, first create kubernetes secrets that contain airflow mysql password as secrets.

```
kubectl create secret generic airflow-mysql-secrets --from-literal=airflow-mysql-password=airflow_pass
```

Next, we run the following command to install openmetadata with default configuration.

```
helm repo add open-metadata https://helm.open-metadata.org
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies
```

If the default configuration is not applicable, you can update the values listed below in a `values.yaml` file and run

```
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies --values <<path-to-values-file>>
```

### Configuration for Different Environments

#### For Local Development (Docker Desktop/Minikube)

If you're running on Docker Desktop or Minikube, you need to use LocalExecutor because these environments don't support ReadWriteMany (RWX) PersistentVolumeClaims. Create a custom values file:

```yaml
# local-values.yaml
airflow:
  executor: "LocalExecutor"
  workers:
    replicas: 0
```

Then install with:
```bash
helm install openmetadata-dependencies open-metadata/openmetadata-dependencies --values local-values.yaml
```

#### For Production Deployments

The default configuration uses KubernetesExecutor, which is recommended for production. Important considerations:

1. **Change the `webserverSecretKey`**: Generate a new secret key for production:
   ```bash
   openssl rand -hex 32
   ```
   Update `airflow.webserverSecretKey` in your values file with the generated key.

2. **Configure RWX Storage**: KubernetesExecutor requires ReadWriteMany (RWX) storage for DAGs:
   - Update `airflow.dags.persistence.storageClassName` to a storage class that supports RWX (e.g., `efs-sc` on AWS, `azurefile` on Azure, `nfs-client` on GKE)
   - Most cloud providers support RWX storage classes

3. **Adjust Worker Replicas**: Set `airflow.workers.replicas` based on your workload (default is 2)

4. **Update Database Passwords**: Change the default MySQL passwords in your production values file

Example production values:
```yaml
airflow:
  webserverSecretKey: "<your-generated-key>"
  executor: "KubernetesExecutor"
  workers:
    replicas: 3
  dags:
    persistence:
      storageClassName: "efs-sc"  # Or your RWX storage class
mysql:
  auth:
    rootPassword: "<strong-password>"
```