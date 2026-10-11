# Organization security baseline

Last reviewed: 2026-10-11

This baseline separates organization defaults from repository-specific controls. It does not infer GitHub-hosted settings from committed workflow files.

## Desired state

New public repositories should inherit these organization defaults:

- dependency graph;
- Dependabot alerts;
- Dependabot security updates;
- secret scanning; and
- secret-scanning push protection.

The `.github` and `asibackbone.github.io` supporting repositories should have the same controls enabled directly. Repositories that contain executable code continue to own their CodeQL mode and workflows.

The supporting repositories also maintain a proportionate source-controlled automation baseline:

- weekly, grouped Dependabot version updates for GitHub Actions;
- dependency review on pull requests;
- weekly and change-triggered zizmor and actionlint analysis of workflow changes; and
- weekly OpenSSF Scorecard analysis with SARIF uploaded to GitHub code scanning.

OWASP Dependency-Check and application-language CodeQL jobs remain with repositories that contain the corresponding package graphs and executable source.

## Verified hosted state

The GitHub organization and repository APIs were checked after configuration on 2026-10-11:

- all five new-public-repository defaults listed above are enabled at the organization level;
- dependency graph/alerts, Dependabot security updates, secret scanning, and push protection are enabled on `.github` and `asibackbone.github.io`;
- the organization-wide 2FA requirement is disabled under the dated exception below; and
- GitHub reports no organization member without 2FA.

These are hosted settings. Their state is verified by the script and is not inferred from this document or from workflow files.

## Repository automation state

The two supporting repositories keep the same GitHub Actions dependency-update schedule and pinned supply-chain scanning actions as the primary repositories. Their local validation scripts require these workflow files and reject action references that are not pinned to a full commit SHA or container digest.

Workflow files establish the intended automation. A committed file is not evidence that a scheduled job has run successfully; confirm current results in each repository's Actions and Security views.

## Identity control and temporary exception

Organization membership should require two-factor authentication. On 2026-10-11, the organization contained one member and GitHub's `members?filter=2fa_disabled` API returned no members. Enforcement is nevertheless deferred until the owner confirms that working recovery methods are stored securely; the API cannot prove recovery readiness.

Review this exception no later than **2026-10-18**:

1. Confirm the owner can sign in with 2FA.
2. Confirm recovery codes are stored offline and at least one independent recovery method is available.
3. Enable the organization two-factor authentication requirement in GitHub's organization authentication-security settings.
4. Run the verification script and confirm the 2FA result changes from `Warning` to `Pass`.

This is a dated blocker, not a claim that organization-wide enforcement is already enabled.

## Verification procedure

An organization owner or security manager should run the following review quarterly, after creating or transferring a repository, and after changing organization security settings:

```powershell
gh auth status
./scripts/Test-OrganizationSecurityBaseline.ps1
```

The script reads settings through the GitHub API, prints one result per control, returns a nonzero exit code for drift, and never reads or prints token values. Use `-Json` for machine-readable evidence. Its contract tests do not call GitHub:

```powershell
./scripts/Test-OrganizationSecurityBaseline.ps1 -SelfTest
```

Record the review date, reviewer, command result, and any exception with an owner and review date. Do not commit API responses that contain unrelated organization or account data.

## Scope and limitations

- The built-in **GitHub recommended** configuration is not attached organization-wide because it enables CodeQL default setup. Learning already uses advanced CodeQL setup, and each executable-code repository owns that choice.
- Application-source CodeQL is not configured for `.github` or `asibackbone.github.io` because they contain no executable application code. Workflow and supply-chain findings from zizmor and OpenSSF Scorecard are uploaded to GitHub code scanning.
- Advanced features that GitHub reports as unavailable for the current plan are recorded as unavailable rather than enabled.
- Signed commits are not required by this baseline.
- Repository rulesets, release environments, publishing credentials, and package controls remain repository-specific.
