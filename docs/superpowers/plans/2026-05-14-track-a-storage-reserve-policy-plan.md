# Track A Storage Reserve Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record Track A storage reserve policy and mainnet blockers so reserve sizing and unbounded on-chain history risk are explicit before further Track A work.

**Architecture:** This is documentation-only policy work. Add one focused research document with storage estimates, reserve tiers, and governance notes, then link it from security, beta, and scorecard docs without changing contract logic.

**Tech Stack:** Markdown docs, Git, existing Track A research/security documentation.

---

## File Map

- Create `docs/research/track-a-storage-reserve-policy.md`: main policy document with estimates, assumptions, reserve tiers, and mainnet requirements.
- Modify `docs/security-model.md`: add storage policy evidence and explicit blockers for reserve sizing/history retention.
- Modify `docs/research/track-a-security-checklist.md`: add storage reserve and retention rows/follow-ups.
- Modify `docs/beta/architecture-scorecard.md`: add storage reserve caveat/evidence for Track A.
- Modify `docs/beta-test-plan.md`: add current progress and readiness task references for storage reserve policy.

---

### Task 1: Add Storage Reserve Policy Research Doc

**Files:**
- Create: `docs/research/track-a-storage-reserve-policy.md`

- [ ] **Step 1: Create the policy document**

Use `apply_patch` to create `docs/research/track-a-storage-reserve-policy.md` with exactly this content:

```markdown
# Track A Storage Reserve Policy

## Purpose

Define how Track A treats TON storage fees, reserve sizing, and proposal history retention before any mainnet candidate work continues.

This document is policy evidence, not an audit report. The estimates are based on current mainnet basechain storage parameters and an approximate state-size model from the deployed testnet Treasury after proposal `1`.

## Current Evidence

- Track A Treasury testnet address: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Current observed deployed state after proposal `1`: `45 cells`, `11094 bits`.
- Current MVP `feeReserve`: `0.1 TON`.
- Mainnet basechain storage parameters used for this estimate: `bit_price_ps = 1`, `cell_price_ps = 500`, `freeze_due_limit = 0.1 TON`, `delete_due_limit = 1 TON`.

## Storage Fee Estimates

| Scenario | Estimated State Size | 1 Year | 5 Years | 10 Years | Approx Freeze Time With Zero Balance |
|---|---:|---:|---:|---:|---:|
| Current state | `45 cells`, `11094 bits` | `0.016165473 TON` | `0.080827361 TON` | `0.161654722 TON` | `~6.18 years` |
| 10 proposals | `109 cells`, `23982 bits` | `0.037765631 TON` | `0.188828152 TON` | `0.377656304 TON` | `~2.65 years` |
| 100 proposals | `829 cells`, `168972 bits` | `0.280767411 TON` | `1.403837051 TON` | `2.807674102 TON` | `~130 days` |
| 1000 proposals | `8029 cells`, `1618872 bits` | `2.710785209 TON` | `13.553926041 TON` | `27.107852081 TON` | `~13 days` |

## Interpretation

- `0.1 TON` is acceptable for low-value MVP/testnet validation with a small number of proposals.
- `0.1 TON` is not enough for a mainnet treasury that keeps long-lived proposal history on-chain.
- At 100 retained proposals, a 10-year reserve estimate is already about `2.81 TON` before safety margin.
- At 1000 retained proposals, on-chain history retention is not a normal treasury design; it requires cleanup/indexer architecture or very high reserve.

## Reserve Tiers

| Tier | Intended Use | Recommended Reserve |
|---|---|---:|
| Testnet/MVP | low-value validation, few proposals | `0.1 TON` |
| Small mainnet treasury | bounded active proposals, low history | `0.5 TON` |
| Medium team treasury | up to about 100 retained proposals without cleanup | `3.5-4 TON` |
| High-history treasury | hundreds or thousands of retained proposals | avoid; require cleanup/indexer first |

These tiers are planning defaults, not immutable protocol constants. Before mainnet, regenerate the estimates from current network config and measured max-state sandbox fixtures.

## Retention Policy

Track A must not rely on unlimited on-chain proposal and approval history.

Mainnet candidate work must choose one of these paths before public launch:

- Keep only active or recently terminal proposals on-chain and prune terminal proposals after a safe visibility window.
- Store long-term user-facing history in an off-chain indexer, reproducible from transaction history.
- Raise `feeReserve` according to a measured max-state target and a documented retention window.

Recommended direction: hybrid retention. Keep security-critical active state on-chain, prune terminal proposal state after the product has indexed it, and keep full historical UX/audit views off-chain.

## Governance Note

`threshold` remains immutable in the Track A MVP. Changing `threshold`, owner set, or reserve policy changes the security model and must not be added as a normal payout proposal.

Future governance/config changes require a separate design with stronger approval rules, such as supermajority or unanimous approval, plus explicit UI warnings and potentially time locks.

## Mainnet Requirements

- Measure max-state cells/bits in deterministic sandbox tests.
- Decide retention policy: bounded on-chain history, cleanup/pruning, or indexer-backed history.
- Set `feeReserve` from measured max-state size and target reserve lifetime.
- Add monitoring/alerts for Treasury balance approaching reserve.
- Keep mainnet blocked until security review accepts the reserve and retention policy.

## Limitations

- Estimates are approximate and based on current observed Track A state plus linear scaling assumptions.
- Network config can change; values must be regenerated before mainnet release.
- This document does not implement cleanup, pruning, indexer behavior, or contract-level reserve changes.
```

