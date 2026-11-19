"""Run with: uv run --with pyyaml python -m unittest discover -s tests."""
import pathlib
import subprocess
import unittest

import yaml

CHART = pathlib.Path(__file__).resolve().parents[1] / 'charts/deps/charts/mysql'


def render(*args, success=True):
    result = subprocess.run(
        ['helm', 'template', 'test', str(CHART), '--set', 'auth.rootPassword=test-only', *args],
        capture_output=True, text=True,
    )
    if not success:
        if result.returncode == 0:
            raise AssertionError('Rendering unexpectedly succeeded')
        return result.stderr
    if result.returncode:
        raise AssertionError(result.stderr)
    return [doc for doc in yaml.safe_load_all(result.stdout) if doc]


def resource(docs, kind):
    return next(doc for doc in docs if doc['kind'] == kind)


class MysqlChartTests(unittest.TestCase):
    def test_official_image_and_new_storage(self):
        sts = resource(render(), 'StatefulSet')
        self.assertEqual(sts['metadata']['name'], 'mysql-84')
        container = sts['spec']['template']['spec']['containers'][0]
        self.assertEqual(container['image'], 'docker.io/mysql:8.4.13')
        self.assertNotIn('command', container)  # Keep the official entrypoint.
        self.assertEqual(container['env'][0]['name'], 'MYSQL_ROOT_PASSWORD_FILE')
        self.assertEqual(container['volumeMounts'][0]['mountPath'], '/var/lib/mysql')
        self.assertEqual(sts['spec']['volumeClaimTemplates'][0]['metadata']['name'], 'data')

    def test_existing_secret_is_not_recreated(self):
        docs = render('--set', 'auth.existingSecret=external')
        self.assertFalse(any(doc['kind'] == 'Secret' for doc in docs))
        volumes = resource(docs, 'StatefulSet')['spec']['template']['spec']['volumes']
        self.assertEqual(next(v for v in volumes if v['name'] == 'passwords')['secret']['secretName'], 'external')

    def test_existing_claim_and_ephemeral_storage(self):
        for args, key in [(['--set', 'primary.persistence.existingClaim=restored-data'], 'persistentVolumeClaim'),
                          (['--set', 'primary.persistence.enabled=false'], 'emptyDir')]:
            sts = resource(render(*args), 'StatefulSet')
            self.assertNotIn('volumeClaimTemplates', sts['spec'])
            volumes = sts['spec']['template']['spec']['volumes']
            self.assertIn(key, next(v for v in volumes if v['name'] == 'data'))

    def test_upgrade_requires_migration_acknowledgment(self):
        self.assertIn('backupAndRestoreCompleted', render('--is-upgrade', success=False))
        render('--is-upgrade', '--set', 'migration.backupAndRestoreCompleted=true')

    def test_replication_is_not_silently_ignored(self):
        self.assertIn('standalone', render('--set', 'architecture=replication', success=False))

    def test_client_service_selects_own_workload(self):
        docs = render('--set', 'fullnameOverride=custom', '--set', 'primary.service.type=NodePort',
                      '--set', 'primary.service.nodePort=30306')
        svc = resource(docs, 'Service')
        sts = resource(docs, 'StatefulSet')
        self.assertEqual(svc['metadata']['name'], 'custom')
        self.assertEqual(svc['spec']['selector'], sts['spec']['template']['metadata']['labels'])
        self.assertEqual(svc['spec']['ports'][0]['nodePort'], 30306)

    def test_init_and_optional_user(self):
        docs = render('--set', 'auth.database=app', '--set', 'auth.username=app',
                      '--set', 'auth.password=test-only', '--set-string', 'initdbScripts.test\\.sql=SELECT 1;')
        self.assertEqual(resource(docs, 'ConfigMap')['data']['test.sql'], 'SELECT 1;')
        env = resource(docs, 'StatefulSet')['spec']['template']['spec']['containers'][0]['env']
        self.assertIn({'name': 'MYSQL_PASSWORD_FILE', 'value': '/run/mysql-secrets/mysql-password'}, env)
        self.assertIn('mysql-password', resource(docs, 'Secret')['data'])


if __name__ == '__main__':
    unittest.main()
