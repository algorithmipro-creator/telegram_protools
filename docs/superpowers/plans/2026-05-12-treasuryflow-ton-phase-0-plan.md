# TreasuryFlow TON Phase 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the Phase 0 foundation artifacts needed before building the dual testnet prototypes: research notes, architecture decision structure, beta validation plan, scorecard, and Acton toolchain validation record.

**Architecture:** This plan does not implement contracts or frontend yet. It turns the approved dual-track specification into a small, reviewable documentation and decision foundation so the next plans can safely split into Track A contracts, Track B multisig integration, frontend, backend/indexer, and beta operations.

**Tech Stack:** Markdown documentation, Acton CLI research, TON official multisig v2 research, Git, ripgrep-style validation commands.

---

## Scope

The approved specification covers several independent subsystems: smart contracts, official multisig integration, frontend, backend/indexer, notifications, beta analytics, deployment, and release gates. Implementing all of that in one plan would be too broad.

This plan covers only Phase 0 foundation work:

- Prepare docs structure.
- Extract product, technical, security, beta, and ADR documents from the approved spec.
- Create an official multisig v2 review checklist.
- Create an Acton toolchain validation record.
- Create the architecture scorecard template.
- Create a beta feedback form template.
- Define the next implementation-plan split.

The next separate plans should be:

- Track A custom Tolk Treasury and Splitter prototype.
- Track B official multisig v2 adapter and Splitter prototype.
- Telegram Mini App frontend.
- Backend/indexer and Telegram notifications.
- Open beta operations and scoring.

## File Structure

Create or modify these files:

- Create: `.gitignore` for local/generated files if missing.
- Create: `docs/product-spec.md` for product goals, users, beta scope, and non-goals.
- Create: `docs/technical-spec.md` for system architecture, dual tracks, and boundaries.
- Create: `docs/security-model.md` for assets, threats, invariants, and mainnet gates.
- Create: `docs/beta-test-plan.md` for target users, scenario, feedback metrics, and release gates.
- Create: `docs/architecture-decision-records.md` for ADR index and decision process.
- Create: `docs/adr/0001-dual-testnet-track.md` for the first architecture decision.
- Create: `docs/research/official-multisig-v2-review.md` for Track B review findings.
- Create: `docs/research/acton-toolchain-validation.md` for Acton commands and local validation results.
- Create: `docs/beta/architecture-scorecard.md` for balanced Track A vs Track B scoring.
- Create: `docs/beta/feedback-form.md` for beta tester questions and segmentation.
- Create: `docs/implementation-plan-index.md` for the next plan sequence.

Each file has one responsibility. Product docs should not contain contract details. Technical docs should not contain user survey questions. Security docs should not contain roadmap filler. Beta docs should focus on test execution and measurable feedback.

## Task 1: Prepare Repository Hygiene

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Write the file**

Create `.gitignore` with exactly this content:

```gitignore
# Acton generated state and build outputs
.acton/
build/
gen/

# Local secrets
.env
.env.*
!.env.example
wallets.toml
global.wallets.toml
global.libraries.toml

# Node / frontend
node_modules/
dist/
coverage/

# Worktrees and brainstorming scratch files
.worktrees/
worktrees/
.superpowers/

# OS / editor
.DS_Store
Thumbs.db
.idea/
.vscode/
```

- [ ] **Step 2: Verify generated paths are ignored**

Run: `rg -n "^\.acton/|^build/|^gen/|^\.env$|^node_modules/|^\.worktrees/|^worktrees/|^\.superpowers/" .gitignore`

Expected: output includes all eight ignored path patterns.

- [ ] **Step 3: Commit**

Run:

```bash
git add .gitignore
git commit -m "chore: add project ignore rules"
```

Expected: commit succeeds. If the workspace is not a git repository, run `git init` first, then rerun the commit commands.

## Task 2: Create Product Spec

**Files:**
- Create: `docs/product-spec.md`

- [ ] **Step 1: Write the product spec**

Create `docs/product-spec.md` with exactly this content:

````markdown
# TreasuryFlow TON Product Spec

## Summary

TreasuryFlow TON is a Telegram-native treasury tool for teams that need shared control over TON funds, approval-based payouts, and transparent TON revenue splits.

