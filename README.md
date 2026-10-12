# oradba-ansible - Collection oradba.automation

Ansible roles and playbooks for Oracle Database software on Linux: OS groups and user, filesystem layout, the
[odb_autoupgrade](https://github.com/oehrlis/odb_autoupgrade) engine, the MOS keystore, patch download and
out-of-place Oracle Home creation.

The collection is a thin layer. Oracle AutoUpgrade is called only by the odb_autoupgrade engine; every role calls
the engine CLI (`au_run.sh`, `au_keystore.sh`, `au_update_jar.sh`, ...), never `autoupgrade.jar`. The conventions
(groups, GIDs, layout, home naming) come from the
[OraDBA conventions page](https://github.com/oehrlis/oradba/blob/main/src/doc/conventions.md) and are implemented
once, as overridable defaults, in the role `oradba`.

## Requirements

- ansible-core 2.16 or later on the controller
- Oracle Linux 8 or 9 (or RHEL) on the managed nodes, Python 3.8 or later there (OL8: `python3.11`)
- No collection dependencies at run time; `community.general` only if you use its 1Password lookup for secrets

## Installation

From a GitHub release (tarball plus sha256, pinned in `requirements.yml`):

```yaml
# requirements.yml
collections:
  - name: https://github.com/oehrlis/oradba-ansible/releases/download/v0.2.0/oradba-automation-0.2.0.tar.gz
    type: url
```

```bash
curl -sLO https://github.com/oehrlis/oradba-ansible/releases/download/v0.2.0/oradba-automation-0.2.0.tar.gz.sha256
curl -sLO https://github.com/oehrlis/oradba-ansible/releases/download/v0.2.0/oradba-automation-0.2.0.tar.gz
shasum -a 256 -c oradba-automation-0.2.0.tar.gz.sha256
ansible-galaxy collection install oradba-automation-0.2.0.tar.gz
```

Galaxy publication is planned later.

## Roles

<!-- markdownlint-disable MD013 MD060 -->
| Role | Purpose | Engine call |
| --- | --- | --- |
| [`oradba`](roles/oradba/README.md) | Conventions as `oradba_*` defaults; dependency of every role | - |
| [`oracle_user`](roles/oracle_user/README.md) | OS groups with fixed GIDs, software owner | - |
| [`oracle_layout`](roles/oracle_layout/README.md) | `/u00` software, `/u01` data, `/u02` archive, `ORACLE_BASE`, inventory directory | - |
| [`odb_autoupgrade_install`](roles/odb_autoupgrade_install/README.md) | Engine release pinned by sha256, `autoupgrade.jar`, site settings | `au_update_jar.sh`, `au_run.sh -version` |
| [`autoupgrade_keystore`](roles/autoupgrade_keystore/README.md) | MOS keystore on a download host | `au_keystore.sh --create`, `--check` |
| [`patch_download`](roles/patch_download/README.md) | Download a patch set by profile, verify, report the pin | `au_run.sh -mode download`, `au_patch_pin.sh`, `au_patch_verify.sh` |
| [`oracle_home_create`](roles/oracle_home_create/README.md) | New Oracle Home out of place, root scripts, verification | `au_run.sh -mode create_home`, `au_home_verify.sh` |
| [`autoupgrade_preflight`](roles/autoupgrade_preflight/README.md) | Checks before a switch, all findings in one report | `au_run.sh -mode analyze`, `au_patch_verify.sh`, `au_home_verify.sh` |
| [`patch_stage`](roles/patch_stage/README.md) | Download folder to hosts without MOS access | `au_patch_verify.sh` |
| [`oracle_home_switch`](roles/oracle_home_switch/README.md) | Databases to the new home in Data Guard order (untested on a real DB) | `au_run.sh -mode deploy` |
| [`oracle_home_rollback`](roles/oracle_home_rollback/README.md) | Back to the previous home: restore point or home switch (untested on a real DB) | - (SQL*Plus, datapatch) |
<!-- markdownlint-restore -->

Planned roles (from the decomposition of the oci-labs `db19_engineering` role): `os_prereq`, `db_create`,
`oradba_install`. Patch apply procedure: [docs/patch-apply.md](docs/patch-apply.md).

## Playbooks

```bash
ansible-playbook -i inventory oradba.automation.site_setup
ansible-playbook -i inventory oradba.automation.patch_download -e oradba_patch_profile=19.32
ansible-playbook -i inventory oradba.automation.home_create -e oradba_patch_profile=19.32
ansible-playbook -i inventory oradba.automation.patch_apply -e oradba_patch_profile=19.32
ansible-playbook -i inventory oradba.automation.patch_rollback -e oracle_home_rollback_mode=home
```

<!-- markdownlint-disable MD013 MD060 -->
| Playbook | Content |
| --- | --- |
| `site_setup` | `oracle_user`, `oracle_layout`, `odb_autoupgrade_install`; `autoupgrade_keystore` on hosts with `oradba_download_host: true` |
| `patch_download` | `patch_download` on download hosts |
| `home_create` | `oracle_home_create` |
| `patch_apply` | `patch_stage` (optional), `autoupgrade_preflight`, `oracle_home_switch` per phase: standby, standalone, primary |
| `patch_rollback` | `oracle_home_rollback` per phase: primary, standalone, standby; mode required |
<!-- markdownlint-restore -->

All playbooks target `oradba_playbook_hosts` (default `all`). An example inventory is in
[`examples/inventory`](examples/inventory/).

## Ownership and Maintenance Rules

This repository is the only place for Ansible code in the OraDBA tooling. The rules that keep it that way:

1. One owner per concern. Consumers use a released, pinned version (tag plus sha256) and never copy code.
2. AutoUpgrade is called only by `odb_autoupgrade`. Roles and Dockerfiles call the engine CLI, not `autoupgrade.jar`.
3. Ansible lives only in `oradba-ansible`. Consumer repos keep inventories, variables and thin scenario playbooks.
4. Conventions (group names, GIDs, home naming, `ORACLE_BASE`, data directory, inventory) are defined once on the
   conventions page in `oradba`; engine and collection implement them as overridable defaults.
5. Profile format belongs to `odb_autoupgrade`; profile content belongs to the consumer (site, lab,
   `cpu-patch-tests`).
6. Shell engines must work without OraDBA and without Ansible; Ansible is an optional layer, never a requirement.
7. A consumer that needs a change opens an issue in the owner repository; no local patches of vendored code.
8. Public repositories contain no site data: inventories, profiles with customer values, PAR URLs and tenancy
   names stay in private repositories or site configuration.

<!-- markdownlint-disable MD013 MD060 -->
| Repository | Role towards this collection |
| --- | --- |
| [`odb_autoupgrade`](https://github.com/oehrlis/odb_autoupgrade) | Engine; installed by `odb_autoupgrade_install` at a pinned release |
| [`oradba`](https://github.com/oehrlis/oradba) | Conventions page; environment and homes registry |
| `oci-labs` | Consumer: inventory and lab scenarios that call these playbooks |
| `oracle-database-docker-legacy` | Calls the engine standalone, not this collection |
| `cpu-patch-tests` (private) | Monthly patch profiles, consumed through `patch_download_profiles` |
<!-- markdownlint-restore -->

## Documentation

- [Ansible standard](docs/ansible-standard.md) - lint profile, variable naming, role layout, testing
- [Variables](docs/variables.md) - the `oradba_*` conventions and how to override them
- [CHANGELOG](CHANGELOG.md)

## Development

```bash
make setup      # .venv with ansible-core, ansible-lint, molecule, yamllint
make lint       # version check, yamllint, ansible-lint (production), markdownlint
make molecule   # Oracle Linux 8 and 9 containers (Docker)
make help
```

## License

Apache License 2.0, see [LICENSE](LICENSE).
