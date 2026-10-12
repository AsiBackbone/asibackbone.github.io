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
- CodeQL analysis of GitHub Actions workflows on every pull request, every push
  to `main`, and a weekly schedule;
- weekly and change-triggered zizmor and actionlint analysis of workflow changes; and
- weekly OpenSSF Scorecard analysis with SARIF uploaded to GitHub code scanning.

OWASP Dependency-Check and application-language CodeQL jobs remain with
repositories that contain the corresponding package graphs and executable
source.

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

## OpenSSF Scorecard finding disposition

### Triage policy

Scorecard remains enabled because its findings are useful prompts, but a high
SARIF severity does not by itself establish that a control applies to every
repository. For static content and organization-support repositories:

1. Remediate findings that identify a control missing from the repository's
   actual source, workflow, or publishing surface.
2. Dismiss an accurately detected but non-applicable or deliberately accepted
   finding as `won't fix`, with a comment that names the verified repository
   scope, compensating controls, and the condition that requires reconsideration.
3. Reserve `false positive` for a finding whose underlying observation is
   factually incorrect. Do not use it merely because the recommended control is
   disproportionate.
4. Let a fresh Scorecard analysis close remediated findings when practical. If
   rolling history still describes pre-remediation commits, record that evidence
   in the dismissal comment.
5. Recheck the repository scope whenever executable code, a distributable
   artifact, an untrusted-input surface, or another active maintainer is added.

The `Maintained` check is a special age gate: Scorecard cannot assess a repository
until it is more than 90 days old and explicitly says there is no remediation for
the resulting low score. An age-only alert may therefore be dismissed as
`won't fix` after confirming that the repository is not archived and has recent
activity. It is not a `false positive`, because Scorecard correctly observed the
repository age. Review the check again after the eligibility date and treat any
later inactivity finding as a new maintenance signal.

### 2026-10-12 triage record

The live code-scanning API was reviewed for every alert named in issue #17. The
SAST findings were remediated with CodeQL for GitHub Actions. Fuzzing and
CII-Best-Practices do not apply to the supporting repositories' current static
scope. The CI-Tests finding described pre-validation history. Branch-Protection
and Code-Review remain documented solo-maintainer tradeoffs. Each of those
findings is resolved with its repository-specific evidence in the GitHub alert.

The only remaining findings were age-only `Maintained` alerts. Before dismissal,
the API confirmed that all three repositories were unarchived and had activity
on 2026-10-12. Their 90-day eligibility dates are:

| Repository | Alert | Eligible for assessment |
| --- | --- | --- |
| `.github` | #4 | 2026-11-09 |
| `Learning` | #5 | 2026-11-10 |
| `asibackbone.github.io` | #5 | 2026-12-26 |

Review each result on or after its eligibility date. An alert that then reports
insufficient activity requires maintenance triage rather than an automatic
dismissal.

### Repository-specific controls

The supporting repositories apply Scorecard findings according to their actual
scope rather than treating every heuristic as a universal requirement:

- CodeQL analyzes GitHub Actions workflows on every pull request and push to
  `main`. This is the supported SAST surface in repositories without application
  source.
- The landing-site validation workflow runs on every pull request and push to
  `main`. A CI-tests warning can temporarily reflect historical pull requests
  from before that workflow existed rather than a current coverage gap.
- Fuzzing is not adopted because this static landing repository has no service,
  library, parser, or untrusted runtime input surface. Reconsider this decision
  if executable application or request-handling code is added.
- The branch-protection and code-review findings reflect the documented
  solo-maintainer tradeoff in `REPOSITORY-GOVERNANCE.md`. The active ruleset
  still blocks deletion and force pushes and requires pull requests, resolved
  conversations, linear history, and the strict landing-site validation check.
  Reconsider required approvals and Code Owner review when an independent active
  maintainer is available.

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
- Application-language CodeQL is not configured for `.github` or
  `asibackbone.github.io` because they contain no executable application code.
  Their GitHub Actions workflows are analyzed with CodeQL, while workflow and
  supply-chain findings from zizmor and OpenSSF Scorecard are also uploaded to
  GitHub code scanning.
- Advanced features that GitHub reports as unavailable for the current plan are recorded as unavailable rather than enabled.
- Signed commits are not required by this baseline.
- Repository rulesets, release environments, publishing credentials, and package controls remain repository-specific.