- [ ] **Step 2: Confirm no placeholder text remains**

Run:

```powershell
git diff -- docs/research/track-a-storage-reserve-policy.md
```

Expected: the new file contains no placeholder language.

---

### Task 2: Update Security Documentation

**Files:**
- Modify: `docs/security-model.md`
- Modify: `docs/research/track-a-security-checklist.md`

- [ ] **Step 1: Link storage reserve evidence from security model**

In `docs/security-model.md`, under `Track A hardening evidence:`, add this bullet after the gas/fee baseline bullet:

```markdown
- Storage reserve policy: `docs/research/track-a-storage-reserve-policy.md`.
```

- [ ] **Step 2: Add storage reserve invariant**

In `docs/security-model.md`, in the `Invariants` table, add this row after `Fee reserve`:

```markdown
| Bounded on-chain history | Treasury does not rely on unlimited retained proposals/approvals |
```

- [ ] **Step 3: Add storage threat**

In `docs/security-model.md`, in the `Threats And Mitigations` table, add this row after `Replay`:

```markdown
| Storage exhaustion | reserve sizing, bounded retention, cleanup/indexer policy |
```

- [ ] **Step 4: Add mainnet blockers**

In `docs/security-model.md`, under `Mainnet is forbidden until all of these are complete:`, add these bullets after `Gas and fee implications are understood.`:

```markdown
- Storage reserve sizing is measured against max-state fixtures.
- On-chain history retention policy is approved.
```

- [ ] **Step 5: Update security checklist status table**

In `docs/research/track-a-security-checklist.md`, add these rows after `Reserve accounting`:

```markdown
| Storage reserve sizing | Policy recorded, needs measured max-state tests | See `docs/research/track-a-storage-reserve-policy.md`; regenerate estimates before mainnet. |
| Proposal history retention | Needs design before mainnet scale | Unbounded on-chain proposal/approval history is not acceptable for mainnet scale. |
```

- [ ] **Step 6: Update security checklist required checks**

In `docs/research/track-a-security-checklist.md`, add these rows after `Reserve invariant`:

```markdown
| Storage reserve policy | `feeReserve` is sized from measured max-state storage and target reserve lifetime. |
| History retention policy | Terminal proposal history is bounded on-chain or backed by a reproducible off-chain indexer. |
```

- [ ] **Step 7: Update known evidence**

In `docs/research/track-a-security-checklist.md`, add this bullet after the gas/fee baseline bullet:

```markdown
- Storage reserve policy and mainnet retention caveats: `docs/research/track-a-storage-reserve-policy.md`.
```

- [ ] **Step 8: Update mainnet blockers**

In `docs/research/track-a-security-checklist.md`, add this bullet after `Review recorded Track A gas/fee baseline and add rejection-path fee evidence before mainnet.`:

```markdown
- Measure max-state storage size and approve bounded history or cleanup/indexer strategy before mainnet.
```

---

### Task 3: Update Beta And Scorecard Docs

**Files:**
- Modify: `docs/beta/architecture-scorecard.md`
- Modify: `docs/beta-test-plan.md`

- [ ] **Step 1: Update scorecard gas/fees evidence**

In `docs/beta/architecture-scorecard.md`, change the `Gas/fees` row from:

```markdown
| Gas/fees | 15 | 3 | 0 | Real testnet balances, transaction links, and observed wallet-side costs are recorded for Track A create/approve/execute; no mainnet fee guarantee exists yet. |
```

to:

