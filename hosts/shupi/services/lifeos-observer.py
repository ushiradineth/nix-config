"""Bounded read-only observations; raw journal messages never leave the host."""
import datetime as dt
import json
import os
import re
import subprocess
from collections import Counter
from pathlib import Path
from zoneinfo import ZoneInfo

UNITS = ['restic-backups-critical-data.service', 'restic-backups-db-dumps.service',
         'restic-backups-app-data.service', 'restic-backups-config.service',
         'restic-backups-minecraft-cshu.service', 'lifeos-db-dump.service']


def run(binary, *args):
    r = subprocess.run([os.environ[binary], *args], capture_output=True, text=True, timeout=25)
    if r.returncode:
        raise RuntimeError('Observation unavailable')
    return r.stdout


def journal(*args):
    return [json.loads(line) for line in run('JOURNALCTL', *args, '-o', 'json', '--no-pager').splitlines()]


def timestamp(row):
    return dt.datetime.fromtimestamp(int(row['__REALTIME_TIMESTAMP']) / 1000000, dt.timezone.utc)


def backup_history(rows, unit, now):
    # A done start job establishes completion only for these known oneshot backup units.
    completed = sorted([r for r in rows if r.get('UNIT') == unit and r.get('JOB_TYPE') == 'start' and r.get('JOB_RESULT')], key=timestamp)
    successes = [r for r in completed if r['JOB_RESULT'] == 'done']
    latest = completed[-1] if completed else None
    last_success = timestamp(successes[-1]) if successes else None
    age = (now - last_success).total_seconds() / 3600 if last_success else None
    status = 'unknown'
    if latest and latest['JOB_RESULT'] != 'done':
        status = 'failed'
    elif age is not None:
        status = 'recent' if 0 <= age <= 30 else 'stale'
    return {'status': status, 'lastSuccess': last_success.isoformat() if last_success else None,
            'lastAttempt': timestamp(latest).isoformat() if latest else None,
            'lastAttemptResult': latest['JOB_RESULT'] if latest else None,
            'ageHours': round(age, 1) if age is not None else None, 'thresholdHours': 30}


def issue_groups(rows):
    counts = Counter()
    for row in rows:
        unit = row.get('UNIT') or row.get('_SYSTEMD_UNIT') or 'host'
        if not re.fullmatch(r'[A-Za-z0-9_.@:-]{1,160}', unit):
            unit = 'host'
        message = str(row.get('MESSAGE', '')).lower()
        category = ('Unit configuration' if 'has no effect' in message or 'ignoring' in message else
                    'Connection problem' if any(x in message for x in ['connection refused', 'connection reset', 'network is unreachable', 'could not resolve']) else
                    'Timeout' if 'timed out' in message or 'timeout' in message else
                    'Access problem' if 'permission denied' in message or 'authentication failed' in message else
                    'Failed service/job' if row.get('JOB_RESULT') == 'failed' or 'failed with result' in message else
                    'Other warning/error')
        counts[(unit, category)] += 1
    return [{'unit': k[0], 'category': k[1], 'count': n} for k, n in counts.most_common(15)]


def collect(now):
    zone = ZoneInfo('Asia/Colombo')
    day = now.astimezone(zone).date() - dt.timedelta(days=1)
    start = dt.datetime.combine(day, dt.time(), zone).isoformat()
    end = dt.datetime.combine(day + dt.timedelta(days=1), dt.time(), zone).isoformat()
    report = {'collectedAt': now.isoformat(), 'reportDay': str(day), 'backups': [], 'issues': [], 'services': []}
    for unit in UNITS:
        backup = {'unit': unit}
        try:
            fields = run('SYSTEMCTL', 'show', unit, '--property=LoadState,ActiveState,Result,ExecMainStatus')
            backup['fields'] = dict(line.split('=', 1) for line in fields.splitlines() if '=' in line)
            rows = journal('UNIT=' + unit, 'JOB_TYPE=start', '--since', '14 days ago', '-n', '60')
            backup.update(backup_history(rows, unit, now))
        except Exception:
            backup.update({'status': 'unknown', 'error': 'Backup observation unavailable.'})
        report['backups'].append(backup)
    try:
        rows = journal('--since', start, '--until', end, '-p', 'warning', '-n', '2000')
        report['issues'] = issue_groups(rows)
        report['journalEntriesSampled'] = len(rows)
        report['journalAtLimit'] = len(rows) == 2000
    except Exception:
        report['journalError'] = 'Yesterday’s journal summary is unavailable.'
    try:
        failed = run('SYSTEMCTL', '--failed', '--no-legend', '--plain')
        report['failedUnits'] = [line.split()[0] for line in failed.splitlines() if line.strip()]
    except Exception:
        report['failedUnits'] = None
    for unit in ['docker.service', 'tailscaled.service', 'traefik.service', 'wakapi.service', 'lifeos.service']:
        try:
            fields = dict(line.split('=', 1) for line in run('SYSTEMCTL', 'show', unit, '--property=LoadState,ActiveState,SubState').splitlines() if '=' in line)
            report['services'].append({'unit': unit, **fields})
        except Exception:
            report['services'].append({'unit': unit, 'ActiveState': 'unknown'})
    return report


if __name__ == '__main__':
    report = collect(dt.datetime.now(dt.timezone.utc))
    path = Path('/var/lib/lifeos-observer/report.json')
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(report))
    os.chmod(temp, 0o644)
    temp.replace(path)
