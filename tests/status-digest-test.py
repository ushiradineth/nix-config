import datetime as dt
import importlib.util
import unittest
import sys
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('observer', 'hosts/shupi/services/journal-summary.py')
o = importlib.util.module_from_spec(spec)
spec.loader.exec_module(o)
NOW = dt.datetime(2026, 9, 30, 5, tzinfo=dt.timezone.utc)
UNIT = 'restic-backups-app-data.service'

def event(hours, result):
    return {'UNIT': UNIT, 'JOB_TYPE': 'start', 'JOB_RESULT': result, '__REALTIME_TIMESTAMP': str(int((NOW - dt.timedelta(hours=hours)).timestamp() * 1000000))}

class ObserverTests(unittest.TestCase):
    def test_failure_after_success_survives_restart(self):
        r = o.backup_history([event(25, 'done'), event(3, 'failed')], UNIT, NOW)
        self.assertEqual(r['status'], 'failed')
        self.assertEqual(r['ageHours'], 25)

    def test_missing_evidence_is_not_success(self):
        self.assertEqual(o.backup_history([], UNIT, NOW)['status'], 'unknown')
        self.assertEqual(o.backup_history([event(31, 'done')], UNIT, NOW)['status'], 'stale')
        self.assertEqual(o.backup_history([event(2, 'done')], UNIT, NOW)['status'], 'recent')

    def test_grouping_never_exports_raw_messages(self):
        rows = [{'UNIT': UNIT, 'MESSAGE': 'authentication failed password=secret'}, {'UNIT': UNIT, 'MESSAGE': 'authentication failed token=secret'}]
        groups = o.issue_groups(rows)
        self.assertEqual(groups, [{'unit': UNIT, 'category': 'Access problem', 'count': 2}])
        self.assertNotIn('secret', str(groups))

unittest.main()
