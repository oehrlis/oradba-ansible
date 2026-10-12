# Role oracle_home_switch

Move databases out of place to a new Oracle Home with the engine deploy mode.

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Procedure and inventory example: [docs/patch-apply.md](../../docs/patch-apply.md).

> Not yet run against a real database (v0.2.0) - test in a lab before a production window.

## Usage

```yaml
- name: Run oracle_home_switch
  ansible.builtin.include_role:
    name: oradba.automation.oracle_home_switch
  vars:
    oracle_home_switch_phase: standby
```