The first beta is not a mainnet product. It is a TON testnet validation of two architecture tracks using one shared user-facing flow.

## Product Goals

- Let a small team create a shared treasury with 2-10 owners.
- Require N-of-M approvals before funds leave the treasury.
- Make every payout and split action understandable before signing.
- Support TON payouts and TON splits in the first testnet beta.
- Collect feedback from open beta testers and known friendly teams.
- Choose the production architecture using measured evidence.

## Target Users

- Telegram Mini App developer teams.
- Creator and Telegram channel teams.
- DAO and community groups.
- NFT and drop teams.
- Agencies and microbusinesses that receive or pay TON.

Feedback must always record the tester segment because each group has different expectations and technical comfort.

## First Beta Scope

| Area | Decision |
|---|---|
| Network | TON testnet only |
| Asset | TON only |
| Core flow | create treasury, deposit, payout proposal, approvals, execution |
| Splits | TON split rule setup and TON split distribution |
| Wallet | TON Connect |
| UI | Telegram Mini App style frontend |
| Architecture | Track A custom Tolk and Track B official multisig v2 based |

## Non-Goals

- Mainnet deployment.
- Jetton payouts.
- Protocol fees.
- Lending, DEX, yield, prediction markets, and token launch features.
- Custodial accounts or server-controlled funds.
- Advanced DAO governance.
- Fiat on/off-ramp.

## Success Criteria

- Testers can complete treasury creation, payout, and split flows on testnet.
- Testers understand what they approve before signing.
- Track-specific issues are recorded separately.
- The team can score Track A and Track B using security, UX, complexity, gas, Acton compatibility, and extensibility evidence.
````

- [ ] **Step 2: Verify product spec has required sections**

Run: `rg -n "^## Summary|^## Product Goals|^## Target Users|^## First Beta Scope|^## Non-Goals|^## Success Criteria" docs/product-spec.md`

Expected: six matching headings.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/product-spec.md
git commit -m "docs: add TreasuryFlow product spec"
```

Expected: commit succeeds.

## Task 3: Create Technical Spec

**Files:**
- Create: `docs/technical-spec.md`

- [ ] **Step 1: Write the technical spec**

Create `docs/technical-spec.md` with exactly this content:

````markdown
# TreasuryFlow TON Technical Spec

## Architecture Strategy

TreasuryFlow TON uses a dual testnet strategy before choosing a production architecture.

| Track | Description |
|---|---|
| Track A | Custom Tolk Treasury, Proposal logic, and Splitter contracts |
| Track B | Official TON multisig v2 as authorization layer with TreasuryFlow adapter and Splitter integration |

Both tracks must expose the same user-facing beta operations where possible.

## System Diagram

```text
Telegram Mini App
        |
        v
TON Connect + TreasuryFlow UI
        |
        v
Generated TypeScript Wrappers
        |
        +-----------------------------+
        |                             |
        v                             v
Track A Custom Tolk              Track B Official Multisig v2
Treasury + Splitter              Adapter + Splitter
        |                             |
        +--------------+--------------+
                       |
                       v
                 TON testnet
```

## Shared Operations

- Create treasury.
- Deposit TON.
- Create payout proposal.
- Approve proposal.
- Execute payout.
- Configure split rules.
- Create split distribution proposal.
- Approve split proposal.
- Execute split distribution.

## Onchain Boundary

Onchain state decides owners, threshold, proposal validity, approvals, execution status, split weights, payouts, and split execution.

## Offchain Boundary

Offchain systems may store names, comments, Telegram bindings, notifications, cached history, beta feedback, aliases, and analytics. They must not control funds or decide financial correctness.

## Track A Contract Units

| Unit | Responsibility |
|---|---|
| `Treasury.tolk` | owners, threshold, proposal registry, balance, authorization |
| Proposal logic | proposal status, approvals, expiry, nonce, action payload |
| `Splitter.tolk` | TON recipients, weights, deterministic distribution |
| Common helpers | errors, messages, ownership, fee reserve helpers |

## Track B Mapping Units

| TreasuryFlow Concept | Official Multisig v2 Mapping |
|---|---|
| Proposal | multisig order/action |
| Approval | multisig owner confirmation |
| Execute | multisig order execution |
| Split distribution | approved call to Splitter or batch actions |
| Status | official state plus indexer-derived view-state |
| Preview | UI parser over multisig payloads |

## Split Model

- Asset: TON only.
- Recipients: 2-20.
- Weights: positive integers.
- Denominator: `10_000` basis points.
- Total weight: exactly `10_000`.
- Dust: keep remainder in Treasury.
- Updates: approved proposal only.
- Distribution: approved proposal only.
````

- [ ] **Step 2: Verify technical spec has architecture and split model**

Run: `rg -n "Track A|Track B|Generated TypeScript Wrappers|10_000|Dust" docs/technical-spec.md`

Expected: matches for both tracks, wrappers, denominator, and dust rule.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/technical-spec.md
git commit -m "docs: add TreasuryFlow technical spec"
```

