# Supporting repository governance

Last reviewed: 2026-10-11

The organization profile and landing-page repositories use a proportionate solo-maintainer ruleset. These hosted controls preserve an auditable pull-request record without inventing an approval requirement that the sole maintainer cannot satisfy.

## Protected repositories

| Repository | Required check | Content protected |
| --- | --- | --- |
| `AsiBackbone/.github` | `Validate organization profile` | Public organization profile |
| `AsiBackbone/asibackbone.github.io` | `Validate landing site` | Domain-root landing page, `robots.txt`, and sitemap index |

Both `main` branches require:

- changes through pull requests;
- resolved review conversations;
- zero approving reviews, matching the current solo-maintainer posture;
- linear history and squash merges only;
- the repository-specific check above on the latest commit;
- protection against force pushes; and
- protection against branch deletion.

Repository settings allow squash merge, disable merge commits and rebase merges, and delete source branches after merge.

## Recovery and bypass posture

The organization owner has a ruleset bypass restricted to `pull_request` mode. It exists only to recover a broken organization profile, Pages deployment, or required-check configuration. Recovery still starts from a branch and retains a pull request and merge record; there is no silent direct-push bypass.

Do not use the bypass for ordinary failed checks. Fix or deliberately revise the relevant check instead.

## Verification

After changing either ruleset:

1. Read the repository merge settings and full ruleset through the GitHub API.
2. Confirm the ruleset targets only `refs/heads/main` and is active.
3. Confirm deletion, non-fast-forward updates, and non-linear history are blocked.
4. Confirm pull requests require conversation resolution but no approving review.
5. Confirm the only allowed merge method is squash.
6. Confirm the expected repository-specific status check is strict and required.
7. Open a test pull request, allow the check to pass, and merge normally without using bypass.

The implementation pull requests and final ruleset identifiers are recorded here after live verification.
