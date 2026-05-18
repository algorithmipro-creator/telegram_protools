# Treasury Proposal Pruning Design

## Goal

Design Phase 4 for TreasuryFlow Track A: bounded on-chain proposal retention through explicit proposal pruning.

The Treasury contract must not become an on-chain archive. It stores only retained proposal state needed for current governance decisions. Historical timeline, comments, analytics, and long-term audit UX are the responsibility of off-chain indexers and UI.

## Security Position

Pruning is storage cleanup only. It must never change governance outcome.

The core invariant is:

```text
Only proposal records that can no longer affect treasury decisions may be removed from on-chain storage.
```

This phase exists because TON account storage fees depend on stored state size. Unbounded proposal and approval history makes long-lived mainnet treasury storage cost hard to reason about and can eventually create freeze/delete risk.

## Scope

In scope:

- manual owner-only `PruneProposal` design;
- proposal view statuses `Pruned` and `NotFound`;
- deterministic getter semantics without tombstones;
- prunable and non-prunable lifecycle states;
- approval cleanup requirements;
- retained proposal count and hard cap policy;
- invariants and test plan for Phase 4 implementation.

Out of scope:

- contract implementation in this design step;
- automatic pruning;
- batch pruning;
- permissionless pruning;
- prune rewards;
- on-chain history reconstruction;
- Telegram Mini App;
- backend or indexer implementation;
- Splitter;
- Jettons;
- arbitrary payload cleanup;
- mainnet readiness claims.

## Current Baseline

After Phase 3 governance/config work, Track A Treasury supports typed proposal kinds:

```text
PayoutTon
SetTreasuryConfig
```

Proposal IDs are globally monotonic through `proposalSeqno`. Proposals store `configVersionAtCreation`, and pending proposals from old config versions are derived as `Stale`. Stored terminal statuses are `Executed` and `Cancelled`; `Expired`, `Executable`, and `Stale` are computed view statuses.

Phase 4 must apply to all proposal kinds uniformly. Future proposal kinds, such as `SetSplitterConfig` or `ExecuteSplit`, must inherit the same pruning rules unless a later design explicitly changes them.

## Design Decisions

### Decision 1: Owner-Only Pruning In V1

Phase 4 v1 adds one typed state-changing message:

```text
PruneProposal {
    proposalId: uint64
}
```

Authorization:

```text
sender must be a current owner
```

Do not allow permissionless pruning in v1.

Reason: permissionless pruning can create UI/indexer race conditions and anti-griefing questions. Owner-only pruning is simpler, safer, and consistent with security-first treasury behavior.

Permissionless pruning may be reconsidered later only after off-chain indexing behavior, prune delays, and user-facing visibility rules are designed.

### Decision 2: Prunable States

Prunable:

```text
Executed
Cancelled
Expired
Stale
```

Not prunable:

```text
Pending current version
Executable current version
Pruned
NotFound
```

Rationale:

- `Executed` and `Cancelled` are terminal stored outcomes.
- `Expired` proposals can no longer approve or execute.
- `Stale` proposals were invalidated by config change and can no longer approve, execute, or cancel.
- `Pending` proposals still represent active governance.
- `Executable` proposals must not be hidden after threshold has been reached.

For simplicity, Phase 4 should reject additional approvals once a proposal is already executable. Reputation-style extra approvals belong off-chain.

### Decision 3: Status Priority

Getter and lifecycle checks must use this status priority:

```text
1. NotFound
2. Pruned
3. Executed
4. Cancelled
5. Stale
6. Expired
7. Executable
8. Pending
```

Rules:

```text
if proposalId >= proposalSeqno:
    NotFound

if proposalId < proposalSeqno and proposal record is missing:
    Pruned

if stored status == Executed:
    Executed

if stored status == Cancelled:
    Cancelled

if proposal.configVersionAtCreation != storage.configVersion:
    Stale

if now >= proposal.expiresAt:
    Expired

if approvalCount >= requiredThreshold(proposal.kind):
    Executable

else:
    Pending
```

`Executed` and `Cancelled` remain terminal and are not reclassified as stale after later config changes.

`Stale` has priority over `Expired` because config-version mismatch is the stronger governance reason that the proposal cannot continue.

### Decision 4: Pruned Versus NotFound Without Tombstones

Do not store tombstones.

Getter semantics:

```text
proposalId >= proposalSeqno
    -> NotFound

proposalId < proposalSeqno and proposal record is absent
    -> Pruned

proposalId < proposalSeqno and proposal record exists
    -> computed view status and retained proposal data
```

This requires monotonic proposal IDs with no reuse. `proposalSeqno` is never decremented.

Reason: tombstones would recreate the same on-chain archive problem that pruning is meant to solve.

### Decision 5: Approvals Must Be Pruneable By Construction

Phase 4 must not leave orphan approval state.

Preferred storage model:

```text
Proposal {
    ...
    approvalMask: uint16
    approvalCount: uint8
    ...
}
```

