# cshu environment and access

## Source hierarchy

Use facts in this order:

1. Current repository configuration, especially `hosts/shupi/backup.nix`.
2. Read-only observations gathered during the current `sudo` incident session.
3. Historical observations below, labeled with their date.

If sources disagree, current repository configuration and current observations win. Do not silently
promote a historical value into a current fact.

## Verified repository facts

| Area                   | Current fact                                                                                                     | Source                   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------ |
| Modrinth file endpoint | `cshuu.modrinth.gg:2222` over SFTP                                                                               | `hosts/shupi/backup.nix` |
| Endpoint capability    | Configured with `shell_type=none`; do not assume shell or service-control access                                 | `hosts/shupi/backup.nix` |
| Credential ownership   | An agenix secret on `shupi` supplies the automated pull job                                                      | `hosts/shupi/backup.nix` |
| World backups mirror   | Modrinth `simplebackups/` syncs to `/var/backup/minecraft/cshu` on `shupi`                                       | `hosts/shupi/backup.nix` |
| Server files mirror    | Selected `mods/`, configuration, properties, and player-policy files sync to `/var/backup/minecraft/cshu-server` | `hosts/shupi/backup.nix` |
| Off-host backup        | Restic job `minecraft-cshu` backs up both mirror directories to the existing Hetzner repository                  | `hosts/shupi/backup.nix` |
| Schedule               | The Restic job is scheduled for 04:00 with a randomized delay                                                    | `hosts/shupi/backup.nix` |

The automated SFTP credential proves backup wiring only. It is not standing operator access. Never
read or decrypt its contents, reuse it interactively, or claim it can restart/manage the server.

The mirrored server-file set includes `mods/`, `config/`, `defaultconfigs/`, `configureddefaults/`,
`server.properties`, `user_jvm_args.txt`, `ops.json`, `whitelist.json`, ban lists, and
`server-icon.png`. The mirror is evidence and recovery material; it is not automatically the live
server state.

## Client facts and historical observations

- `shuwin` is the logical name the user uses for the Windows Minecraft client.
- Last observed on 2026-10-01, the active Modrinth profile path was
  `C:\Users\shu\AppData\Roaming\ModrinthApp\profiles\NeoForge 1.21.1`.
- That client log encoded the game endpoint as `23.109.123.101:15005` and a cshu server label. Treat
  both as historical until current evidence confirms them.
- `/Users/shu/Code/cshu` is a separate personal Next.js website. It is not the Minecraft modpack,
  server, or client source of truth.

## Read-only access discovery

Run these checks only after the user has explicitly requested diagnosis in `sudo`:

1. Resolve the intended target before connecting. If OpenSSH is the current route, `ssh -G shuwin`
   may confirm alias expansion without opening a connection; it does not prove authentication or
   reachability.
2. Require non-interactive access. Stop rather than prompting for a password, host-key acceptance,
   or credential material.
3. Use the current approved route supplied by configuration or the user. Do not infer a user, key,
   transport, or PowerShell wrapper from the name `shuwin`.
4. Treat Modrinth SFTP as file-only unless current provider evidence proves another interface.
5. Identify the source of every artifact: live server, `shupi` mirror, Restic snapshot, or client.
   Do not compare files without recording their timestamps and origin.

## Stale-fact checklist

Before using a dynamic value, verify or label it unknown:

- current Minecraft version and loader on both server and client
- active Modrinth profile path
- server game address and port
- `shuwin` access route and reachability
- live server file paths and lifecycle-control interface
- latest successful `minecraft-cshu` mirror/Restic run
- timestamp and completeness of any mirrored or restored artifact

Stop if the task requires an unverified access route or credential. Ask for the minimum missing
fact; do not search blocked session storage or secret files.
