# asibackbone.github.io

Organization landing page and `robots.txt` for the AsiBackbone GitHub Pages sites, served at <https://asibackbone.github.io/>.

## Contents

| File | Purpose |
| --- | --- |
| `index.html` | Organization landing page linking the four projects, their documentation sites, available archived DOIs, current releases, community routes, organization search, and the organization funding destination |
| `search/` | Organization-wide documentation search that combines the published indexes from Learning, Framework, Template, and Reference |
| `robots.txt` | Crawler rules and `Sitemap:` lines. Crawlers only read `robots.txt` at the domain root, so this is the one place that can advertise the project sites' sitemaps |
| `sitemap.xml` | Sitemap index for the organization and project sites |
| `site-sitemap.xml` | Sitemap for the organization landing page and organization search |
| `images/` | Icon, favicon, and social preview image shared with the Learning site |
| `.nojekyll` | Serves the files as-is, without a Jekyll build |
| `OUTREACH-PLAN.md` | Maintainer-owned audience, publication, community-participation, and measurement plan |
| `REPOSITORY-METADATA-BASELINE.md` | Organization-wide repository metadata expectations and review procedure |
| `PUBLICATION-INTEGRITY.md` | GitHub Pages publication-integrity assessment and the deferred Sigstore signing decision |
| `DOCUMENTATION-CURRENCY-REVIEW.md` | Dated inventory of this repository's documentation, its version references, and the findings of the most recent currency review |
| `scripts/` | Validation scripts run by the workflows; each script's header describes its contract |

Organization identity, new-repository defaults, supporting-repository controls, and the periodic verification procedure are documented in [SECURITY-BASELINE.md](SECURITY-BASELINE.md).

Repository metadata that affects documentation routing, including the organization-wide wiki policy, is documented in [REPOSITORY-METADATA-BASELINE.md](REPOSITORY-METADATA-BASELINE.md).

GitHub Actions dependencies are maintained by Dependabot and reviewed by dependency-review, CodeQL, zizmor, actionlint, and OpenSSF Scorecard workflows using immutable action pins.

Pull-request flow, required checks, merge behavior, and the recovery-only bypass are documented in [REPOSITORY-GOVERNANCE.md](REPOSITORY-GOVERNANCE.md).

Organization-wide outreach, its initial 90-day calendar, and the reusable publication checklist are documented in [OUTREACH-PLAN.md](OUTREACH-PLAN.md).

## Relationship to the project sites

The project repositories publish their own sites under this domain:

- <https://asibackbone.github.io/Learning/>
- <https://asibackbone.github.io/AsiBackbone/>
- <https://asibackbone.github.io/NetCoreApplicationTemplate/>
- <https://asibackbone.github.io/ReferenceApplication/>

This repository must not contain folders named `Learning`, `AsiBackbone`, `NetCoreApplicationTemplate`, or `ReferenceApplication`, because those paths belong to the project sites.

When a project site starts publishing a sitemap, add its `Sitemap:` line to `robots.txt`.

## Current releases

The landing page's **Current releases** section shows each project's current stable release, the integration combination that was reviewed together, and Learning's teaching baseline. Its contents are generated from the organization [compatibility manifest](https://github.com/AsiBackbone/.github/blob/main/compatibility/ecosystem-compatibility.json) and must not be edited by hand; this repository keeps no version numbers of its own. The [compatibility matrix](https://github.com/AsiBackbone/.github/blob/main/compatibility/README.md) remains the owner of that information and explains which combinations were reviewed.

After the matrix changes, regenerate and commit the section:

```powershell
./scripts/Test-ReleaseSummary.ps1 -Update
```

Use `-ManifestPath` to read a local clone of `AsiBackbone/.github` instead of downloading the manifest from its `main` branch. Landing-site validation fails while `index.html` differs from the manifest, including on its weekly scheduled run, and the published-site verification workflow checks the live page after each site change.

A current release is not a statement that it was reviewed with the other projects' current releases, and Learning's reviewed teaching pins are not upgrade instructions. Deeper pages in this repository link the matrix instead of naming versions.

## Publishing

GitHub Pages deploys the `main` branch root. Changes are live a minute or two after they reach `main`.

The site is not signed. This repository distributes no downloadable artifact, so Sigstore signing is deferred. [PUBLICATION-INTEGRITY.md](PUBLICATION-INTEGRITY.md) records the publication controls, the threat model, the revisit triggers, and `scripts/Test-PublishedSiteParity.ps1`, which checks that the live site serves the committed bytes.

## Licensing

Landing-page prose, descriptive metadata, and the listed image assets are licensed under CC BY 4.0. Site implementation, scripts, workflows, and repository configuration are licensed under MIT. See [LICENSES.md](LICENSES.md), [LICENSE](LICENSE), [LICENSE-CODE](LICENSE-CODE), and [ASSETS-LICENSES.md](ASSETS-LICENSES.md) for the complete boundary and trademark notice.
