# Changelog

All notable changes to the collection `oradba.automation` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [0.2.0] - 2026-10-12

Patch apply. The switch and rollback roles have **not yet run against a real database**; molecule covers their
logic with stub homes and the engine in dry-run mode. Test them in a lab before a production window.

### Added

- Role `autoupgrade_preflight`: engine, MOS connectivity (optional), download folder, target home, free space and
  per database the state, ARCHIVELOG, `au_home_verify.sh` and `au_run.sh -mode analyze`. All findings are
  collected and reported once.
- Role `patch_stage`: download host -> controller directory -> hosts without MOS access, verified on every target
  with `au_patch_verify.sh`.
- Role `oracle_home_switch`: `au_run.sh -mode deploy` per database, phase filter from the runtime role
  (standby, standalone, primary), listener and network files, standby apply (broker aware), post checks against
  the state before the switch, switch record `logs/home_switch_<SID>.json` written before the deploy.
- Role `oracle_home_rollback`: mode `restore` (flashback to the deploy restore point, refused for Data Guard
  members) or mode `home` (previous home plus datapatch); the mode has no default.
- Shared tasks in role `oradba`: `db_state` (one sqlplus call per database, phase classification) and
  `target_home` (home name from `patches_info.json`, used by `oracle_home_create` too).
- Variables `oradba_patch_databases`, `oradba_patch_target_home`.
- Playbooks `patch_apply` (stage, preflight, standby, standalone, primary with `any_errors_fatal`) and
  `patch_rollback`.
- Molecule: stub homes and four stub databases (standby, primary, standalone, rolled-back case).

## [0.1.0] - 2026-10-12

### Added

- Ansible standard: ansible-lint profile `production` without skips, yamllint, variable naming with role prefixes
  and `oradba_*` conventions, `meta/argument_specs.yml` for every role (`docs/ansible-standard.md`).
- Role `oradba`: OraDBA conventions (layout, user, groups with GIDs, home naming, patch profile) as overridable
  defaults; dependency of every other role.
- Role `oracle_user`: OS groups with fixed GIDs and the software owner; GID mismatch is reported, never changed.
- Role `oracle_layout`: `/u00` software, `/u01` data, `/u02` archive, `ORACLE_BASE`, inventory directory.
- Role `odb_autoupgrade_install`: engine 0.6.0 from the GitHub release pinned by sha256 (offline source
  possible), `autoupgrade.jar` through `au_update_jar.sh`, optional `etc/autoupgrade.env`.
- Role `autoupgrade_keystore`: MOS keystore with `au_keystore.sh --create` using pass files, `--check`.
- Role `patch_download`: `au_run.sh --profile ... -mode download`, MRP resolution, `au_patch_verify.sh`, pin report.
- Role `oracle_home_create`: `au_run.sh -mode create_home`, home name derived from `patches_info.json`, root
  scripts, `au_home_verify.sh`.
- Playbooks `site_setup`, `patch_download`, `home_create`.
- Molecule scenario on Oracle Linux 8 and 9 with the real engine and jar, engine calls in dry-run mode.
- CI (lint, syntax, molecule matrix), release workflow (collection tarball plus sha256), gitleaks.
