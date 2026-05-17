# Treasury Governance Config Proposal Design

## Goal

Design Phase 2 for TreasuryFlow Track A: governance and config proposals for safely changing owners, payout threshold, config threshold, and fee reserve.

This phase is design only. It does not implement contract changes.

## Security Position

Governance changes are financial security events. A malicious or mistaken config update can change who controls the treasury, how many approvals are required, and how much reserve must remain in the contract.

The core invariant is:

```text
No treasury authority can be changed except by the current owners under the current config rules.
```

The proposed config has no authority until the config proposal is executed. New owners cannot approve the proposal that adds them. Removed owners keep their authority until the proposal removing them is executed. Old pending proposals become stale after any successful config change.

## Scope

In scope:

- `SetTreasuryConfigProposal` design.
- `configVersion` design.
- stale proposal semantics.
- separate payout and config thresholds.
- deployment-time `configThresholdMutable` lock.
- owner set validation.
- threshold validation.
- fee reserve validation.
- getter and UI preview requirements.
- test plan for Phase 3 implementation.

Out of scope:

- implementation in Tolk.
- Telegram Mini App.
- backend or indexer.
- Splitter.
- Jettons.
- arbitrary payload execution.
- Track B official multisig integration.
- storage pruning or retention implementation.
- mainnet readiness claims.

## Current Core Baseline

Track A Treasury Core v0.1 currently supports:

- immutable owners after deploy;
- immutable threshold after deploy;
- TON payout proposals only;
- creator auto-approval;
- owner approvals;
- execute and cancel paths;
- fee reserve check based on pre-inbound balance;
- bounded owner count;
- minimum inbound values;
- maximum proposal expiry;
- Treasury self-recipient rejection;
- action-phase payout evidence tests.

Phase 2 changes the design from immutable config to governed config, but only through typed config proposals.

## Design Decisions

### Decision 1: Atomic Config Proposal

Use one typed proposal:

```text
SetTreasuryConfigProposal
```

It updates the full security-relevant config atomically:

```text
newOwners
newOwnerCount
newPayoutThreshold
newConfigThreshold
newFeeReserve
expiresAt
configVersionAtCreation
```

Do not implement separate `AddOwner`, `RemoveOwner`, `ChangeThreshold`, or `SetFeeReserve` proposal types in the first governance implementation.

Reason: separate partial actions can create unsafe intermediate states. Atomic config replacement validates the final state before any state mutation.

### Decision 2: Separate Payout And Config Thresholds

Storage should evolve from one `threshold` into:

```text
payoutThreshold
configThreshold
```

Rules:

```text
1 <= payoutThreshold <= ownerCount
payoutThreshold <= configThreshold <= ownerCount
```

Payout proposals require `payoutThreshold`.

Config proposals require `configThreshold`.

This lets a treasury choose, for example:

```text
Owners: A, B, C
payoutThreshold: 2
configThreshold: 3
```

Two owners can approve a payout, but all three must approve changes to owners, thresholds, or fee reserve.

### Decision 3: Deployment-Time Config Threshold Lock

Each treasury chooses at deploy:

```text
configThresholdMutable: bool
```

If `configThresholdMutable == false`, `configThreshold` is immutable forever.

If `configThresholdMutable == true`, `configThreshold` can be changed only through `SetTreasuryConfigProposal`, approved under the current `configThreshold`.

The flag itself is immutable. It must not be included in `SetTreasuryConfigProposal`.

Default product posture:

```text
configThresholdMutable = false
```

This default makes the config approval rule the treasury constitution. Teams that need flexibility can explicitly opt into mutability at deploy.

### Decision 4: Config Version And Stale Proposals

Storage adds:

```text
configVersion: uint32
```

Initial deploy value:

```text
configVersion = 0
```

Every successful `SetTreasuryConfigProposal` execution increments `configVersion` by one.

Every proposal stores:

```text
configVersionAtCreation
```

A pending proposal is stale when:

```text
proposal.configVersionAtCreation != storage.configVersion
```

`Stale` is not a stored proposal status and cannot be supplied by any message. It is a derived execution and view condition computed only from `proposal.configVersionAtCreation` and `storage.configVersion`.

Only successful `SetTreasuryConfigProposal` execution may increment `storage.configVersion`. No owner, non-owner, proposal creator, approver, UI, backend, or Telegram integration can directly mark a proposal stale.

Stale pending proposals cannot be approved, executed, or cancelled. They remain visible through getters for auditability until Phase 4 defines retention and cleanup.

Terminal proposals remain terminal:

```text
Executed
Cancelled
```

Terminal status takes precedence over stale status.

For pending proposals, view status order is:

```text
Stale
Expired
Executable
Pending
```

### Decision 5: Typed Governance Only

Do not add arbitrary payload governance.