Expected: commit succeeds.

## Task 4: Create Security Model

**Files:**
- Create: `docs/security-model.md`

- [ ] **Step 1: Write the security model**

Create `docs/security-model.md` with exactly this content:

```markdown
# TreasuryFlow TON Security Model

## Security Position

TreasuryFlow handles team funds. Every payout, split distribution, and configuration update is a financial security event.

The first beta is testnet only. Mainnet is blocked until architecture selection, security review, and release checklist approval.

## Assets To Protect

- Treasury TON balance.
- Owner list.
- Threshold.
- Pending proposals.
- Approval records.
- Split rules.
- Deployment keys and wallet configuration.
- Telegram bot token.
- Offchain metadata integrity.

## Invariants

| Invariant | Requirement |
|---|---|
| Owner-only proposal creation | Non-owner cannot create financial proposals |
| Owner-only approval | Non-owner cannot approve |
| No double approval | One owner cannot increase approval count twice |
| Threshold required | Execution before threshold is rejected |
| Expiry enforced | Expired proposal cannot execute |
| No double execution | Executed proposal cannot execute again |
| Deterministic split math | UI preview and onchain result match |
| Fee reserve | Treasury does not drain below configured reserve |
| Payload transparency | Payload is decoded or marked with a warning |
| Replay protection | Proposal/action cannot be reused after terminal status |

## Threats And Mitigations

| Threat | Mitigation |
|---|---|
| Single owner drain | N-of-M approval threshold |
| Replay | nonce, status, terminal proposal states |
| Double approval | approval bitmap/map per proposal |
| Expired execution | expiry check before approval and execution |
| Unknown payload | human-readable parser plus raw technical details |
| Owner spoofing | onchain sender validation |
| Threshold attack | threshold updates disabled in beta UI or require approved proposal |
| Jetton spoofing | Jettons excluded from first beta |
| Bounce confusion | activity visibility and explicit failure state where possible |
| Frontend compromise | onchain checks, generated wrappers, raw payload preview, source verification |

## Mainnet Blockers

Mainnet is forbidden until all of these are complete:

- Architecture decision record is approved.
- Threat model is reviewed.
- Critical unit and fuzz tests pass.
- Gas and fee implications are understood.
- Source verification workflow is confirmed.
- External review or audit is completed.
- Mainnet release checklist is approved.
```

- [ ] **Step 2: Verify security invariants are present**

Run: `rg -n "Owner-only|No double approval|Threshold required|Replay protection|Mainnet is forbidden" docs/security-model.md`

Expected: matches for all listed invariant and gate phrases.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/security-model.md
git commit -m "docs: add TreasuryFlow security model"
```

Expected: commit succeeds.

## Task 5: Create Beta Test Plan

**Files:**
- Create: `docs/beta-test-plan.md`

- [ ] **Step 1: Write the beta test plan**

Create `docs/beta-test-plan.md` with exactly this content:

```markdown
# TreasuryFlow TON Beta Test Plan

## Beta Type

The first beta is a public TON testnet validation with direct outreach to known teams.

## Target Segments

- Telegram Mini App developer team.
- Creator or Telegram channel team.
- DAO or community group.
- NFT or drop team.
- Agency or microbusiness.
- Other TON testnet user.

## Required Scenario

Each tester should attempt this scenario:

