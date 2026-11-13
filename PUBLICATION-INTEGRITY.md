# Publication integrity and Sigstore applicability

Last reviewed: 2026-11-12 (issue #35)

**Decision:** Deferred

This repository publishes the static organization landing page, the cross-project search page, the crawler files, and
their images through GitHub Pages. It distributes no versioned downloadable artifact, so Sigstore keyless signing is
**not implemented**. Branch, deployment, and validation controls remain the publication-integrity boundary. Signing
ordinary web pages would add a pipeline whose signatures no browser or reader checks, and it would not protect what a
visitor actually receives.

GitHub Pages does **not** sign the files it serves, and GitHub build-provenance attestations do not cover a Pages
branch build. Nothing on this site should be described as signed or attested.

Organization-wide signing policy, the trust claims shared by every repository, and the status of each product's signing
work are owned by the
[Sigstore release-signing trust and verification policy](https://github.com/AsiBackbone/.github/blob/main/assurance/SIGSTORE.md)
in `AsiBackbone/.github`. This document covers only this repository's publication; it does not own or describe the
release signatures of the four project repositories.

## Inventory

Checked against the repository, the GitHub API, and the live site on 2026-11-12.

| Item | Current state |
| --- | --- |
| Publication source | GitHub Pages **branch build** (`build_type: legacy`) from `main` at `/`. `.nojekyll` disables Jekyll, so committed files are served unchanged. The deployment is GitHub's own `pages-build-deployment`; no workflow in this repository deploys the site. |
| Deployment environment | `github-pages`, with a deployment-branch policy that allows only `main`. |
| Branch protection | The `Main branch security baseline` ruleset (`eng/repository-controls/main-branch-ruleset.json`) blocks deletion and force pushes, and requires pull requests, linear history, and the strict landing-site validation check. One user bypass actor exists under the solo-maintainer tradeoff in `REPOSITORY-GOVERNANCE.md`. |
| Write access | One repository administrator. No deploy keys or publishing credentials are used. |
| Workflow permissions | Workflows default to `permissions: {}` or read-only. Write scopes are limited to `security-events: write` for code-scanning uploads, and `id-token: write` only in the OpenSSF Scorecard job, which needs it to publish results. No workflow has `contents: write` or `pages: write`. Every action is pinned to a full commit SHA, which `scripts/Test-LandingSite.ps1` enforces. |
| Served files | `index.html`, `search/index.html`, `search/search.js`, `search/search.css`, `robots.txt`, `sitemap.xml`, `site-sitemap.xml`, three images under `images/`, and the repository's Markdown and license files, served as plain text. Image SHA-256 values are recorded in `ASSETS-LICENSES.md` and checked by the landing-site validation. |
| Downloadable artifacts | **None.** There are no GitHub Releases, archives, packages, binaries, installers, or PDFs. |
| Live parity | On 2026-11-12 the latest Pages build was from the current `main` commit, and every served site file above matched its committed bytes (SHA-256). |
| Third-party code | None. The pages load no external scripts, styles, or fonts. Search fetches each project's `index.json` from the same origin and renders results with `textContent`. |

## Threat model

| Threat | Control today | Would Sigstore signing help? |
| --- | --- | --- |
| Unreviewed change reaches the site | Pages publishes only `main`; the ruleset requires a pull request and the validation check; the environment allows only `main`. | No. Signing happens after the content is chosen, so it cannot stop a bad change from being merged. |
| Compromised CI workflow alters the site | No workflow can write contents or deploy Pages; actions are SHA-pinned and checked by CodeQL, zizmor, and actionlint. | No. There is no CI publication step to sign. |
| Maintainer account compromise | Organization security baseline and 2FA controls (`SECURITY-BASELINE.md`). | No. A compromised maintainer could change the content before any signing step. |
| Tampering in transit | HTTPS is enforced, with HSTS, on GitHub's Pages and CDN infrastructure. | No. Browsers do not verify Sigstore signatures. |
| Hosting serves something other than `main` | Live content can be compared with the committed bytes (see below). | Only in theory. A reader would have to download and verify each page manually, which nobody does for a landing page. |
| Shared origin with project sites | All five sites are served from `https://asibackbone.github.io`, so a compromised project documentation site can run script on this origin. Each owning repository protects its own publication. | No. This is a hosting-origin boundary, not an artifact-integrity problem. A separate origin per project would be the relevant change. |

**Conclusion:** signing would cover none of the paths that can actually change what visitors see. Retain the existing
controls.

## Checking live publication

To confirm that GitHub Pages serves the reviewed `main` commit:

```powershell
./scripts/Test-PublishedSiteParity.ps1
```

The script downloads every served site file and fails if any differs from the committed bytes at `origin/main`. It
assumes that GitHub's HTTPS endpoint and the repository's `main` branch are trusted. It is a monitoring check, not a
signature, and a mismatch shortly after a merge can simply mean that Pages has not finished deploying. It is not part
of pull-request validation because it depends on the network and on deployment timing.

## Fail-closed guard

`scripts/Test-LandingSite.ps1` fails if:

- this document no longer records a `**Decision:**` of `Deferred`; or
- the repository contains a downloadable artifact type (archive, package, binary, installer, disk image, or PDF).

Publishing such a file therefore requires revisiting this decision first.

## Revisit triggers

Reassess, and implement signing if justified, when any of these happens:

1. this repository publishes a GitHub Release, archive, package, binary, installer, PDF, or other file meant to be
   downloaded and kept;
2. a workflow in this repository starts building or deploying the site (for example a Pages Actions deployment), which
   creates a CI publication step whose output could be attested;
3. the site starts serving third-party or generated executable code;
4. organization policy in `AsiBackbone/.github` requires signed provenance for static sites; or
5. browsers or GitHub Pages gain native verification of signed site content.

If signing is implemented, it must follow the organization policy: sign the exact published bytes from a protected
workflow with SHA-pinned actions and `id-token: write` only on the signing job; publish durable `*.sigstore.json`
bundles beside the subjects; verify them against the pinned issuer and workflow identity; and make validation fail on
missing or mismatched bundles, with a negative test. No signing credentials or runtime Sigstore dependency are needed
for the current static site.
