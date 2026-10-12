# Changelog

All notable changes to the collection `oradba.automation` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

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