1. Open the Mini App.
2. Connect wallet through TON Connect.
3. Create a treasury with 2-10 owners.
4. Deposit testnet TON.
5. Create a payout proposal.
6. Have another owner approve.
7. Execute payout after threshold.
8. Configure split recipients and weights.
9. Create split distribution proposal.
10. Approve and execute split distribution.
11. Submit feedback.

## Metrics

| Metric | Meaning |
|---|---|
| Task completion | Whether treasury, payout, and split flows complete |
| Time-to-complete | Time spent per flow |
| Confusion points | Where tester pauses or asks for help |
| Trust clarity | Whether tester understands what they sign |
| Fee clarity | Whether tester understands fees and reserves |
| Approval clarity | Whether tester understands threshold and remaining approvals |
| Split clarity | Whether split preview matches expectation |
| Error clarity | Whether failures are understandable |
| Architecture finding | Track-specific friction or failure |

## Release Gates

| Gate | Requirement |
|---|---|
| Internal testnet | Contracts build/test, UI completes one payout |
| Known teams beta | Payout and splits work, feedback form active, no critical security gap |
| Open beta | Source verification dry-run, public test instructions, known failure handling |
| Architecture decision | Scorecard completed for Track A and Track B |
| Mainnet candidate | Audit/review, threat model, migration/deprecation plan |
```

- [ ] **Step 2: Verify beta scenario and gates**

Run: `rg -n "Required Scenario|Create a treasury|Configure split|Release Gates|Architecture decision" docs/beta-test-plan.md`

Expected: matches for scenario and release-gate sections.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/beta-test-plan.md
git commit -m "docs: add TreasuryFlow beta test plan"
```

Expected: commit succeeds.

## Task 6: Create ADR Index And First ADR

**Files:**
- Create: `docs/architecture-decision-records.md`
- Create: `docs/adr/0001-dual-testnet-track.md`

- [ ] **Step 1: Create ADR directory**

Run: `New-Item -ItemType Directory -Force -Path "docs\adr"`

Expected: `docs/adr` exists.

- [ ] **Step 2: Write ADR index**

Create `docs/architecture-decision-records.md` with exactly this content:

```markdown
# Architecture Decision Records

This index tracks architecture decisions for TreasuryFlow TON.

| ADR | Status | Decision |
|---|---|---|
| [0001](adr/0001-dual-testnet-track.md) | Accepted for beta | Use dual testnet track before choosing production architecture |

## Decision Status Values

- Proposed: under discussion.
- Accepted for beta: valid for testnet validation.
- Accepted for production: approved for mainnet candidate work.
- Replaced: superseded by a later ADR.
```

- [ ] **Step 3: Write ADR 0001**

Create `docs/adr/0001-dual-testnet-track.md` with exactly this content:

```markdown
# ADR 0001: Dual Testnet Track

## Status

Accepted for beta.

## Context

TreasuryFlow TON needs a secure N-of-M treasury architecture. A custom Tolk implementation gives product flexibility, while official TON multisig v2 may provide stronger production security posture.

Choosing one architecture before testnet validation would hide important UX, security, gas, and development trade-offs.

## Decision

Build and test two comparable testnet tracks:

- Track A: custom Tolk Treasury, Proposal logic, and Splitter contracts.
- Track B: official TON multisig v2 based TreasuryFlow with adapter and Splitter integration.

Use the same beta scenario and score both tracks with a balanced score matrix.

## Consequences

- More Phase 1 work is required because two tracks must be evaluated.
- Production architecture will be selected using evidence rather than preference.
- Mainnet remains blocked until a later production ADR is accepted.
```

- [ ] **Step 4: Verify ADR links and status**

Run: `rg -n "0001|Accepted for beta|Track A|Track B|Mainnet remains blocked" docs/architecture-decision-records.md docs/adr/0001-dual-testnet-track.md`

Expected: matches in both ADR files.

- [ ] **Step 5: Commit**

Run:

```bash
git add docs/architecture-decision-records.md docs/adr/0001-dual-testnet-track.md
git commit -m "docs: record dual testnet architecture decision"
```

Expected: commit succeeds.

## Task 7: Create Official Multisig v2 Review Template

**Files:**
- Create: `docs/research/official-multisig-v2-review.md`

- [ ] **Step 1: Create research directory**

Run: `New-Item -ItemType Directory -Force -Path "docs\research"`

Expected: `docs/research` exists.

