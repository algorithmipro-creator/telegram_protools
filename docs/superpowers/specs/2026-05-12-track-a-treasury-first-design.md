# Track A Treasury-First Design

## 1. Purpose

This design defines the first Track A implementation target for TreasuryFlow TON: a custom Tolk treasury prototype focused only on the core N-of-M TON payout loop.

The goal is to validate the security-critical approval and execution lifecycle before adding Splitter, frontend, backend, or official multisig v2 integration.

## 2. Scope

In scope for this prototype:

- Acton project scaffold.
- One custom `Treasury.tolk` contract.
- Treasury owners.
- Approval threshold.
- TON payout proposals.
- Creator auto-approval.
- Owner approvals.
- Proposal expiry.
- Proposal cancellation.
- Execute TON payout after threshold.
- Public approval tracking.
- Getters needed by tests and future wrappers.
- Acton tests for core invariants.
- TypeScript wrapper generation path.
- Local/testnet deployment script path.

Out of scope:

- Splitter contract.
- Jetton payouts.
- Telegram Mini App frontend.
- Backend/indexer.
- Official multisig v2 adapter.
- Anonymous/ZK approvals.
- Mainnet deployment.

## 3. Architecture Decision

Use a single custom Treasury contract for the first Track A prototype.

```text
Treasury.tolk
  |
  |-- owners
  |-- threshold
  |-- proposal_seqno
  |-- payout proposals
  |-- approvals per proposal
  |-- execute TON payout
```

This avoids separate proposal/order contracts in the first prototype. Separate contracts are deferred until after the payout lifecycle is tested.

## 4. Contract Responsibilities

`Treasury.tolk` is responsible for:

- Storing owner addresses.
- Enforcing threshold rules.
- Accepting TON deposits.
- Creating payout proposals.
- Recording creator auto-approval.
- Recording additional owner approvals.
- Preventing duplicate approvals.
- Enforcing proposal expiry.
- Preventing double execution.
- Sending TON payout messages after threshold.
- Exposing read-only getters.

The contract must not trust frontend/backend for financial correctness.

## 5. Storage Model

Recommended logical storage:

| Field | Meaning |
|---|---|
| `owners` | Owner address set/map |
| `owner_count` | Number of owners |
| `threshold` | Minimum approvals required |
| `proposal_seqno` | Next proposal ID |
| `proposals` | Map: proposal ID to proposal data |
| `fee_reserve` | Minimum TON reserve retained by Treasury |

Recommended logical proposal data:

| Field | Meaning |
|---|---|
| `id` | Proposal ID |
| `creator` | Owner who created proposal |
| `recipient` | TON payout recipient |
| `amount` | TON payout amount |
| `created_at` | Creation timestamp or logical time available to contract |
| `expires_at` | Expiry timestamp |
| `status` | Pending, executed, cancelled, expired-derived |
| `approval_count` | Number of unique owner approvals |
| `approvals` | Owner approval map/bitmap |

The implementation plan will choose the exact Tolk dictionary/cell representation while preserving this logical model.

## 6. Messages

| Message | Sender | Purpose |
|---|---|---|
| `CreatePayoutProposal` | Owner | Create payout proposal and auto-approve creator |
| `ApproveProposal` | Owner | Approve existing pending proposal |
| `ExecuteProposal` | Owner | Execute proposal after threshold |
| `CancelProposal` | Creator or owner policy | Cancel pending proposal before execution |
| plain TON transfer | Any sender | Deposit TON into treasury |

No arbitrary action payloads are included in this prototype. Only TON payout proposals are supported.

## 7. Proposal Lifecycle

```text
created
  |
  v
pending
  |
  +-- approval_count >= threshold --> executable-derived
  |
  +-- cancel ----------------------> cancelled
  |
  +-- expires_at passed -----------> expired-derived
  |
  v
executed
```

The contract stores terminal statuses and derives `expired`/`executable` from current time, expiry, and approval count.

Required stored statuses:

- `pending`
- `executed`
- `cancelled`

Derived statuses for getters/UI:

- `executable`
- `expired`

