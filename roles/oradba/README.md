# Role oradba

OraDBA conventions (layout, user, groups, home naming) as overridable defaults.

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Conventions: [docs/variables.md](../../docs/variables.md).

## Usage

```yaml
- name: Run oradba
  ansible.builtin.include_role:
    name: oradba.automation.oradba
```
