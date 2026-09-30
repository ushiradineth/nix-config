{
  config,
  pkgs,
  ...
}: let
  journalSummary = pkgs.writeText "journal-summary.py" (builtins.readFile ./journal-summary.py);
  ntfyUrl = "http://127.0.0.1:${toString config.ports.ntfy}/log";
in {
  systemd.services.ntfy-log-digest = {
    description = "Send quiet morning status digest to ntfy log topic";
    after = ["docker-ntfy.service"];
    wants = ["docker-ntfy.service"];

    path = with pkgs; [
      coreutils
      curl
      gnugrep
      gnused
      jq
      restic
      sqlite
      systemd
      python3
    ];

    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "shupi-status";
    };

    script = ''
      set -eu

      report_date=$(date '+%d/%m/%Y')
      yesterday_iso=$(date -d 'yesterday' +%F)
      today_iso=$(date +%F)

      # Backups, syncs, and checks should reflect today's overnight jobs.
      job_since="$today_iso 00:00:00"
      job_until="now"

      # Websites should reflect yesterday midnight until the digest runs.
      website_since="$yesterday_iso 00:00:00"
      website_until="now"

      report=$(mktemp)
      send_report=$(mktemp)
      issues=$(mktemp)
      website_issues=$(mktemp)

      success="◎"
      error="×"
      warning="△"
      info="※"
      partial="〜"
      unknown="？"

      trap 'rm -f "$report" "$send_report" "$issues" "$website_issues"' EXIT

      format_dt() {
        input="$1"

        if [ -z "$input" ]; then
          echo "unknown"
          return
        fi

        date -d "$input" '+%d/%m/%Y %H:%M' 2>/dev/null || echo "$input"
      }

      human_ago() {
        input="$1"

        if [ -z "$input" ]; then
          echo "unknown"
          return
        fi

        input_epoch=$(date -d "$input" +%s 2>/dev/null || echo "")
        now_epoch=$(date +%s)

        if [ -z "$input_epoch" ]; then
          echo "unknown"
          return
        fi

        diff=$((now_epoch - input_epoch))

        if [ "$diff" -lt 0 ]; then
          echo "in the future"
        elif [ "$diff" -lt 60 ]; then
          echo "just now"
        elif [ "$diff" -lt 3600 ]; then
          mins=$((diff / 60))

          if [ "$mins" -eq 1 ]; then
            echo "1 minute ago"
          else
            echo "$mins minutes ago"
          fi
        elif [ "$diff" -lt 86400 ]; then
          hours=$((diff / 3600))

          if [ "$hours" -eq 1 ]; then
            echo "1 hour ago"
          else
            echo "$hours hours ago"
          fi
        else
          days=$((diff / 86400))

          if [ "$days" -eq 1 ]; then
            echo "1 day ago"
          else
            echo "$days days ago"
          fi
        fi
      }

      human_age() {
        hours="$1"

        if [ "$hours" -lt 24 ]; then
          echo "$hours hours"
        else
          days=$((hours / 24))
          remaining_hours=$((hours % 24))

          if [ "$remaining_hours" -eq 0 ]; then
            echo "$days days"
          else
            echo "$days days, $remaining_hours hours"
          fi
        fi
      }

      status_icon() {
        ok="$1"
        total="$2"

        if [ "$total" -gt 0 ] && [ "$ok" -eq "$total" ]; then
          printf '%s' "$success"
        else
          printf '%s' "$warning"
        fi
      }

      summary_line() {
        label="$1"
        ok="$2"
        total="$3"

        printf '%s %s: %s/%s\n' \
          "$(status_icon "$ok" "$total")" \
          "$label" \
          "$ok" \
          "$total"
      }

      backup_ok=0
      backup_total=0

      sync_ok=0
      sync_total=0

      check_ok=0
      check_total=0

      issue_count=0

      observations=$(mktemp)
      trap 'rm -f "$report" "$send_report" "$issues" "$website_issues" "$observations"' EXIT

      unit_check() {
        category="$1"
        unit="$2"
        label="$3"

        if ! systemctl cat "$unit" >/dev/null 2>&1; then
          if [ "$category" = "backup" ]; then
            jq -nc --arg unit "$unit" '{unit:$unit,status:"unknown",error:"Unit unavailable"}' >> "$observations"
          fi
          issue_count=$((issue_count + 1))
          printf -- "%s %s: unit not found: %s\n" "$error" "$label" "$unit" >> "$issues"

          case "$category" in
            backup) backup_total=$((backup_total + 1)) ;;
            sync) sync_total=$((sync_total + 1)) ;;
            check) check_total=$((check_total + 1)) ;;
          esac

          return
        fi

        observation=$(journalctl "UNIT=$unit" JOB_TYPE=start --since '14 days ago' -n 60 -o json --no-pager 2>/dev/null | python ${journalSummary} --unit "$unit" || jq -nc --arg unit "$unit" '{unit:$unit,status:"unknown"}')
        result=$(printf '%s' "$observation" | jq -r '.lastAttemptResult // "unknown"')
        last_attempt=$(printf '%s' "$observation" | jq -r '.lastAttempt // empty')
        active_state=$(systemctl show "$unit" -P ActiveState 2>/dev/null || echo unknown)
        exec_status=$(systemctl show "$unit" -P ExecMainStatus 2>/dev/null || echo unknown)
        failed=1
        ran_today=0
        if [ -n "$last_attempt" ] && [ "$(date -d "$last_attempt" +%s)" -ge "$(date -d "$job_since" +%s)" ]; then
          ran_today=1
        fi
        if [ "$result" = "done" ] && [ "$ran_today" -eq 1 ]; then failed=0; fi
        if [ "$category" = "backup" ]; then printf '%s\n' "$observation" >> "$observations"; fi

        case "$category" in
          backup)
            backup_total=$((backup_total + 1))
            if [ "$failed" -eq 0 ]; then
              backup_ok=$((backup_ok + 1))
            fi
            ;;
          sync)
            sync_total=$((sync_total + 1))
            if [ "$failed" -eq 0 ]; then
              sync_ok=$((sync_ok + 1))
            fi
            ;;
          check)
            check_total=$((check_total + 1))
            if [ "$failed" -eq 0 ]; then
              check_ok=$((check_ok + 1))
            fi
            ;;
        esac

        if [ "$failed" -eq 1 ]; then
          issue_count=$((issue_count + 1))

          {
            if [ "$exec_status" != "0" ] && [ "$exec_status" != "" ]; then
              printf -- "%s %s: failed with exit code %s\n" "$error" "$label" "$exec_status"
            else
              printf -- "%s %s: result=%s, state=%s\n" "$error" "$label" "$result" "$active_state"
            fi

            if [ "$ran_today" -eq 0 ]; then
              printf -- "did not run in job window: %s → now\n" "$(format_dt "$job_since")"
            fi
          } >> "$issues"
        fi
      }

      macos_code_backup_check() {
        repository="/srv/backups/shu-code"
        password_file="/run/agenix/restic-password"
        tag="shu-code"
        max_age_hours=48

        backup_total=$((backup_total + 1))

        if [ ! -d "$repository" ]; then
          issue_count=$((issue_count + 1))
          printf -- "%s macOS code backup repository is missing.\n" "$error" >> "$issues"
          return
        fi

        if [ ! -r "$password_file" ]; then
          issue_count=$((issue_count + 1))
          printf -- "%s macOS code backup password file is not readable.\n" "$error" >> "$issues"
          return
        fi

        latest_snapshot=$(
          restic \
            -r "$repository" \
            --password-file "$password_file" \
            snapshots \
            --latest 1 \
            --tag "$tag" \
            --json 2>/dev/null | jq -r '.[0].time // empty' || true
        )

        if [ -z "$latest_snapshot" ]; then
          issue_count=$((issue_count + 1))
          printf -- "%s macOS code backup has no snapshots.\n" "$error" >> "$issues"
          return
        fi

        snapshot_epoch=$(date -d "$latest_snapshot" +%s 2>/dev/null || echo 0)

        if [ "$snapshot_epoch" -le 0 ]; then
          issue_count=$((issue_count + 1))
          printf -- "%s macOS code backup has an unreadable snapshot time.\n" "$error" >> "$issues"
          return
        fi

        age_hours=$(( ($(date +%s) - snapshot_epoch) / 3600 ))

        if [ "$age_hours" -gt "$max_age_hours" ]; then
          issue_count=$((issue_count + 1))
          printf -- "%s macOS code backup is %s stale.\n" "$error" "$(human_age "$age_hours")" >> "$issues"
          return
        fi

        backup_ok=$((backup_ok + 1))
      }

      unit_check backup "restic-backups-critical-data.service" "critical-data backup"
      unit_check backup "restic-backups-db-dumps.service" "db-dumps backup"
      unit_check backup "restic-backups-app-data.service" "app-data backup"
      unit_check backup "restic-backups-config.service" "config backup"
      unit_check backup "restic-backups-minecraft-cshu.service" "Minecraft backup"
      unit_check backup "dump-lifeos-db.service" "LifeOS PostgreSQL dump"
      macos_code_backup_check

      unit_check sync "forgejo-sync-github.service" "Forgejo GitHub sync"

      website_total=0
      website_down=0

      if [ -f /srv/uptimekuma/kuma.db ]; then
        website_total=$(sqlite3 -readonly /srv/uptimekuma/kuma.db "
          select count(*)
          from monitor
          where active = 1
            and type != 'group';
        " 2>/dev/null || echo 0)

        sqlite3 -readonly -noheader -separator '|' /srv/uptimekuma/kuma.db "
          with latest as (
            select
              h.monitor_id,
              h.status,
              h.time
            from heartbeat h
            join (
              select
                monitor_id,
                max(time) as latest_time
              from heartbeat
              group by monitor_id
            ) lh
              on lh.monitor_id = h.monitor_id
             and lh.latest_time = h.time
          )
          select
            m.name,
            sum(case when h.status = 0 then 1 else 0 end) as down_events,
            max(case when h.status = 0 then h.time end) as last_down,
            latest.status as current_status,
            latest.time as current_seen
          from heartbeat h
          join monitor m on m.id = h.monitor_id
          join latest on latest.monitor_id = m.id
          where h.time >= '$website_since'
            and h.time < datetime('now', 'localtime')
            and m.active = 1
            and m.type != 'group'
          group by m.id, m.name, latest.status, latest.time
          having down_events > 0
          order by down_events desc, m.name;
        " > "$website_issues" 2>/dev/null || true

        if [ -s "$website_issues" ]; then
          website_down=$(wc -l < "$website_issues" | tr -d ' ')
          issue_count=$((issue_count + website_down))
        fi
      else
        website_total="unknown"
        issue_count=$((issue_count + 1))
        echo "$error Uptime Kuma database not found: /srv/uptimekuma/kuma.db" >> "$issues"
      fi

      {
        echo "$info Summary"
        summary_line "Backups" "$backup_ok" "$backup_total"
        summary_line "Syncs" "$sync_ok" "$sync_total"

        if [ "$check_total" -gt 0 ]; then
          summary_line "Availability checks" "$check_ok" "$check_total"
        else
          echo "$partial Availability checks: skipped"
        fi

        if [ "$website_total" = "unknown" ]; then
          echo "$unknown Websites: unable to read Uptime Kuma"
        elif [ "$website_down" -eq 0 ]; then
          echo "$success Websites: $website_total/$website_total monitors had no downtime since yesterday"
        else
          website_ok=$((website_total - website_down))
          echo "$warning Websites: $website_ok/$website_total monitors had no downtime since yesterday"
        fi

        echo

        if [ "$issue_count" -eq 0 ]; then
          echo "$success No action needed."
        else
          echo "$warning Issues"

          if [ -s "$issues" ]; then
            cat "$issues"
          fi

          if [ -s "$website_issues" ]; then
            echo
            echo "$warning Websites with downtime since yesterday"

            while IFS='|' read -r monitor down_events last_down current_status current_seen; do
              if [ "$current_status" = "1" ]; then
                status_text="currently up"
              elif [ "$current_status" = "0" ]; then
                status_text="still down"
              else
                status_text="current status unknown"
              fi

              printf -- "- %s: last down %s, %s\n" \
                "$monitor" \
                "$(human_ago "$last_down")" \
                "$status_text"
            done < "$website_issues"
          fi
        fi
      } > "$report"

      journalctl --since "$yesterday_iso 00:00:00" --until "$today_iso 00:00:00" -p warning -n 2000 -o json --no-pager \
        | python ${journalSummary} > /var/lib/shupi-status/journal.tmp || \
        echo '{"issues":[],"journalError":"Journal summary unavailable"}' > /var/lib/shupi-status/journal.tmp
      monitors=$(sqlite3 -readonly -json /srv/uptimekuma/kuma.db "
        select m.name, h.status, h.time as seen
        from monitor m left join heartbeat h on h.monitor_id=m.id
          and h.id=(select id from heartbeat where monitor_id=m.id order by time desc,id desc limit 1)
        where m.active=1 and m.type != 'group' order by m.name;
      " 2>/dev/null || echo 'null')
      jq -s --argjson monitors "$monitors" --arg collected "$(date --iso-8601=seconds)" --arg day "$yesterday_iso" \
        --slurpfile journal /var/lib/shupi-status/journal.tmp \
        '{collectedAt:$collected,reportDay:$day,backups:.,services:[],failedUnits:null,monitors:$monitors} + $journal[0]' "$observations" > /var/lib/shupi-status/report.tmp
      chmod 644 /var/lib/shupi-status/report.tmp
      mv /var/lib/shupi-status/report.tmp /var/lib/shupi-status/report.json
      rm /var/lib/shupi-status/journal.tmp

      max_bytes=3500

      if [ "$(wc -c < "$report")" -gt "$max_bytes" ]; then
        {
          head -c "$max_bytes" "$report"
          echo
          echo
          echo "[truncated: original report was $(wc -c < "$report") bytes]"
        } > "$send_report"
      else
        cp "$report" "$send_report"
      fi

      if [ "$issue_count" -eq 0 ]; then
        ntfy_priority="min"
      else
        ntfy_priority="high"
      fi

      curl -fsS \
        -H "Title: shupi morning status: $report_date" \
        -H "Priority: $ntfy_priority" \
        --data-binary @"$send_report" \
        "${ntfyUrl}"
    '';
  };

  systemd.timers.ntfy-log-digest = {
    description = "Send quiet morning status digest to ntfy log topic";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 09:00:00";
      Persistent = true;
    };
  };
}
