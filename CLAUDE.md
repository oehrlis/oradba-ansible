# CLAUDE.md - oradba-ansible

## Project

Ansible collection `oradba.automation`: the only Ansible code of the OraDBA tooling. Roles call the odb_autoupgrade
engine CLI, never `autoupgrade.jar`. Conventions come from the oradba conventions page via the role `oradba`.

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
