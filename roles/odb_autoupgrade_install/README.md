# Role odb_autoupgrade_install

odb_autoupgrade engine from a pinned release, autoupgrade.jar through the engine.

Variables with type and description: [`meta/argument_specs.yml`](meta/argument_specs.yml); defaults:
[`defaults/main.yml`](defaults/main.yml). Conventions: [docs/variables.md](../../docs/variables.md).

## Usage

```yaml
- name: Run odb_autoupgrade_install
  ansible.builtin.include_role:
    name: oradba.automation.odb_autoupgrade_install
```
