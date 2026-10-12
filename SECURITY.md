# Security Policy

## Supported Versions

Security fixes are applied to the latest release only.

## Reporting a Vulnerability

Please do not report security vulnerabilities through public GitHub issues. Report them by email to
<stefan.oehrli@oradba.ch> with a description, steps to reproduce and the affected version. You receive an
acknowledgement within 48 hours and a status update within 7 days.

## Scope

- Roles, playbooks and templates of the collection `oradba.automation`
- Handling of secrets (MOS credentials, keystore password) by the role `autoupgrade_keystore`

Out of scope: the odb_autoupgrade engine (report in its repository), Oracle AutoUpgrade and Oracle software.

## Rules for Contributions

- No site data in this repository: no inventories, GIDs of real sites, PAR URLs, tenancy names or credentials.
- Secrets reach the engine only through pass files; never on argv, in `environment:` or in a committed file.
