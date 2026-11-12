"""Redact the existing morning digest's bounded journal sample into issue groups."""
import datetime as dt
import json
import re
import sys
from collections import Counter

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

if __name__ == '__main__':
    rows = [json.loads(line) for line in sys.stdin if line.strip()]
    if len(sys.argv) == 3 and sys.argv[1] == '--unit':
        unit = sys.argv[2]
        print(json.dumps({'unit': unit, **backup_history(rows, unit, dt.datetime.now(dt.timezone.utc))}))
    else:
        print(json.dumps({'issues': issue_groups(rows), 'journalEntriesSampled': len(rows), 'journalAtLimit': len(rows) == 2000}))
