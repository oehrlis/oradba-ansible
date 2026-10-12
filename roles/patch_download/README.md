# Role patch_download

Patch download by profile through the odb_autoupgrade engine.

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Conventions: [docs/variables.md](../../docs/variables.md).

## Usage

```yaml
- name: Run patch_download
  ansible.builtin.include_role:
    name: oradba.automation.patch_download
```
