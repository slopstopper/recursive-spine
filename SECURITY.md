# Security

recursive-spine is a Claude Code plugin: markdown skills plus a small
shell script run by CI. It runs no service, stores no credentials, and
its skills operate through the `gh` CLI with whatever permissions your
own token carries.

If you believe you've found a security issue — for example, a way a
skill could be induced to leak private repo state or execute untrusted
input — please use GitHub's private vulnerability reporting on this
repository rather than filing a public issue. If that's unavailable,
contact the maintainer via their GitHub profile.

Please don't open public issues for suspected vulnerabilities until
they've been triaged.