Allowed proposal kinds for Phase 3:

```text
PayoutTon
SetTreasuryConfig
```

No config proposal may execute a raw cell, arbitrary destination call, or untyped action.

## Proposed Storage Shape

Phase 3 should evolve storage toward:

```text
struct Storage {
    ownerCount: uint8
    payoutThreshold: uint8
    configThreshold: uint8
    configThresholdMutable: bool
    configVersion: uint32
    proposalSeqno: uint64
    feeReserve: coins
    owners: map<address, uint8>
    payoutProposals: map<uint64, Cell<PayoutProposal>>
    configProposals: map<uint64, Cell<ConfigProposal>>
    approvals: map<uint256, uint8>
}
```

The existing testnet contract is not mainnet state. A storage schema migration is acceptable for Phase 3 as long as wrappers, tests, and deploy scripts are regenerated and documented.

## Proposed Proposal Shapes

### Payout Proposal

```text
struct PayoutProposal {
    id: uint64
    creator: address
    recipient: address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    status: ProposalStatus
    approvalCount: uint8
}
```

Payout approval and execution use `payoutThreshold`.

### Config Proposal

```text
struct ConfigProposal {
    id: uint64
    creator: address
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
    newOwners: map<address, uint8>
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    status: ProposalStatus
    approvalCount: uint8
}
```

Config approval and execution use `configThreshold`.

## Config Validation

The final proposed config must pass all checks before storage is mutated:

```text
MIN_OWNER_COUNT <= newOwnerCount <= MAX_OWNER_COUNT
newOwnerMapCount == newOwnerCount
1 <= newPayoutThreshold <= newOwnerCount
newPayoutThreshold <= newConfigThreshold <= newOwnerCount
newFeeReserve >= MIN_FEE_RESERVE
```

If the treasury was deployed with:

```text
configThresholdMutable == false
```

then:

```text
newConfigThreshold == currentConfigThreshold
```

If this check fails, execution and creation should reject with a dedicated error such as:

```text
ConfigThresholdLocked
```

Phase 3 should introduce `MIN_FEE_RESERVE`. Initial policy should use the current `DEFAULT_FEE_RESERVE` as the minimum unless storage reserve research approves a different value.

## Authority Rules

### Create Payout Proposal

Required:

- sender is current owner;
- current storage config is valid;
- minimum inbound value is met;
- payout fields are valid;
- proposal stores current `configVersion`.

Creator auto-approval remains acceptable for payout proposals.

### Create Config Proposal

Required:

- sender is current owner;
- current storage config is valid;
- minimum inbound value is met;
- proposed config is valid;
- proposal stores current `configVersion`.

Creator auto-approval is acceptable for config proposals because the creator is a current owner and execution still requires `configThreshold`.

### Approve Payout Proposal

Required:

- sender is current owner;
- proposal is pending;
- proposal is not stale;
- proposal is not expired;
- sender has not approved this proposal.

Approval increments payout proposal approval count by one.

### Approve Config Proposal

Required:

- sender is current owner;
- proposal is pending;
- proposal is not stale;
- proposal is not expired;
- sender has not approved this proposal.

Approval increments config proposal approval count by one.

New proposed owners cannot approve until after the config proposal executes.

### Execute Payout Proposal

Required:

- sender is current owner;
- proposal is pending;
- proposal is not stale;
- proposal is not expired;
- approval count is at least current `payoutThreshold`;
- pre-inbound balance preserves `feeReserve`.

Execution marks the proposal `Executed` and sends the TON payout.

### Execute Config Proposal

Required:

- sender is current owner;
- proposal is pending;
- proposal is not stale;
- proposal is not expired;
- approval count is at least current `configThreshold`;
- proposed config validates against current governance rules.

Execution order:

1. Load storage.
2. Validate current config.
3. Load proposal.
4. Validate proposal lifecycle.
5. Validate approval count against current `configThreshold`.
6. Validate proposed config.
7. Mark proposal `Executed`.
8. Replace owners, owner count, payout threshold, config threshold if mutable, and fee reserve.
9. Increment `configVersion`.
10. Save storage.

This order prevents partially applied config changes.

### Cancel Proposal

Existing cancel semantics can remain:

- sender is current owner;
- sender is proposal creator;
- proposal is pending;
- proposal is not stale;
- proposal is not expired;
- proposal is not already executable under the relevant current threshold.

For payout proposals, executable means approval count is at least `payoutThreshold`.

For config proposals, executable means approval count is at least `configThreshold`.

## Approval Key Design

Phase 3 should include proposal kind in approval keys:

```text
approvalKey(proposalKind, proposalId, owner)
```

This avoids ambiguity if proposal maps are separated by type and preserves clarity for audits.

Proposal IDs should remain globally monotonic through one `proposalSeqno`, shared by payout and config proposals.

