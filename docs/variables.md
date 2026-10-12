# Variables

The `oradba_*` variables implement the
[OraDBA conventions page](https://github.com/oehrlis/oradba/blob/main/src/doc/conventions.md). They are defined once
in [`roles/oradba/defaults/main.yml`](../roles/oradba/defaults/main.yml); every role reads them. Role-specific
variables are documented in each role README and in its `meta/argument_specs.yml`.

## Conventions

<!-- markdownlint-disable MD013 MD060 -->
| Variable | Default | Conventions page |
| --- | --- | --- |
| `oradba_oracle_root` | `/u00` | Software root `ORACLE_ROOT` |
| `oradba_oracle_data` | `/u01` | Data root `ORACLE_DATA` |
| `oradba_oracle_arch` | `/u02` | Archive root `ORACLE_ARCH` |
| `oradba_oracle_base` | `/u00/app/oracle` | `ORACLE_BASE` |
| `oradba_oracle_inventory` | `/u00/app/oraInventory` | Central inventory |
| `oradba_oradata_dir` | `/u01/oradata` | Datafiles, `<DB_UNIQUE_NAME>` below |
| `oradba_archive_dir` | `/u02/archive` | Archived redo, `<DB_UNIQUE_NAME>` below |
| `oradba_fra_dir` | `/u02/fast_recovery_area` | `db_recovery_file_dest` |
| `oradba_oracle_user` | `oracle` | Software owner |
| `oradba_oracle_uid` | `54321` | UID from the Preinstallation RPM |
| `oradba_oracle_groups` | Preinstallation RPM names and GIDs | OS users and groups |
| `oradba_autoupgrade_base` | `/u00/app/oracle/local/odb_autoupgrade` | Engine install directory (OraDBA extension location) |
| `oradba_oracle_home_prefix` | `product` | Oracle Home naming `${ORACLE_BASE}/product/<version>` |
| `oradba_patch_profile` | `recommended` | Profile shared by download and create_home |
| `oradba_patch_profile_dir` | `<engine>/profiles` | Site profiles (`AU_PROFILE_DIR`) |
<!-- markdownlint-restore -->

Paths derive from each other: changing `oradba_oracle_root` moves `ORACLE_BASE`, the inventory and the engine with
it.

## Groups

`oradba_oracle_groups` maps the seven group roles to a name and a GID:

```yaml
oradba_oracle_groups:
  inventory: { name: oinstall, gid: 54321 }
  osdba: { name: dba, gid: 54322 }
  osoper: { name: oper, gid: 54323 }
  osbackupdba: { name: backupdba, gid: 54324 }
  osdgdba: { name: dgdba, gid: 54325 }
  oskmdba: { name: kmdba, gid: 54326 }
  osracdba: { name: racdba, gid: 54330 }
```

Ansible does not merge dictionaries across precedence levels: an override replaces the whole dictionary, so a site
always lists all seven roles. The role `oradba` asserts that every role is present with a numeric GID.

Site variant with `os*` names - the GIDs are site data and belong in the private inventory, not here:

```yaml
# group_vars/all.yml of a private site inventory
oradba_oracle_groups:
  inventory: { name: oinstall, gid: <site gid> }
  osdba: { name: osdba, gid: <site gid> }
  osoper: { name: osoper, gid: <site gid> }
  osbackupdba: { name: osbackupdba, gid: <site gid> }
  osdgdba: { name: osdgdba, gid: <site gid> }
  oskmdba: { name: oskmdba, gid: <site gid> }
  osracdba: { name: osracdba, gid: <site gid> }
```

The engine uses only the names (`AU_GROUP_*`); `oracle_home_create` passes them when there is no source home.

## Playbook Control

<!-- markdownlint-disable MD013 MD060 -->
| Variable | Default | Effect |
| --- | --- | --- |
| `oradba_playbook_hosts` | `all` | Host pattern of the collection playbooks |
| `oradba_download_host` | `false` | Host holds the MOS keystore and downloads patches |
<!-- markdownlint-restore -->

## Secrets

<!-- markdownlint-disable MD013 MD060 -->
| Variable | Used by | Source |
| --- | --- | --- |
| `autoupgrade_keystore_mos_user` | `autoupgrade_keystore` | inventory of the download host (not secret, but personal) |
| `autoupgrade_keystore_mos_password` | `autoupgrade_keystore` | Vault or lookup |
| `autoupgrade_keystore_password` | `autoupgrade_keystore` | Vault or lookup |
<!-- markdownlint-restore -->

Example with the 1Password lookup of `community.general` (the `op` CLI must be signed in on the controller):

```yaml
autoupgrade_keystore_mos_password: "{{ lookup('community.general.onepassword', 'MOS', field='password') }}"
autoupgrade_keystore_password: "{{ lookup('community.general.onepassword', 'AutoUpgrade Keystore', field='password') }}"
```
