# Role oracle_user

Oracle OS groups with fixed GIDs and the software owner.

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Conventions: [docs/variables.md](../../docs/variables.md).

## Usage

```yaml
- name: Run oracle_user
  ansible.builtin.include_role:
    name: oradba.automation.oracle_user
```
