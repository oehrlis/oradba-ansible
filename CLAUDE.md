# CLAUDE.md - oradba-ansible

## Project

Ansible collection `oradba.automation`: the only Ansible code of the OraDBA tooling. Roles call the odb_autoupgrade
engine CLI, never `autoupgrade.jar`. Conventions come from the oradba conventions page via the role `oradba`.

## Role in the lab architecture

The only Ansible code of the OraDBA tooling: collection `oradba.automation` for VM and OCI hosts.

- Is: roles and playbooks that configure Linux hosts (OS user, layout, Oracle Homes) by calling
  [odb_autoupgrade](https://github.com/oehrlis/odb_autoupgrade) for home creation and patching.
- Is not: a container tool - Ansible never runs inside containers (images are built by oradba-docker, planned).
  No lab content and no Terraform.
- Consumers pin the collection version (`requirements.yml`): oci-labs (host provisioning, from M5), the patch
  test catalogue and oradba-labs for `TARGET=oci`.
- Neighbours: oci-labs (creates the hosts), odb_autoupgrade (home engine), oradba (runtime and conventions),
  oradba-labs (lab catalogue). `ansible/roles` from oci-labs move here (M4).

See the [lab architecture overview](https://github.com/oehrlis/oradba-labs/blob/main/docs/architecture.md).

## Quick Reference

- Setup: `make setup` (.venv, links the collection into .collections)
- Lint: `make lint` (version, yamllint, ansible-lint production, markdownlint)
- Test: `make molecule` (Docker, OL8 and OL9)
- Release: bump `VERSION` and `galaxy.yml`, CHANGELOG section, `make tag`
- Standard: `docs/ansible-standard.md`; ownership rules in `README.md`
- Secrets: 1Password via `op read` or the community.general lookup, never committed

## Rules

- No `skip_list` in `.ansible-lint`; fix the code instead
- Keep `meta/argument_specs.yml` in step with `defaults/main.yml`
- Engine version bump: version and sha256 of the published asset together
