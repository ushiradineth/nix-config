# Selfsync

Obsidian sync at <https://sync.shupi.ushira.com>, accessible over Tailscale. `http://sync.shu`
redirects there. The server uses a pinned official image, unprivileged with a read-only root
filesystem. State lives in `/srv/selfsync/data`.

## Connect Obsidian

1. Keep Tailscale connected, create an empty local vault, and install **Selfsync** from Obsidian's
   community plugins (the self-hosted plugin).
2. Create a device link in your own terminal:

   ```sh
   ssh -t root@shupi 'docker exec -it selfsync /usr/local/bin/selfsync link --vault notes --name mac'
   ```

3. Open the link on that device and confirm the connection in Obsidian.
4. Enable end-to-end encryption in the plugin before syncing your real notes. Save its password and
   recovery phrase in your password manager.
5. Copy your notes and attachments into the encrypted vault, leaving the old `.obsidian` directory
   behind. Use **Connect a new device** in the plugin for each additional device.

Device links are credentials: don't commit them or share terminal logs containing them. Disable the
old CouchDB/LiveSync plugin before connecting this vault; don't run two sync engines on the same
vault. Existing notes and the CouchDB archive are not imported automatically. Keep your original
vault until the new setup is verified.

## Backups and integrity

The app-data Restic job first runs `selfsync-backup.service`. This takes a consistent snapshot with
real blob copies and keeps seven snapshots under `/srv/selfsync/backups`; a failed snapshot fails
the offsite job. Restic sends these snapshots to the existing Hetzner app-data repository. Weekly
integrity checks verify SQLite and blob hashes; failures use the existing ntfy alert.

```sh
ssh root@shupi 'systemctl start selfsync-backup.service selfsync-verify.service'
ssh root@shupi 'docker exec selfsync /usr/local/bin/selfsync token list'
```

To check a restored snapshot, mount it at `/restore` in the same image and run
`selfsync --data /restore verify`. To serve a restore, stop the server first, preserve the current
data directory, and restore the snapshot as UID/GID 65532. Selfsync snapshots carry a new database
generation so devices detect the rollback. For filesystem snapshots or other copies taken without
`selfsync backup`, run `selfsync vault regenerate` against restored data before starting the server.
Keep the old data until verified.

History/trash cleanup is manual (`selfsync sweep`); no automatic purge is enabled. Upstream
operations guide: <https://github.com/Darkildo/selfsync#server>.
