# Patch Apply

Out-of-place patching with the playbooks `patch_apply` and `patch_rollback`. The databases move to a new Oracle
Home through the odb_autoupgrade engine (`au_run.sh -mode deploy`); the collection adds the Data Guard order,
listener and network files, standby apply and the checks around it.

> **Status v0.2.0:** `oracle_home_switch` and `oracle_home_rollback` have not yet run against a real database.
> Molecule covers their logic with stub homes and the engine in dry-run mode. Run them in a lab with a Data Guard
> pair before a production window.

## Sequence

<!-- markdownlint-disable MD013 MD060 -->
| Step | Playbook / role | Hosts | What happens |
| --- | --- | --- | --- |
| 1 | `patch_download` | download host | Patch set by profile, pin file, verification |
| 2 | `home_create` | all | Folder staged (optional), new home `product/<RU>.0.0` from the profile folder |
| 3 | `patch_apply`: `patch_stage` | all without MOS | Folder from the download host via the controller, verified on each host (only with `oradba_patch_stage_from`) |
| 4 | `patch_apply`: `autoupgrade_preflight` | all | Engine, folder, target home, free space, per database state, ARCHIVELOG, home comparison, `-mode analyze` |
| 5 | `patch_apply`: switch phase `standby` | all | Physical standby databases: deploy, apply restarted |
| 6 | `patch_apply`: switch phase `standalone` | all | Databases without Data Guard |
| 7 | `patch_apply`: switch phase `primary` | all | Primaries of a Data Guard configuration, after their standbys |
<!-- markdownlint-restore -->

Each phase runs on the same host list. A database is switched only in the phase that matches its runtime role
(`v$database.database_role` and `v$dataguard_config`); in the other phases it is reported with the phase that
handles it. A host with a standby and a standalone database is therefore no special case. Any failure stops all
hosts (`any_errors_fatal`); `oradba_patch_serial` (default 1) sets how many hosts run in parallel within a phase.

`home_create` needs the download folder on the host. With `-e oradba_patch_stage_from=<download host>` both
`home_create` and `patch_apply` stage it first; the second staging transfers nothing (checksum based copy).

## Inventory

```yaml
# host_vars/db01.example.com.yml (private site inventory)
oradba_patch_databases:
  - DB01H
  - { sid: DB02W, source_home: /u00/app/oracle/product/19.31.0.0 }
oracle_home_switch_listeners: [LISTENER]
# Central network files (OraDBA / TNS_ADMIN outside the homes): nothing to copy
oracle_home_switch_tns_admin: /u00/app/oracle/network/admin
oracle_home_rollback_listeners: [LISTENER]
oracle_home_rollback_tns_admin: /u00/app/oracle/network/admin
```

```bash
ansible-playbook -i inventory oradba.automation.patch_apply -e oradba_patch_profile=19.32 \
  -e oradba_patch_stage_from=dl01.example.com
```

Not covered by the playbooks, do it around them: application stop and start, backup before the window, cron jobs
of the standby (apply and monitoring scripts), Data Guard switchover.

## Per Database

`oracle_home_switch` for one database:

1. State before: home from oratab, role, open mode, invalid objects, last SQL patch.
2. Switch record `logs/home_switch_<SID>.json` (source home, target home, version, autostart flag) - written
   before the deploy, so a failed deploy can be rolled back.
3. Listeners stopped in the source home (`oracle_home_switch_listeners`).
4. `au_run.sh --profile <profile> -config etc/au_patch.cfg -patch -mode deploy` with `AU_SID`, `AU_SOURCE_HOME`,
   `AU_TARGET_HOME`. AutoUpgrade creates the guaranteed restore point, restarts the database from the target home,
   updates oratab and runs datapatch on the primary.
5. Network files copied from `<source home>/network/admin` when there is no central `TNS_ADMIN` (existing files in
   the target home are kept); oratab checked; listeners started from the target home.
6. Standby: managed recovery started when it is not running and the broker is not active.
7. Post checks: open (primary, standalone) or mounted/open (standby); on primaries no invalid component, last SQL
   patch `SUCCESS`, new invalid objects not above `oracle_home_switch_max_new_invalid`.

A database that already runs from the target home is skipped and reported; a second run of the playbook is safe.

## Rollback

```bash
ansible-playbook -i inventory oradba.automation.patch_rollback -e oracle_home_rollback_mode=home
```

<!-- markdownlint-disable MD013 MD060 -->
| Mode | When | What happens | Data |
| --- | --- | --- | --- |
| `restore` | Inside the window, before users work on the patched database | Shutdown from the new home, oratab back with autostart off, flashback to the deploy restore point from the old home, open resetlogs, PDBs open, autostart back on | Changes after the restore point are lost |
| `home` | After the window | Shutdown from the new home, start from the old home, datapatch and utlrp from the old home (primary, standalone), standby apply restarted | Kept |
<!-- markdownlint-restore -->

- The previous home comes from the switch record or from `source_home` in `oradba_patch_databases`.
- Mode `restore` is refused for Data Guard members (the partner would need its own flashback or a reinstate);
  `oracle_home_rollback_allow_restore_with_dg` overrides.
- Rollback order: primaries, databases without Data Guard, standbys (`oradba_rollback_phases`). Check
  MOS 1265700.1 (Standby-First Patch Apply) for your patch before a Data Guard rollback.
- The restore point stays until it is dropped; AutoUpgrade `drop_grp_after_patching` is not set by the collection.
  Drop it after the window, otherwise the fast recovery area fills.

## Known Gaps (v0.2.0)

- Not run against a real database or a Data Guard pair yet.
- AutoUpgrade deploy on a mounted physical standby: behaviour as documented by Oracle, not verified in this
  collection or in the engine (`odb_autoupgrade` `tasks/au_facts.md`: deploy with real SIDs unverified).
- Which files AutoUpgrade deploy copies into the target home (spfile, password file, network files) is unverified;
  the role copies network files itself and leaves the rest to AutoUpgrade.
- No switchover handling; RAC is out of scope.
