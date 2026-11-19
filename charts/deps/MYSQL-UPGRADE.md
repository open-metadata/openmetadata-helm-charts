# MySQL 8.4 deployment and migration

Dependency chart 3.x replaces Bitnami MySQL with a bundled standalone chart using
`docker.io/mysql:8.4.13`. The OpenMetadata application version is unchanged.
This chart major version reflects the incompatible database packaging change.
The 2.0 release line uses dependency chart 3.0.0; main uses 3.1.0.
Publish each version once; do not overwrite an already published chart archive.

## New installations

The default Service remains `mysql:3306`. The StatefulSet is `mysql-84`, with a
new `data-mysql-84-0` PVC and data under `/var/lib/mysql/mysql`. The old Bitnami
`data-mysql-0` volume is deliberately not selected. Do not point `existingClaim`
at an old Bitnami volume. The container's official entrypoint runs `initdbScripts`
only when the data directory is empty and uses `caching_sha2_password` for new users.
Do not enable `mysql_native_password` or pass `--default-authentication-plugin`.

Use a Kubernetes Secret containing `mysql-root-password`, and `mysql-password`
when `auth.username` is configured:

```yaml
mysql:
  auth:
    existingSecret: mysql-credentials
  primary:
    persistence:
      size: 50Gi
```

Alternatively set `auth.rootPassword` and, if needed, `auth.database`,
`auth.username` and `auth.password`. These values generate a Secret; retain the
same credentials on upgrades. Application SQL in the parent chart creates the
OpenMetadata and Airflow accounts. Override those scripts with your intended
credentials, and configure the application Secrets to match. Avoid creating the
same database/user with both `auth.*` and an init script (the OpenShift example
replaces those scripts with no-ops when using `auth.*`). Do not commit passwords.
Secret changes alone do not change passwords in an initialized database.

## Existing MySQL 8.0 installations

Do not run an unattended `helm upgrade` against the old database installation.
The chart rejects upgrade rendering unless
`mysql.migration.backupAndRestoreCompleted=true` is explicitly supplied.

1. Rehearse with a copy of production data. Run MySQL Shell's upgrade checker
   against the source and resolve reported incompatibilities. Confirm that the
   OpenMetadata release and JDBC clients support 8.4.
2. Stop OpenMetadata, Airflow schedulers/workers and all other database writers.
   Take and verify a complete backup, including routines, events and triggers,
   of `openmetadata_db` and `airflow_db`. Preserve the old database PVC, credentials,
   chart values and release images. Ensure the backup can actually be restored.
3. Install this chart in a separate namespace/release with **new storage**. For a
   database-only migration target, disable `airflow.enabled`, `opensearch.enabled`
   and `fuseki.enabled`. Set the intended root/application credentials. Do not
   import the old `mysql` system database or copy the Bitnami data directory.
4. Restore the two application databases to 8.4.13, including routines, events and
   triggers. Recreate any additional users/grants with supported authentication.
   Validate data counts, representative JSON values, privileges and both services'
   connections. Run the OpenMetadata migrations and application smoke tests.
5. Point the applications at the new Service (use its namespace-qualified DNS
   name when crossing namespaces) and matching credentials, then resume writers.
   Keep the old database stopped and its backup intact through the rollback window.
6. For subsequent upgrades of the migrated release, retain
   `mysql.migration.backupAndRestoreCompleted: true` in its saved values. This is
   an operator acknowledgment, not an automated migration or backup check.

Rollback means restoring the pre-upgrade backup into an isolated MySQL 8.0
instance and reverting application versions/configuration. Never start MySQL 8.0
on a directory initialized or upgraded by 8.4. Writes after cutover require an
explicit recovery/reconciliation plan before rollback.

## Supported MySQL values

This is not a drop-in implementation of every Bitnami option. Review overrides
before migrating; do not assume Bitnami-specific settings carry over.

| Value | Purpose |
| --- | --- |
| `enabled`, `fullnameOverride` | Enable the dependency and choose the Service name |
| `architecture` | Only `standalone` is supported; other values fail rendering |
| `image.registry`, `repository`, `tag`, `pullPolicy` | Official MySQL image selection |
| `imagePullSecrets` | Kubernetes image pull Secret references |
| `auth.existingSecret` | Secret with the password keys described above |
| `auth.rootPassword`, `database`, `username`, `password` | Official entrypoint initialization |
| `initdbScripts` | File-name to SQL/shell script mapping for first initialization |
| `primary.extraFlags` | Space-separated mysqld flags, without shell quoting |
| `primary.persistence.enabled`, `size`, `storageClass`, `existingClaim` | Storage; existingClaim must contain compatible official-image data |
| `primary.service.type`, `port`, `nodePort` | Client Service; nodePort applies only to NodePort |
| `primary.resources` | Container resource requests and limits |
| `primary.podSecurityContext`, `containerSecurityContext` | Cluster-specific security settings |
| `primary.nodeSelector`, `tolerations`, `affinity` | Scheduling settings |
| `migration.backupAndRestoreCompleted` | Required acknowledgment for Helm upgrades |

The supplied OpenShift example needs validation with the target cluster's SCC
and storage permissions. This change does not assert compatibility with every
restricted OpenShift policy or managed Kubernetes storage class.