- [ ] **Step 2: Write review template**

Create `docs/research/official-multisig-v2-review.md` with exactly this content:

```markdown
# Official TON Multisig v2 Review

## Purpose

Determine whether official TON multisig v2 can serve as the production trust layer for TreasuryFlow TON.

## Sources To Review

- Official TON multisig v2 repository.
- Contract storage schema.
- Order/action lifecycle.
- Owner confirmation mechanics.
- Execution semantics.
- Getter availability.
- Existing tests and audit notes if available.

## Review Questions

| Question | Finding | Impact |
|---|---|---|
| How are owners stored? | Not reviewed yet | Blocks Track B mapping |
| How is threshold enforced? | Not reviewed yet | Blocks security comparison |
| How are orders created? | Not reviewed yet | Blocks proposal UX mapping |
| How are confirmations recorded? | Not reviewed yet | Blocks approval UI mapping |
| How is execution triggered? | Not reviewed yet | Blocks payout/split flow |
| Can arbitrary actions call Splitter? | Not reviewed yet | Blocks TON split design |
| Which getters are available? | Not reviewed yet | Blocks frontend/indexer design |
| How are expired orders handled? | Not reviewed yet | Blocks proposal state mapping |
| What replay protections exist? | Not reviewed yet | Blocks security comparison |
| What source verification path exists? | Not reviewed yet | Blocks release gate |

## Required Output

The review must end with one of these recommendations:

- Track B is viable for beta prototype.
- Track B is viable only with adapter constraints.
- Track B is not viable for the first beta.

## Notes

Replace each `Not reviewed yet` cell with a concrete finding during the review. Do not use this file as production evidence until every review row has a finding.
```

- [ ] **Step 3: Verify review questions**

Run: `rg -n "owners stored|threshold enforced|orders created|arbitrary actions call Splitter|Required Output" docs/research/official-multisig-v2-review.md`

Expected: matches for key review questions and output section.

- [ ] **Step 4: Commit**

Run:

```bash
git add docs/research/official-multisig-v2-review.md
git commit -m "docs: add official multisig review template"
```

Expected: commit succeeds.

## Task 8: Create Acton Toolchain Validation Record

**Files:**
- Create: `docs/research/acton-toolchain-validation.md`

- [ ] **Step 1: Write validation record**

Create `docs/research/acton-toolchain-validation.md` with exactly this content:

```markdown
# Acton Toolchain Validation

## Purpose

Confirm that Acton can support the TreasuryFlow TON development workflow: scaffold, build, test, wrapper generation, deployment scripts, gas snapshots, fuzz testing, and source verification.

## Commands To Validate

| Area | Command | Expected Result | Recorded Result |
|---|---|---|---|
| Version | `acton --version` | Acton 1.0.0 or later | Not run yet |
| Help | `acton --help` | Command list is printed | Not run yet |
| Scaffold | `acton new treasury-flow-ton --template counter --app` | Project scaffold is created | Not run yet |
| Build | `acton build` | Contracts compile | Not run yet |
| Test | `acton test` | Tests pass | Not run yet |
| Lint | `acton check` | No critical diagnostics | Not run yet |
| Format | `acton fmt --check` | Formatting check passes | Not run yet |
| Wrappers | `acton wrapper --all --ts` | TypeScript wrappers generated | Not run yet |
| Gas snapshot | `acton test --snapshot gas-baseline.json` | Snapshot file created | Not run yet |
| Verification dry-run | `acton verify <contract> --address <address> --dry-run` | Verifier accepts sources | Not run yet |

## Validation Notes

Use this file to record the exact local environment and any Windows-specific issues, including PowerShell execution policy problems, PATH problems, Node.js version problems, and Acton installation status.

## Minimum Accepted Toolchain

- Acton 1.0.0 or later.
- Node.js 22 LTS or later for the Vite frontend scaffold.
- npm and npx available in PATH.
- TON Center testnet API key available before public beta if rate limits interfere with deployment or indexer testing.
```

- [ ] **Step 2: Verify validation matrix**

Run: `rg -n "acton --version|acton new|acton wrapper --all --ts|gas-baseline|Node.js 22" docs/research/acton-toolchain-validation.md`

