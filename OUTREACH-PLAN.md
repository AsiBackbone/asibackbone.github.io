# Outreach and discoverability plan

Status: Active maintainer plan<br>
Owner: AsiBackbone organization maintainer<br>
Initial planning window: 2026-10-19 through 2027-01-16<br>
Last link and channel review: 2026-10-11<br>
Next plan review: 2027-01-18

This plan defines a sustainable way to introduce AsiBackbone's existing work to people who have a relevant problem. It does not set targets for stars, forks, maintainers, adopters, or conference acceptance. Scheduled items below are **planned**, not already published, unless an evidence link is added after publication.

The organization landing page is the discovery front door. Technical claims, samples, release details, and implementation guidance remain in their owning project repositories and sites. Outreach should point to that canonical material instead of copying it here.

## Audiences and problem-first entry points

| Audience | Problem to start with | Canonical owner and entry point | Useful next step |
| --- | --- | --- | --- |
| .NET and ASP.NET Core developers | "When is built-in authorization enough, and when does a decision need a durable explanation?" | Learning: [When ASP.NET Core Authorization Is Enough](https://asibackbone.github.io/Learning/architecture/when-aspnet-core-authorization-is-enough.html) | Compare the boundary before evaluating another dependency. |
| Application architects and technical leads | "How can policy, evidence, and execution stay separated without adding machinery to simple applications?" | Learning: [When a Simple Application Service Is Enough](https://asibackbone.github.io/Learning/architecture/when-a-simple-application-service-is-enough.html) | Follow the learning path, then inspect the framework documentation. |
| Application-security and governance practitioners | "How can an application show why an operation was permitted, under which policy, and with what evidence?" | AsiBackbone: [framework documentation](https://asibackbone.github.io/AsiBackbone/) | Review the concepts and current release notes before discussing adoption. |
| Teams starting or modernizing an ASP.NET Core service | "What does a secure, observable, maintainable application boundary look like in a working template?" | NetCoreApplicationTemplate: [template documentation](https://asibackbone.github.io/NetCoreApplicationTemplate/) | Scaffold a disposable sample and evaluate the defaults against local requirements. |
| AI-governance and agent-system builders | "How can an AI-assisted recommendation remain separate from the host's authority to act?" | Learning: [learning site](https://asibackbone.github.io/Learning/) and AsiBackbone: [framework documentation](https://asibackbone.github.io/AsiBackbone/) | Start a concrete architecture discussion; do not imply that the framework alone establishes legal or regulatory compliance. |
| Open-source evaluators and potential contributors | "Where can I evaluate scope, support boundaries, and contribution readiness without making an adoption commitment?" | Each project's documentation and repository, reached from the [organization landing page](https://asibackbone.github.io/) | Ask a question, reproduce a sample, or make a bounded contribution. |

## Canonical content map

Outreach artifacts may summarize these sources, but every technical claim must link back to the current owner.

| Content | Canonical owner | Reuse rule |
| --- | --- | --- |
| Concepts, comparisons, tutorials, and cross-project learning paths | [Learning](https://asibackbone.github.io/Learning/) | Lead with the reader's decision or problem; link to the article rather than reproducing it. |
| Framework behavior, packages, API guidance, compatibility, and framework releases | [AsiBackbone](https://asibackbone.github.io/AsiBackbone/) | Verify against the documentation and [framework releases](https://github.com/AsiBackbone/AsiBackbone/releases) on publication day. |
| Scaffold behavior, runnable defaults, setup instructions, and template releases | [NetCoreApplicationTemplate](https://asibackbone.github.io/NetCoreApplicationTemplate/) | Verify commands against a clean scaffold and the [template releases](https://github.com/AsiBackbone/NetCoreApplicationTemplate/releases). |
| Cross-project questions, adopter reports, and architecture proposals | [Organization Discussions](https://github.com/orgs/AsiBackbone/discussions/categories/architecture-integration) | Link to repository-specific evidence; do not turn a discussion into a second documentation source. |
| Organization identity, project routing, and this plan | [Organization landing repository](https://github.com/AsiBackbone/asibackbone.github.io) | Keep the material organizational and route implementation changes to the owning repository. |

## Sustainable publishing model

The default effort ceiling is one substantial canonical item and up to two small adaptations per month. A release or security correction takes priority over the calendar. Skipping an item is preferable to publishing an unverified or repetitive one.

Every cycle should use this sequence:

1. Choose one real question seen in documentation, an issue, a discussion, or release work.
2. Improve or confirm the canonical source first.
3. Produce one durable artifact: an article, worked sample, release brief, talk outline, or consented case study.
4. Adapt it for no more than two suitable channels, following each channel's rules.
5. Record the published URLs, useful responses, corrections, and follow-up work at the next review.

Do not cross-post the same promotional paragraph to unrelated communities. External participation must answer an existing question, contribute reusable technical material, or follow an explicit speaker/content submission process.

## Initial 90-day calendar

All entries are planned. Dates are maintainer targets, not publication claims.

| Window | Reusable deliverable | Canonical source and verification | Proposed channels | Completion evidence |
| --- | --- | --- | --- | --- |
| Days 1-14: 2026-10-19 to 2026-11-01 | **Decision brief:** "When ordinary ASP.NET Core authorization is enough"; one diagram or comparison table plus a short discussion adaptation | Learning comparison article; re-run Learning documentation validation before publication | Learning article/RSS and one organization architecture discussion; consider a .NET community answer only when it directly addresses an existing question | Canonical article or revision URL, discussion URL, validation result |
| Days 15-30: 2026-11-02 to 2026-11-17 | **Talk proposal and demo runbook:** policy decision, evidence capture, and host-owned execution in a small ASP.NET Core scenario | Learning explanation, current AsiBackbone release, and a clean template scaffold | [.NET Conf](https://dotnet.microsoft.com/en-us/conf) only if its current CFP is open and the proposal fits; otherwise retain the proposal for an appropriate meetup or later CFP | Versioned outline, runnable demo commit, submission or deferral note |
| Days 31-45: 2026-11-18 to 2026-12-02 | **Security architecture briefing:** what an auditable authorization decision proves—and what it does not | Learning and framework documentation; maintainer review of all security and compliance wording | A suitable OWASP chapter speaker inquiry or an organization discussion, after rules and local organizer interest are confirmed | Briefing URL, inquiry/submission record, corrections received |
| Days 46-60: 2026-12-03 to 2026-12-17 | **Release-to-practice note:** one concrete framework or template capability, its trade-offs, and a reproducible evaluation path | Current framework/template release notes and a fresh scaffold smoke test | Learning article/RSS, release notes backlink, and at most one relevant .NET venue | Article URL, exact tested versions, smoke-test result, referral snapshot if available |
| Days 61-75: 2026-12-18 to 2027-01-01 | **Architecture/AI-governance proposal:** host authority versus model recommendation, with explicit claim boundaries | Learning and framework sources; factual and regulatory claims require primary sources | Prepare for a future architecture CFP or contribute substantively to a relevant open working group; no holiday-period posting quota | Proposal URL or local draft reference, source review, channel decision |
| Days 76-90: 2027-01-02 to 2027-01-16 | **Evaluation invitation and retrospective:** a reusable adopter-report template plus the first 90-day evidence review | Organization contribution/adopter pathways and the evidence produced above | Organization Discussions and project contribution routes; direct outreach only to people who invited follow-up | Retrospective discussion, consented reports, next-quarter decision |

The first window can move if this plan merges after 2026-10-19; preserve the ordering and the 90-day effort envelope rather than compressing missed work.

## Candidate communities and CFP sources

These are candidates, not pre-approved distribution lists. The maintainer must re-read the linked rules and current submission status immediately before participating. A verified link only establishes that the venue and guidance were reachable on the last review date; it does not establish that a submission is open or appropriate.

| Candidate | Appropriate contribution | Participation rule or verification link | Gate before use |
| --- | --- | --- | --- |
| .NET Foundation | Open-source maintainer knowledge-sharing, committee participation, or an invited project/community opportunity | [Participation types](https://dotnetfoundation.org/membership/participation-types) and [.NET Foundation Code of Conduct](https://dotnetfoundation.org/code-of-conduct) | Participate as a contributor; confirm the current route and do not treat membership as a promotional entitlement. |
| .NET Conf | A tested, educational .NET session with concrete takeaways | [Current event and Call for Speakers status](https://dotnet.microsoft.com/en-us/conf) | Confirm the CFP is open, the format/deadline, originality expectations, and speaker terms before submission. |
| ASP.NET Core GitHub community | A directly relevant technical answer or upstream discussion | [Discussions](https://github.com/dotnet/aspnetcore/discussions) and [contribution guidance](https://github.com/dotnet/aspnetcore/blob/main/CONTRIBUTING.md) | Do not open a project-promotion topic. Participate only where the material resolves or advances an ASP.NET Core question. |
| OWASP chapters and events | Vendor-neutral application-security education, a chapter talk, or a public CFP response | [Chapter directory](https://owasp.org/chapters/), [Chapters Policy](https://owasp.org/policy/chapters), and [Events Policy](https://owasp.org/policy/events) | Contact the relevant organizer, keep the content vendor-neutral, and follow the event's speaker agreement and open CFP. |
| iSAQB Software Architecture Gathering | A practice-based architecture talk or workshop | [Current Call for Papers](https://www.software-architecture-gathering.com/call-for-papers/) | Recheck dates and formats; submit a lessons-and-trade-offs proposal rather than a product pitch. |
| AI Alliance | Substantive work on open, safe, responsible AI within an active working group | [Join and working-group route](https://thealliance.ai/join) and [individual participation clarification](https://help.thealliance.ai/who-can-be-a-member) | Join only with capacity to contribute to the group's work; do not use a working group as an announcement channel. |

If a venue has no clear participation rules, no current organizer contact, or no relevant audience question, do not post. Record the deferral and choose another planned deliverable.

## Reusable publication checklist

### Before drafting

- [ ] Name one audience, one problem, and one useful action the reader can take.
- [ ] Identify the owning canonical source and confirm that it is current.
- [ ] Decide whether the work belongs in Learning, AsiBackbone, NetCoreApplicationTemplate, or this organization repository.
- [ ] Read the target channel's current content, submission, self-promotion, conduct, licensing, and disclosure rules.
- [ ] Check for a similar recent post or open submission to avoid repetition.

### Technical and editorial review

- [ ] Test every command, sample, and version-dependent statement against the named release or commit.
- [ ] Link technical claims to the canonical project page, documentation, release, or immutable evidence as appropriate.
- [ ] Separate demonstrated behavior from analogy, inference, roadmap, and legal or regulatory interpretation.
- [ ] State material limitations, alternatives, and when the AsiBackbone approach is unnecessary.
- [ ] Remove secrets, private correspondence, private analytics, and identifying user or adopter details.
- [ ] Confirm licenses and attribution for every third-party quotation, diagram, image, recording, or dataset.
- [ ] Use accessible headings, descriptive link text, alt text, captions, and readable contrast where the format supports them.

### Channel adaptation and publication

- [ ] Keep the canonical source complete; make the channel version a concise, audience-specific introduction rather than a divergent copy.
- [ ] Disclose project affiliation and relevant conflicts of interest.
- [ ] Use the community's required submission mechanism and respect moderator or organizer decisions.
- [ ] Recheck every link and the channel rules on publication day.
- [ ] Label planned, experimental, or unreleased work; never present it as shipped.
- [ ] Record the publication URL, date, owner, canonical source, tested version, and any promised follow-up.

### After publication

- [ ] Answer good-faith technical questions and correct material errors at the canonical source first.
- [ ] Capture qualified questions, documentation referrals where available, contribution activity, and opt-in adopter reports without profiling individuals.
- [ ] Do not scrape member lists, harvest addresses, add people to mailing lists, or republish private messages.
- [ ] Stop or revise a channel experiment that produces noise, moderation concerns, or no useful learning after two attempts.

## Permission, attribution, and privacy guardrails

An organization, project, quotation, logo, screenshot, usage statement, or person's name must not appear as an endorsement or adopter story without explicit permission covering the proposed wording and channel. Keep the approval record privately; publish only what the person authorized. Offer attribution, anonymity, or withdrawal before publication, and remove or correct the story if consent is withdrawn where reasonably possible.

Aggregate signals when practical. Do not commit raw analytics exports, email addresses, IP addresses, attendee lists, private messages, or community membership data. Public GitHub activity may be linked when it is necessary evidence, but do not assemble individual activity profiles. Follow the destination community's privacy terms as well as these guardrails.

Third-party material retains its own license. Prefer a link or an original explanation. Record the source, license, attribution, permission, and modification status before copying material into an AsiBackbone artifact.

## Ownership and review cadence

The organization maintainer owns the calendar, channel checks, publication record, and quarterly review. The maintainer of the canonical project source owns technical accuracy and may block or correct an adaptation. A future contributor may prepare an artifact, but publication remains subject to the same review and consent gates.

Review this plan monthly during the initial window and quarterly afterward. At each review:

1. mark each planned deliverable completed, deferred, revised, or dropped and link evidence;
2. recheck community rules and remove stale or unsuitable candidates;
3. note recurring audience questions and improve the canonical documentation first;
4. assess effort against useful outcomes, not reach alone; and
5. select at most one substantial canonical item for the next month.

## Measurement and limits

Record a lightweight baseline at the start of each quarter and compare it only with the same source and definition at review time.

| Signal | What it can indicate | Limit |
| --- | --- | --- |
| Qualified questions and discussions | Whether the material reached someone with the named problem | Volume is not quality; moderation and maintainer replies can influence it. |
| Documentation referrals, when privacy-preserving data is available | Which sources or channels led readers to canonical material | Referrer data can be absent, blocked, or aggregated; do not identify visitors. |
| Package downloads, release views, or scaffold usage signals | Possible evaluation or use over time | Downloads are not unique users, successful adoption, or endorsement. |
| External issues, pull requests, and other contributions | Observable participation in project work | One contributor or contribution should not become a growth target. |
| Opt-in adopter reports | Context-rich evidence of real evaluation or use | Self-selected, permission-dependent, and not representative of all users. |
| CFP, meetup, or working-group outcomes | Whether a proposed contribution matched a venue | Acceptance depends on timing, capacity, and program fit as well as quality. |

Stars, forks, impressions, and follower counts may be recorded as context, but they are not success targets and must not be manufactured. The useful outcome is better-informed evaluation, better questions, corrected documentation, or a genuine contribution—not a larger number by itself.
