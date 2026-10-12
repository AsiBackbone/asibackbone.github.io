# Repository metadata baseline

Last reviewed: 2026-10-12

This baseline records organization-wide repository settings that affect where maintainers and users find authoritative information. These are GitHub-hosted settings, so their state must be read from the GitHub API rather than inferred from files in a checkout.

## Documentation source of truth

Wikis are disabled on every AsiBackbone organization repository. Project documentation is maintained in the repositories, reviewed through pull requests, and published on the corresponding documentation sites:

- Learning: <https://asibackbone.github.io/Learning/>
- AsiBackbone: <https://asibackbone.github.io/AsiBackbone/>
- NetCoreApplicationTemplate: <https://asibackbone.github.io/NetCoreApplicationTemplate/>
- Organization landing page: <https://asibackbone.github.io/>

The `.github` repository owns the public organization profile and default community-health files. It does not maintain a separate wiki.

An empty or independently edited wiki would create a second documentation surface outside the established review and publication flow. New or transferred repositories should therefore start with the wiki disabled unless a later, documented decision establishes a distinct need and ownership model.

## Community conversation source of truth

[AsiBackbone organization Discussions](https://github.com/orgs/AsiBackbone/discussions), backed by the `.github` repository, is the single public surface for questions, ideas, architecture, integration, and community examples. Project-specific posts identify the affected repository and version; reproducible defects and focused work remain in the owning repository's issue tracker. Suspected vulnerabilities remain private and follow the affected repository's security policy.

Repository-specific Discussions are disabled to avoid splitting questions and proposals across parallel surfaces. Support files, contribution guidance, README community links, package guidance, and issue-form contact links route users to the organization surface. Existing welcome posts were preserved as [Learning community discussions](https://github.com/orgs/AsiBackbone/discussions/12) and [AsiBackbone package community discussions](https://github.com/orgs/AsiBackbone/discussions/13) before their repository Discussions were disabled. No NetCoreApplicationTemplate discussion required migration.

## Desired state

| Repository | Wiki | Discussions |
| --- | --- | --- |
| `AsiBackbone/.github` | Disabled | Enabled (organization source) |
| `AsiBackbone/asibackbone.github.io` | Disabled | Disabled |
| `AsiBackbone/AsiBackbone` | Disabled | Disabled |
| `AsiBackbone/Learning` | Disabled | Disabled |
| `AsiBackbone/NetCoreApplicationTemplate` | Disabled | Disabled |

## Verification procedure

The repository-metadata workflow runs weekly and can be dispatched manually. It reads each repository through the GitHub API and fails if a wiki is enabled or if Discussions is not enabled exclusively on `.github`:

```powershell
./scripts/Test-RepositoryMetadataBaseline.ps1
```

The validator's contract tests do not call GitHub and run on relevant pull requests and pushes:

```powershell
./scripts/Test-RepositoryMetadataBaseline.ps1 -SelfTest
```

Run the live review after creating or transferring a repository and after changing repository features. Add every new organization repository to the validator's default repository list as part of its setup. Record deliberate exceptions here with an owner and review date rather than weakening the expected state silently.
