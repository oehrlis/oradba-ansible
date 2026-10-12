# Ansible Standard

The rules every role and playbook in `oradba.automation` follows. New roles that move here from `oci-labs` or other
repositories are adapted to this standard before they are merged.

## Lint

- `ansible-lint` with profile `production`, `strict: true`, no `skip_list` and no `warn_list`. A rule that does not
  fit is solved in the code, not by skipping it. Inline `# noqa` needs a comment on the same line that says why.
- `yamllint` with [`.yamllint`](../.yamllint): line length 120, `true`/`false` only, no implicit octal values
  (modes are quoted strings: `mode: "0750"`).
- `markdownlint` with [`.markdownlint.yaml`](../.markdownlint.yaml).
- `make lint` runs all of them plus a version check (`VERSION`, `galaxy.yml` and `CHANGELOG.md` agree).

Difference to the oci-labs `.ansible-lint`: oci-labs skips `var-naming[no-role-prefix]` because a set of variables
there is a contract between Terraform, inventory and one role. Here the rule stays active; the contract variables are
the `oradba_*` variables of the role `oradba` (next section), which satisfy the prefix rule.

## Variable Naming

<!-- markdownlint-disable MD013 MD060 -->
| Kind | Prefix | Defined in | Example |
| --- | --- | --- | --- |
| Convention (cross-role contract) | `oradba_` | `roles/oradba/defaults/main.yml` only | `oradba_oracle_base`, `oradba_oracle_groups` |
| Role input | full role name | `roles/<role>/defaults/main.yml` | `patch_download_profile` |
| Role internal fact or register | full role name | tasks | `patch_download_pin_before` |
| Playbook control | `oradba_` | inventory or `-e` | `oradba_playbook_hosts`, `oradba_download_host` |
<!-- markdownlint-restore -->

Rules:

- A role default that represents a convention reads the `oradba_*` variable instead of repeating its value:
  `oracle_user_name: "{{ oradba_oracle_user }}"`. The value exists once.
- A site overrides the `oradba_*` variable in inventory (`group_vars`). The role variable is overridden only for a
  deviation of that one role.
- Every role depends on `oradba.automation.oradba` in `meta/main.yml`, so the conventions are defined whenever a
  role runs - also with `include_role` and in a playbook that lists one role only.
- Secrets have no default and are marked `no_log: true` in `meta/argument_specs.yml` and on every task that
  handles them. They come from Ansible Vault or a lookup at run time, never from a committed file.
- Secrets reach the engine as pass files (mode 0600 in a 0700 temp directory, removed in an `always` block), never on
  argv and never in `environment:`.

## Role Layout

```text
roles/<role>/
  defaults/main.yml       every input with a default, comment above each variable
  meta/main.yml           galaxy_info, dependency on oradba.automation.oradba
  meta/argument_specs.yml type, description and choices for every default
  tasks/main.yml          entry point; larger parts in tasks/<part>.yml
  templates/              *.j2, only when needed
  README.md               purpose, engine calls, variables, example
```

- Every YAML file starts with the OraDBA header (name, author, date, version, purpose, reference, license).
- Modules by FQCN (`ansible.builtin.command`). The collection uses `ansible.builtin` only; a role that needs
  another collection adds it to `galaxy.yml` `dependencies` in the same change.
- Every task has a name in imperative form. Task names do not repeat the role name.

## Engine Calls

- Roles call the engine CLI with `ansible.builtin.command` and `argv` (no shell, no string splitting), as the
  software owner (`become_user`). Never `autoupgrade.jar` directly (maintenance rule 2).
- Values reach the engine through the caller environment (configuration level 2), not by rendering engine config
  files. The only file the collection renders for the engine is `etc/autoupgrade.env`, and only on request.
- Long runs (download, create_home) use `async` with `poll` and a role variable for the timeout.
- Every engine-mode role offers `<role>_dry_run` that passes the engine `--dry-run`. Molecule uses it.

## Idempotency and Skips

- A second run changes nothing. `changed_when` is set on every `command`; checks report `changed_when: false`.
- "Changed" is derived from the artefact (checksum before and after, file exists), not from parsing engine output.
- A skipped step is reported with its reason and the variable that forces it (`patch_download_force`,
  `autoupgrade_keystore_force`, ...). No silent `when`.
- Destructive operations (recreate keystore, replace a home) need an explicit `*_force` variable; existing
  homes are never removed by a role.

## Testing

- Molecule, Docker driver, scenario `extensions/molecule/default` on `oraclelinux:8` and `oraclelinux:9`.
- The scenario installs the real engine release and the real `autoupgrade.jar`. Keystore, download and create_home
  run in engine dry-run mode: no MOS credentials and no Oracle software in CI. Real downloads and homes are tested
  in `oci-labs`.
- The test sequence includes `idempotence`. `verify.yml` checks the result on the host (GIDs, owner, modes, engine
  version) and renders a create_home config through the engine to check the conventions arrive there.
- CI runs `make ci` (lint, syntax check) and the molecule matrix on every pull request.

## Versioning and Release

- SemVer in `VERSION` and `galaxy.yml`, both equal; `CHANGELOG.md` section per release.
- Release: tag `vX.Y.Z` (pushed together with the branch, `make tag`), the release workflow builds the collection
  tarball plus sha256 and attaches both to the GitHub release.
- Engine version bumps change `odb_autoupgrade_install_version` and `odb_autoupgrade_install_sha256` together; the
  sha256 is taken from the published release asset, not from a local build.
