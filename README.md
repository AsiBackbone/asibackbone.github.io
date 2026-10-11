# asibackbone.github.io

Organization landing page and `robots.txt` for the AsiBackbone GitHub Pages sites, served at <https://asibackbone.github.io/>.

## Contents

| File | Purpose |
| --- | --- |
| `index.html` | Organization landing page linking the three projects, their documentation sites, and their archived DOIs |
| `robots.txt` | Crawler rules and `Sitemap:` lines. Crawlers only read `robots.txt` at the domain root, so this is the one place that can advertise the project sites' sitemaps |
| `sitemap.xml` | Sitemap for the landing page itself |
| `images/` | Icon, favicon, and social preview image shared with the Learning site |
| `.nojekyll` | Serves the files as-is, without a Jekyll build |

Organization identity, new-repository defaults, supporting-repository controls, and the periodic verification procedure are documented in [SECURITY-BASELINE.md](SECURITY-BASELINE.md).

GitHub Actions dependencies are maintained by Dependabot and reviewed by dependency-review, zizmor, actionlint, and OpenSSF Scorecard workflows using immutable action pins.

Pull-request flow, required checks, merge behavior, and the recovery-only bypass are documented in [REPOSITORY-GOVERNANCE.md](REPOSITORY-GOVERNANCE.md).

Pull-request flow, required checks, merge behavior, and the recovery-only bypass are documented in [REPOSITORY-GOVERNANCE.md](REPOSITORY-GOVERNANCE.md).

## Relationship to the project sites

The project repositories publish their own sites under this domain:

- <https://asibackbone.github.io/Learning/>
- <https://asibackbone.github.io/AsiBackbone/>
- <https://asibackbone.github.io/NetCoreApplicationTemplate/>

This repository must not contain folders named `Learning`, `AsiBackbone`, or `NetCoreApplicationTemplate`, because those paths belong to the project sites.

When a project site starts publishing a sitemap, add its `Sitemap:` line to `robots.txt`.

## Publishing

GitHub Pages deploys the `main` branch root. Changes are live a minute or two after they reach `main`.

## Licensing

Landing-page prose, descriptive metadata, and the listed image assets are licensed under CC BY 4.0. Site implementation, scripts, workflows, and repository configuration are licensed under MIT. See [LICENSES.md](LICENSES.md), [LICENSE](LICENSE), [LICENSE-CODE](LICENSE-CODE), and [ASSETS-LICENSES.md](ASSETS-LICENSES.md) for the complete boundary and trademark notice.
