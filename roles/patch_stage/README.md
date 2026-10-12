# Role patch_stage

Stage a verified download folder on hosts without MOS access.

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Procedure and inventory example: [docs/patch-apply.md](../../docs/patch-apply.md).

## Usage

```yaml
- name: Run patch_stage
  ansible.builtin.include_role:
    name: oradba.automation.patch_stage
```
