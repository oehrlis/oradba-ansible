# Role oracle_layout

OraDBA filesystem layout (u00 software, u01 data, u02 archive).

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Conventions: [docs/variables.md](../../docs/variables.md).

## Usage

```yaml
- name: Run oracle_layout
  ansible.builtin.include_role:
    name: oradba.automation.oracle_layout
```
