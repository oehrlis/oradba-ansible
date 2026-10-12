# Role oracle_home_create

Out-of-place Oracle Home creation through the odb_autoupgrade engine.

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Conventions: [docs/variables.md](../../docs/variables.md).

## Usage

```yaml
- name: Run oracle_home_create
  ansible.builtin.include_role:
    name: oradba.automation.oracle_home_create
```