Expected: matches for validation commands and minimum toolchain.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/research/acton-toolchain-validation.md
git commit -m "docs: add Acton toolchain validation record"
```

Expected: commit succeeds.

## Task 9: Create Architecture Scorecard

**Files:**
- Create: `docs/beta/architecture-scorecard.md`

- [ ] **Step 1: Create beta directory**

Run: `New-Item -ItemType Directory -Force -Path "docs\beta"`

Expected: `docs/beta` exists.

- [ ] **Step 2: Write scorecard**

Create `docs/beta/architecture-scorecard.md` with exactly this content:

```markdown
# TreasuryFlow Architecture Scorecard

## Purpose

Compare Track A custom Tolk and Track B official multisig v2 based architecture after testnet validation.

## Weighted Score

| Criterion | Weight | Track A Score 1-5 | Track B Score 1-5 | Evidence Required |
|---|---:|---:|---:|---|
| Security / auditability | 30 | 0 | 0 | invariant coverage, code complexity, reviewed base, audit readiness |
| User UX clarity | 20 | 0 | 0 | completion rate, confusion points, trust score |
| Development complexity | 15 | 0 | 0 | implementation effort, wrapper friction, debugging effort |
| Gas/fees | 15 | 0 | 0 | Acton gas snapshots and fee observations |
| Acton workflow compatibility | 10 | 0 | 0 | build/test/wrapper/deploy/verify smoothness |
| Extensibility for splits/Jettons | 10 | 0 | 0 | split fit, Jetton path, adapter complexity |

## Score Rules

- 1 means poor fit or high risk.
- 3 means acceptable with known trade-offs.
- 5 means strong fit with clear evidence.
- Do not assign a nonzero score without written evidence.

## Decision Outcomes

- Choose Track A only if security review supports custom multisig logic.
- Choose Track B if official multisig gives stronger safety without unacceptable UX constraints.
- Choose hybrid if official multisig handles authorization while custom contracts handle product-specific split and metadata flows.
```

- [ ] **Step 3: Verify weights sum to 100 by inspection**

Run: `rg -n "Security / auditability|User UX clarity|Development complexity|Gas/fees|Acton workflow compatibility|Extensibility" docs/beta/architecture-scorecard.md`

Expected: six criteria appear. Weights are 30, 20, 15, 15, 10, and 10.

- [ ] **Step 4: Commit**

Run:

```bash
git add docs/beta/architecture-scorecard.md
git commit -m "docs: add architecture scorecard"
```

Expected: commit succeeds.

## Task 10: Create Feedback Form Template

**Files:**
- Create: `docs/beta/feedback-form.md`

- [ ] **Step 1: Write feedback form**

Create `docs/beta/feedback-form.md` with exactly this content:

```markdown
# TreasuryFlow Beta Feedback Form

## Tester Segment

Choose one:

- Telegram Mini App developer team.
- Creator or Telegram channel team.
- DAO or community group.
- NFT or drop team.
- Agency or microbusiness.
- Other.

## Completion Questions

| Question | Answer Type |
|---|---|
| Did you create a treasury? | Yes / No |
| Did you deposit testnet TON? | Yes / No |
| Did you create a payout proposal? | Yes / No |
| Did another owner approve? | Yes / No |
| Did you execute a payout? | Yes / No |
| Did you configure split rules? | Yes / No |
| Did you execute a split distribution? | Yes / No |

## Clarity Questions

| Question | Answer Type |
|---|---|
| How well did you understand what you signed? | 1-5 |
| How much did you trust the process? | 1-5 |
| How clear were fees and reserves? | 1-5 |
| How clear were approval requirements? | 1-5 |
| How clear was the split preview? | 1-5 |

## Written Feedback

- What was confusing?
- What felt unsafe?
- What error message was hardest to understand?
- What must change before mainnet?
- Would you use this for a real team?
- If yes or maybe, what team scenario would you use it for?

## Internal Fields

These fields are filled by the product team or telemetry layer:

- Architecture track: Track A or Track B.
- Treasury address.
- Proposal count.
- Payout completed: yes or no.
- Split completed: yes or no.
- Time-to-complete.
- Failure codes observed.
```

- [ ] **Step 2: Verify feedback fields**

Run: `rg -n "Tester Segment|Completion Questions|Clarity Questions|Architecture track|Time-to-complete" docs/beta/feedback-form.md`

Expected: all feedback sections and internal fields appear.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/beta/feedback-form.md
git commit -m "docs: add beta feedback form"
```