With `MAX_OWNER_COUNT = 10`, a bitmask is small and bounded. Pruning one proposal record removes the proposal and its approvals together.

Implementation requirement:

```text
Approvals must live inside the proposal record or the proposal must store enough data to delete every approval key deterministically during prune.
```

If approvals remain in a separate global map, the proposal must store an owner snapshot or approved-owner list sufficient to delete all approval keys from the proposal's creation context.

Deleting approval keys only for current owners is invalid. Example:

```text
Proposal #10 created with owners A, B, C
Config changes owners to A, D, E
Proposal #10 becomes Stale
Prune using current owners A, D, E would leave orphan approvals for B and C
```

Therefore, Phase 4 implementation must first make approval cleanup deterministic.

### Decision 6: Hard Cap On Retained Proposals

Phase 4 should add bounded retained state:

```text
MAX_RETAINED_PROPOSALS = 100
retainedProposalCount
```

Rules:

Rules:

```text
create proposal:
    require retainedProposalCount < MAX_RETAINED_PROPOSALS
    retainedProposalCount += 1

prune proposal:
    require proposal exists and is prunable
    delete proposal record and associated approvals
    retainedProposalCount -= 1
```

`proposalSeqno` continues to increase monotonically and is not affected by pruning.

The v1 cap is intentionally conservative. Existing storage reserve research shows that hundreds or thousands of retained proposals make mainnet reserve policy harder to reason about. The implementation must include deterministic storage and gas evidence for the 100-retained-proposal fixture. If evidence shows the cap is still too high for the target reserve policy, reduce the cap before merging Phase 4 implementation.

## Prune Semantics

`PruneProposal` must:

- require sender to be a current owner;
- require the proposal record to exist;
- compute proposal view status;
- allow only `Executed`, `Cancelled`, `Expired`, or `Stale`;
- reject `Pending`, `Executable`, `Pruned`, and `NotFound`;
- delete the proposal record;
- delete all approvals associated with the proposal;
- decrement `retainedProposalCount` if the counter is implemented.

`PruneProposal` must not:

- change `proposalSeqno`;
- change `configVersion`;
- change owners;
- change `payoutThreshold`;
- change `configThreshold`;
- change `configThresholdMutable`;
- change `feeReserve`;
- send TON;
- create a proposal;
- revive or mutate a terminal proposal;
- remove active proposal state.

The only balance impact should be ordinary transaction fees.

## Lifecycle Matrix

| View status | Approve | Execute | Cancel | Prune | Reason |
|---|---|---|---|---|---|
| Pending current version | Yes | No | Yes, creator only and not executable | No | Active governance |
| Executable current version | No | Yes | No | No | Threshold reached; cannot hide ready decision |
| Executed | No | No | No | Yes | Outcome already happened |
| Cancelled | No | No | No | Yes | Outcome closed |
| Expired | No | No | No | Yes | Activity impossible |
| Stale | No | No | No | Yes | Config changed |
| Pruned | No | No | No | No | Record removed |
| NotFound | No | No | No | No | Proposal never existed |

## Getter Requirements

Add or update getters:

```text
proposal(id)
proposal_status(id)
can_prune(id)
retained_proposal_count()
proposal_seqno()
has_approval(id, owner)
```

After prune:

```text
proposal(id) -> status Pruned, empty payload
proposal_status(id) -> Pruned
can_prune(id) -> false
has_approval(id, owner) -> Pruned or ProposalPruned error
```

For `proposalId >= proposalSeqno`:

```text
proposal(id) -> status NotFound, empty payload
proposal_status(id) -> NotFound
can_prune(id) -> false
has_approval(id, owner) -> NotFound or ProposalNotFound error
```

`has_approval(id, owner)` must not return plain `false` for `Pruned` or `NotFound`, because that would make UI look like the owner did not approve a retained proposal. The proposal does not exist as active retained state.

## Errors

Phase 4 should add or preserve:

```text
Errors.ProposalNotFound
Errors.ProposalPruned
Errors.ProposalNotPrunable
Errors.NotOwner
Errors.InsufficientMessageValue
```

If the implementation keeps a compact error surface, `ProposalPruned` and `ProposalNotFound` may share a low-level missing-record path internally, but public getters should still distinguish `Pruned` from `NotFound`.

## Invariants

- Active proposal state cannot be pruned.
- Executable proposal state cannot be pruned.
- Prune cannot change governance outcome.
- Prune cannot reset approvals for active proposals.
- Prune cannot change owners.
- Prune cannot change thresholds.
- Prune cannot change `configVersion`.
- Prune cannot change `proposalSeqno`.
- Prune cannot change `feeReserve`.
- Prune cannot send funds.
- Stale and expired proposals cannot be revived.
- Pruned proposals cannot be approved, executed, cancelled, or pruned again.
- Proposal IDs remain monotonic and are never reused.
- Missing proposal IDs below `proposalSeqno` are treated as `Pruned`, not `NotFound`.
- Approvals are deleted with the pruned proposal or are otherwise deterministically deleted without orphan state.