## View And Getter Requirements

Future UI and review tools need clear typed views. They must not decode raw storage for security-critical previews.

Required getters:

```text
owner_count()
payout_threshold()
config_threshold()
config_threshold_mutable()
config_version()
proposal_seqno()
fee_reserve()
is_owner(address)
payout_proposal(id)
config_proposal(id)
has_approval(proposalKind, id, owner)
```

View status should include:

```text
Pending
Executable
Executed
Cancelled
Expired
Stale
```

Config proposal view should expose a clear preview:

```text
currentOwnerCount
newOwnerCount
currentPayoutThreshold
newPayoutThreshold
currentConfigThreshold
newConfigThreshold
currentFeeReserve
newFeeReserve
configVersionAtCreation
currentConfigVersion
status
approvalCount
requiredApprovalCount
```

Off-chain UI may additionally compute:

- added owners;
- removed owners;
- unchanged owners;
- threshold changes.

These previews are UI helpers only. They must not affect on-chain execution.

## Attack Scenarios Covered

### Add Owner And Use Them Immediately

Blocked. Proposed owners are not current owners and cannot approve before execution.

### Remove Owner After Their Approval

Old proposals become stale after config execution. Removed owner approvals on old pending proposals no longer help.

### Lower Config Threshold With Too Few Votes

Blocked. Changing `configThreshold` requires the current `configThreshold`. If `configThresholdMutable` is false, changing it is impossible.

### Parallel Config Proposals

The first executed config proposal increments `configVersion`. Other pending config proposals created on the old version become stale.

### Lower Fee Reserve Below Safe Minimum

Blocked by `newFeeReserve >= MIN_FEE_RESERVE`.

### Arbitrary Payload Governance

Blocked by scope. Only typed `SetTreasuryConfigProposal` is allowed.

### Off-Chain UI Spoofing

On-chain sender validation, typed messages, getters, and generated wrappers remain the source of truth. Telegram, backend, or cached metadata cannot grant owner rights.

## Phase 3 Test Plan

Config validation tests:

- deploy rejects `payoutThreshold = 0`;
- deploy rejects `configThreshold = 0`;
- deploy rejects `payoutThreshold > ownerCount`;
- deploy rejects `configThreshold > ownerCount`;
- deploy rejects `configThreshold < payoutThreshold`;
- config proposal rejects duplicate owners;
- config proposal rejects owner count below minimum;
- config proposal rejects owner count above maximum;
- config proposal rejects fee reserve below minimum.

Config proposal lifecycle tests:

- owner creates config proposal with creator auto-approval;
- non-owner cannot create config proposal;
- second owner approves config proposal;
- duplicate config approval is rejected;
- config proposal is executable only at `configThreshold`;
- executable config proposal cannot be cancelled;
- executed config proposal cannot execute twice;
- expired config proposal cannot be approved;
- expired config proposal cannot be executed.

Config execution tests:

- execution atomically updates owners, owner count, payout threshold, config threshold when mutable, fee reserve, and config version;
- execution rejects config threshold change when `configThresholdMutable` is false;
- execution allows config threshold change when `configThresholdMutable` is true and current `configThreshold` is met;
- removed owner cannot approve new proposals after execution;
- added owner can approve new proposals after execution;
- old payout proposal becomes stale after config execution;
- old config proposal becomes stale after another config execution;
- stale proposal cannot be approved;
- stale proposal cannot be executed;
- stale proposal cannot be created or forced by a message field;
- stale status is derived from `configVersionAtCreation` and current `configVersion`, not stored as mutable proposal state;
- stale proposal view status is `Stale`.

Payout compatibility tests:

- payout proposal still requires `payoutThreshold`;
- payout execution still uses pre-inbound balance for reserve check;
- minimum inbound value checks still apply;
- action-phase payout evidence still passes.

Getter and wrapper tests:

- getters expose payout threshold, config threshold, mutability flag, config version, and typed proposal views;
- generated wrappers expose new messages, statuses, errors, and getters.

## Documentation Updates For Phase 3

When implemented, update:

- `docs/security-model.md`;
- `docs/research/track-a-security-checklist.md`;
- gas baseline docs or snapshot artifacts;
- storage reserve docs if config proposal state materially changes storage size.

Docs must continue to state that mainnet is blocked pending security review or audit.

## Non-Goals For Implementation Plan

The Phase 3 implementation plan must not include:

- Telegram integration;
- Splitter;
- Jettons;
- backend/indexer;
- arbitrary payload execution;
- storage pruning;
- Track B adapter;
- mainnet release work.

## Acceptance Criteria For Phase 2

Phase 2 is complete when:

- this design is reviewed and accepted;
- the security invariants are clear;
- the test plan is accepted;
- no contract implementation has started;
- Phase 3 can be planned as a separate implementation task.