## 8. Approval Policy

Creator auto-approves the proposal.

Rationale:

- Creating a payout request means the creator supports it.
- Small Telegram-team UX is faster.
- UI can immediately show the creator in approval list.

Rules:

- Non-owner cannot create proposals.
- Non-owner cannot approve proposals.
- Creator approval is counted exactly once.
- Duplicate approval does not increase `approval_count`.
- Approval after execution, cancellation, or expiry is rejected.

Approvals are public and tied to owner addresses in the MVP.

## 9. Execution Policy

Execution rules:

- Only owners can execute in the first prototype.
- Proposal must exist.
- Proposal must not be cancelled.
- Proposal must not be executed.
- Proposal must not be expired.
- `approval_count >= threshold` must hold.
- Treasury balance must be enough for `amount + fee_reserve`.
- Successful execution marks proposal as executed before or atomically with payout send according to safe TON message semantics.

The first prototype should prefer conservative behavior over convenience.

## 10. Cancellation Policy

For the first prototype, cancellation is intentionally narrow:

- Creator can cancel only while proposal is pending and not executable.
- Executed proposals cannot be cancelled.
- Expired proposals do not need cancellation.

Owner-majority cancellation can be considered later as a separate proposal type.

## 11. Security Invariants

The prototype must test these invariants:

| Invariant | Requirement |
|---|---|
| Owner-only proposal creation | Non-owner cannot create payout proposal |
| Creator auto-approval | Creator is counted once on creation |
| Owner-only approval | Non-owner cannot approve |
| No duplicate approvals | Duplicate approval does not increase count |
| Threshold required | Execution before threshold is rejected |
| Expiry enforced | Expired proposal cannot be approved or executed |
| No double execution | Executed proposal cannot execute again |
| Fee reserve | Treasury cannot drain below reserve |
| Public accountability | Approval list/getter exposes approving owners |

## 12. Anonymous / ZK Voting Decision

Anonymous or ZK approvals are out of scope for Track A Treasury MVP.

Reasoning:

- Treasury payout approvals need accountability.
- ZK proof verification on TON/TVM requires separate feasibility research.
- Nullifier-based double-vote prevention would significantly increase complexity.
- The first prototype must validate basic financial safety first.

Future extension:

- DAO private voting is a future research track for non-financial governance votes.
- Possible approaches include commit-reveal voting, anonymous owner voting with nullifiers, or ZK membership proofs.
- This future work must have a separate threat model, proof-system decision, implementation plan, and audit path.

## 13. Testing Strategy

Initial Acton tests should cover:

- Treasury deployment with valid owners and threshold.
- Reject duplicate owners.
- Reject invalid threshold.
- Accept TON deposit.
- Owner creates payout proposal.
- Creator auto-approval is recorded.
- Non-owner cannot create proposal.
- Owner approves proposal.
- Non-owner cannot approve.
- Duplicate approval does not increase count.
- Execute before threshold fails.
- Execute after threshold succeeds.
- Execute after expiry fails.
- Execute twice fails.
- Cancel pending non-executable proposal succeeds.
- Cancel executable or executed proposal fails.
- Insufficient balance or fee reserve violation fails.

Fuzz tests are part of the follow-up hardening step after deterministic unit tests pass:

- Random owner count and threshold validity.
- Random approval order with duplicates.
- Random payout amounts against reserve.

## 14. Acton Workflow

Expected workflow for implementation:

```text
acton new treasury-flow-ton --template counter --app
replace counter contract with Treasury.tolk
acton build
acton test
acton wrapper --all --ts
acton script scripts/deploy_treasury_testnet.tolk --net testnet
```

The implementation plan must validate these commands against the installed Acton version before relying on them in automation.

## 15. Acceptance Criteria

The Track A Treasury-first prototype is acceptable when:

- Acton project builds.
- Core Treasury tests pass.
- Generated wrappers can be produced.
- Local deployment script can construct initial Treasury state.
- No Splitter code is required for this milestone.
- Anonymous/ZK voting is documented as future research only.
- Mainnet remains blocked.
