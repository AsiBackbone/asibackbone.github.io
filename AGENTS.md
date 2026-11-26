# Repository agent instructions

## Purpose and authority

This repository owns the AsiBackbone organization landing site and supporting
public outreach, publication-integrity, security-baseline and repository
metadata guidance. Keep public claims evidence-based and aligned with their
owning repositories. Human maintainers retain authority for publication,
outreach decisions, repository settings and security response.

## Organization discussion proposals

Use [AsiBackbone Organization Discussions](https://github.com/orgs/AsiBackbone/discussions)
for cross-repository ideas, architecture questions, governance proposals and
work that benefits from human review before becoming an issue, pull request,
article or external contribution.

Humans and AI agents may introduce proposals into this public consideration
process. This provides proposal access, not organizational decision authority;
organizational decisions and downstream work authorization remain exclusively
with human maintainers.

By default, prepare a proposed discussion title, category and body locally for
maintainer review. Create a public discussion only when a maintainer explicitly
requests that specific posting action in the current task. Before posting,
search existing organization discussions and affected-repository issues. Do
not create a proposal for an item that is already entered. Return the existing
link instead. Create a distinct follow-up only when a maintainer explicitly
requests it and the new proposal explains the difference. If posting is not
explicitly authorized, return the draft and stop.

Choose the category deliberately:

- `Q&A` for project-specific or cross-project questions and support;
- `Ideas` for feature, process and outreach proposals;
- `Architecture & Integration` for design, tradeoff and integration decisions;
- `Show and tell` only for completed, demonstrated outcomes; and
- `Announcements` only when a maintainer explicitly directs an announcement.

Every AI-assisted public proposal must begin with this visible notice:

> **AI-assisted proposal — unreviewed:** This discussion was prepared with AI
> assistance and remains a proposal until a maintainer records a decision.

Name the affected repository and version when applicable. State the problem or
goal, relevant evidence, alternatives and tradeoffs, risks and the decision
requested. Never include credentials, approval codes, private paths, personal
information, private repository content, exploit details or other sensitive
material. Follow the affected repository's security policy for private
reporting instead.

A discussion is not implementation, publication or merge authority. Agents must
not vote or react to their own proposals, solicit votes, present the proposal as
independently human-authored, or treat comments and reactions as authorization.
A human maintainer must record the decision before accepted work becomes an
issue, pull request, Learning article or separately governed SOFA draft. Link
subsequent work back to the discussion.

## Validation

Run the landing-site and any changed-surface validators under `scripts/`. For
changes limited to this guidance, run at least:

```powershell
./scripts/Test-LandingSite.ps1
./scripts/Test-RepositoryMetadataBaseline.ps1
```

Report only checks actually run and their results. Do not weaken validation to
obtain a pass.