## Attack Scenarios Covered

### Hide Active Vote

Blocked. Pending current-version proposals are not prunable.

### Hide Executable Proposal

Blocked. Executable current-version proposals are not prunable.

### Reset Approvals

Blocked. Prune applies only to proposals that can no longer approve or execute. Active proposals cannot be pruned.

### Orphan Approval State After Owner Change

Blocked by construction. Approvals must live inside proposal records or be deterministically deleteable from proposal-local data.

### Reuse Pruned Proposal ID

Blocked. `proposalSeqno` is monotonic and pruning does not decrement it.

### Forge Pruned Status

Blocked. `Pruned` is derived from missing proposal record plus `proposalId < proposalSeqno`. No message can directly mark an active proposal as pruned without passing pruning authorization and lifecycle checks.

## Off-Chain Responsibility

UI and indexers must not treat on-chain proposal getters as permanent history.

Off-chain systems are responsible for:

- saving proposal snapshots at creation;
- saving approval/update events;
- saving terminal and prune events;
- showing full timeline and comments;
- reconstructing history from transactions when possible;
- distinguishing retained on-chain state from archived product history.

The contract remains the source of truth for current authorization and retained proposal state, not for product archive UX.

## Phase 4 Test Plan

Authorization tests:

- non-owner cannot prune;
- current owner can prune a prunable proposal.

Executed proposal tests:

- executed payout proposal can be pruned;
- executed config proposal can be pruned;
- pruned executed proposal getter returns `Pruned`;
- pruned executed proposal cannot execute again.

Cancelled proposal tests:

- cancelled proposal can be pruned;
- pruned cancelled proposal getter returns `Pruned`;
- pruned cancelled proposal cannot be approved or executed.

Expired proposal tests:

- expired proposal can be pruned;
- expired proposal cannot be approved before prune;
- expired proposal cannot be executed before prune;
- pruned expired proposal getter returns `Pruned`.

Stale proposal tests:

- config change makes old pending payout proposal `Stale`;
- config change makes old pending config proposal `Stale`;
- stale proposal can be pruned;
- stale proposal cannot be approved before prune;
- stale proposal cannot be executed before prune;
- pruned stale proposal getter returns `Pruned`.

Active protection tests:

- pending current-version proposal cannot be pruned;
- executable current-version payout proposal cannot be pruned;
- executable current-version config proposal cannot be pruned;
- executable proposal rejects additional approvals if Phase 4 adopts no-extra-approvals semantics.

Getter tests:

- `proposalId >= proposalSeqno` returns `NotFound`;
- `proposalId < proposalSeqno` and missing record returns `Pruned`;
- retained proposal returns its computed lifecycle status;
- `has_approval` on pruned proposal returns `Pruned` or throws `ProposalPruned`;
- `has_approval` on never-created proposal returns `NotFound` or throws `ProposalNotFound`.

Approval cleanup tests:

- approvals are removed with pruned proposal;
- no orphan approvals remain after pruning a stale proposal created under an old owner set;
- pruning does not affect approvals on another retained proposal.

Counter and cap tests:

- `retainedProposalCount` increments on payout proposal creation;
- `retainedProposalCount` increments on config proposal creation;
- `retainedProposalCount` decrements on prune;
- `retainedProposalCount` does not decrement twice;
- create is rejected when `retainedProposalCount >= MAX_RETAINED_PROPOSALS`;
- prune frees one retained slot and a later create can use it.

Governance invariant tests:

- prune does not change `configVersion`;
- prune does not change owners;
- prune does not change `payoutThreshold`;
- prune does not change `configThreshold`;
- prune does not change `feeReserve`;
- prune does not change `proposalSeqno`;
- prune does not send TON.

Storage and gas tests:

- storage sizing fixture records max retained proposal count;
- pruning reduces retained state size in deterministic sandbox evidence;
- gas snapshot records prune success and rejection paths.

## Documentation Updates For Implementation

When implemented, update:

- `docs/security-model.md`;
- `docs/research/track-a-security-checklist.md`;
- `docs/research/track-a-storage-reserve-policy.md`;
- gas baseline docs or snapshot artifacts;
- generated wrappers and getter docs.

Docs must continue to state that mainnet is blocked pending security review or audit.

## Acceptance Criteria

Phase 4 design is complete when:

- prunable and non-prunable states are unambiguous;
- owner-only authorization is accepted for v1;
- `Pruned` and `NotFound` getter semantics are defined without tombstones;
- approval cleanup is pruneable by construction;
- retained proposal cap policy is fixed at `MAX_RETAINED_PROPOSALS = 100` for v1;
- test plan covers approval cleanup, stale proposals, active proposal protection, and storage/gas evidence;
- no contract implementation has started from this design step.