Expected: commit succeeds.

## Task 11: Create Implementation Plan Index

**Files:**
- Create: `docs/implementation-plan-index.md`

- [ ] **Step 1: Write plan index**

Create `docs/implementation-plan-index.md` with exactly this content:

```markdown
# TreasuryFlow Implementation Plan Index

## Current Plan

Phase 0 foundation artifacts are defined in `docs/superpowers/plans/2026-05-12-treasuryflow-ton-phase-0-plan.md`.

## Next Plans

| Order | Plan | Output |
|---:|---|---|
| 1 | Track A custom Tolk Treasury and Splitter prototype | Acton contracts, tests, wrappers, testnet deploy script |
| 2 | Track B official multisig v2 adapter prototype | official multisig review, adapter mapping, tests, deploy script |
| 3 | Telegram Mini App frontend | TON Connect UI, dashboard, proposals, split screens, feedback screen |
| 4 | Backend/indexer and notifications | activity index, metadata API, Telegram notifications, feedback storage |
| 5 | Open beta operations | public instructions, invite copy, scorecard process, release gates |

## Execution Rule

Do not start mainnet work until the architecture scorecard is completed and a production ADR is accepted.
```

- [ ] **Step 2: Verify plan index**

Run: `rg -n "Track A custom Tolk|Track B official multisig|Telegram Mini App|Backend/indexer|Do not start mainnet" docs/implementation-plan-index.md`

Expected: all next plans and mainnet rule appear.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/implementation-plan-index.md
git commit -m "docs: add implementation plan index"
```

Expected: commit succeeds.

## Task 12: Final Phase 0 Verification

**Files:**
- Verify all created Phase 0 files.

- [ ] **Step 1: Verify all required files exist**

Run:

```powershell
$required = @(
  ".gitignore",
  "docs/product-spec.md",
  "docs/technical-spec.md",
  "docs/security-model.md",
  "docs/beta-test-plan.md",
  "docs/architecture-decision-records.md",
  "docs/adr/0001-dual-testnet-track.md",
  "docs/research/official-multisig-v2-review.md",
  "docs/research/acton-toolchain-validation.md",
  "docs/beta/architecture-scorecard.md",
  "docs/beta/feedback-form.md",
  "docs/implementation-plan-index.md"
)
$missing = $required | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missing.Count -gt 0) { throw "Missing required files: $($missing -join ', ')" }
```

Expected: command exits with status `0` and no output.

- [ ] **Step 2: Scan for unresolved markers**

Run the required unresolved-marker scan across `docs` and `.gitignore`.

Expected: no matches.

- [ ] **Step 3: Verify mainnet is blocked in security and plan docs**

Run: `rg -n "Mainnet is forbidden|Do not start mainnet|mainnet work" docs/security-model.md docs/implementation-plan-index.md`

Expected: matches in both files.

- [ ] **Step 4: Commit final verification note if files changed during fixes**

Run:

```bash
git status --short
git add docs .gitignore
git commit -m "docs: complete Phase 0 foundation"
```

Expected: if `git status --short` showed changes, commit succeeds. If there were no changes, skip the commit.

## Self-Review

Spec coverage:

- Product goals, target users, beta scope, and non-goals are covered by Task 2.
- Dual architecture strategy and system boundaries are covered by Task 3.
- Security invariants and mainnet gates are covered by Task 4.
- Beta validation, metrics, and release gates are covered by Task 5.
- Architecture decision process is covered by Task 6 and Task 9.
- Official multisig v2 research is covered by Task 7.
- Acton workflow validation is covered by Task 8.
- Feedback collection is covered by Task 10.
- Next implementation split is covered by Task 11.

Marker scan:

- The plan intentionally uses `Not run yet` and `Not reviewed yet` in research templates because those are initial recorded states, not unresolved implementation instructions.
- The final verification task scans generated docs for unresolved engineering markers.

Type and naming consistency:

- Track names are consistently `Track A` and `Track B`.
- Split denominator is consistently `10_000` basis points.
- Mainnet remains blocked across security and plan-index documents.
