# Role autoupgrade_preflight

Patch preflight checks through the odb_autoupgrade engine (analyze mode).

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Procedure and inventory example: [docs/patch-apply.md](../../docs/patch-apply.md).

## Usage

```yaml
- name: Run autoupgrade_preflight
  ansible.builtin.include_role:
    name: oradba.automation.autoupgrade_preflight
```