```markdown
| Gas/fees | 15 | 3 | 0 | Real testnet action costs and storage reserve policy are recorded for Track A; mainnet still needs measured max-state storage tests and retention policy approval. |
```

- [ ] **Step 2: Add scorecard evidence bullet**

In `docs/beta/architecture-scorecard.md`, add this bullet after the gas/fee baseline bullet:

```markdown
- Storage reserve policy and unbounded-history caveat: `docs/research/track-a-storage-reserve-policy.md`.
```

- [ ] **Step 3: Update current decision**

In `docs/beta/architecture-scorecard.md`, change the `Current Decision` paragraph to:

```markdown
Track A is validated enough to continue hardening and beta preparation on testnet. Mainnet remains blocked until the final source verification transaction, measured max-state storage reserve sizing, bounded history or cleanup/indexer policy, security review/audit readiness, and a release checklist are complete. Track B remains unscored until official multisig v2 is tested with comparable evidence.
```

- [ ] **Step 4: Update beta current progress**

In `docs/beta-test-plan.md`, under `Current Progress`, add this bullet after the security review checklist bullet:

```markdown
- Storage reserve policy is recorded in `docs/research/track-a-storage-reserve-policy.md`; mainnet reserve sizing still requires measured max-state tests.
```

- [ ] **Step 5: Update beta readiness tasks**

In `docs/beta-test-plan.md`, under `Next Beta Readiness Tasks`, add this bullet after `Review and resolve the Track A security checklist before beta expansion.`:

```markdown
- Measure max-state storage size and decide bounded on-chain history versus cleanup/indexer strategy before mainnet candidate work.
```

---

### Task 4: Verification And Commit

**Files:**
- Create: `docs/research/track-a-storage-reserve-policy.md`
- Modify: `docs/security-model.md`
- Modify: `docs/research/track-a-security-checklist.md`
- Modify: `docs/beta/architecture-scorecard.md`
- Modify: `docs/beta-test-plan.md`

- [ ] **Step 1: Run local whitespace check**

Run:

```powershell
git diff --check
```

Expected: no whitespace errors. Windows may show LF/CRLF warnings; warnings are acceptable if no whitespace errors are reported.

- [ ] **Step 2: Scan changed docs for accidental secrets and placeholders**

Use Grep or `rg` for:

```powershell
rg -n "T[B]D|T[O]DO|observed nanotons|wallets\.toml|mnemonic|private key|b5ee9c|Message body: [0-9a-f]{32,}" docs/research/track-a-storage-reserve-policy.md docs/security-model.md docs/research/track-a-security-checklist.md docs/beta/architecture-scorecard.md docs/beta-test-plan.md
```

Expected: no matches except legitimate references to avoiding secrets if any are already present in unchanged context. If a new placeholder or verifier payload appears, fix it before committing.

- [ ] **Step 3: Review final diff**

Run:

```powershell
git diff -- docs/research/track-a-storage-reserve-policy.md docs/security-model.md docs/research/track-a-security-checklist.md docs/beta/architecture-scorecard.md docs/beta-test-plan.md
```

Expected: diff only adds the storage reserve policy and related doc links/blockers.

- [ ] **Step 4: Commit doc implementation**

Run:

```powershell
git add -- docs/research/track-a-storage-reserve-policy.md docs/security-model.md docs/research/track-a-security-checklist.md docs/beta/architecture-scorecard.md docs/beta-test-plan.md
git commit -m "docs: record Track A storage reserve policy"
```

Expected: commit succeeds.

- [ ] **Step 5: Inspect branch status**

Run:

```powershell
git status --short --branch
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
```

Expected: branch contains the design spec commit, implementation plan commit, and doc implementation commit. Root checkout unrelated changes are not included.

---

### Task 5: Final PR

**Files:**
- No further file changes expected.

- [ ] **Step 1: Push branch**

Run:

```powershell
git push -u origin track-a-storage-reserve-policy
```

Expected: branch is pushed.

- [ ] **Step 2: Create PR**

Run:

```powershell
gh pr create --base main --head track-a-storage-reserve-policy --title "docs: record Track A storage reserve policy" --body @'
## Summary
- Add Track A storage reserve policy with mainnet storage estimates and reserve tiers.
- Document that unbounded on-chain proposal history is not acceptable for mainnet scale.
- Update security, beta, and scorecard docs with reserve sizing and retention-policy blockers.

## Test Plan
- `git diff --check`
- Checked changed docs for placeholders, secrets, and verifier payloads
- Documentation-only change; no contract logic modified
'@
```

Expected: PR URL is printed.
