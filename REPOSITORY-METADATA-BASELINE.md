# Repository metadata baseline

Last reviewed: 2026-10-11

This baseline records organization-wide repository settings that affect where maintainers and users find authoritative information. These are GitHub-hosted settings, so their state must be read from the GitHub API rather than inferred from files in a checkout.

## Documentation source of truth

Wikis are disabled on every AsiBackbone organization repository. Project documentation is maintained in the repositories, reviewed through pull requests, and published on the corresponding documentation sites:

- Learning: <https://asibackbone.github.io/Learning/>
- AsiBackbone: <https://asibackbone.github.io/AsiBackbone/>
- NetCoreApplicationTemplate: <https://asibackbone.github.io/NetCoreApplicationTemplate/>
- Organization landing page: <https://asibackbone.github.io/>

The `.github` repository owns the public organization profile and default community-health files. It does not maintain a separate wiki.

An empty or independently edited wiki would create a second documentation surface outside the established review and publication flow. New or transferred repositories should therefore start with the wiki disabled unless a later, documented decision establishes a distinct need and ownership model.

## Desired state

| Repository | Wiki |
| --- | --- |
| `AsiBackbone/.github` | Disabled |
| `AsiBackbone/asibackbone.github.io` | Disabled |
| `AsiBackbone/AsiBackbone` | Disabled |
| `AsiBackbone/Learning` | Disabled |
| `AsiBackbone/NetCoreApplicationTemplate` | Disabled |

## Verification procedure

The repository-metadata workflow runs weekly and can be dispatched manually. It reads each repository through the GitHub API and fails if a wiki is enabled:

```powershell
./scripts/Test-RepositoryMetadataBaseline.ps1
```

The validator's contract tests do not call GitHub and run on relevant pull requests and pushes:

```powershell
./scripts/Test-RepositoryMetadataBaseline.ps1 -SelfTest
```

Run the live review after creating or transferring a repository and after changing repository features. Add every new organization repository to the validator's default repository list as part of its setup. Record deliberate exceptions here with an owner and review date rather than weakening the expected state silently.
