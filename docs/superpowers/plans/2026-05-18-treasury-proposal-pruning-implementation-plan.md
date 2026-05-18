# Treasury Proposal Pruning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement bounded proposal retention and owner-only pruning without leaving orphan approval state.

**Architecture:** Replace global approval records with proposal-local approval masks, add retained proposal counting and `PruneProposal`, and make getters distinguish retained, pruned, and never-created proposal IDs. Pruning deletes one proposal record only when the computed status is `Executed`, `Cancelled`, `Expired`, or `Stale`; it never changes governance config or sends funds.

**Tech Stack:** Tolk smart contract, Acton 1.0.0, generated Tolk/TypeScript wrappers, deterministic Acton tests, TON testnet smoke scripts.

---

## Source Design

Implement this accepted design:

`docs/superpowers/specs/2026-05-18-treasury-proposal-pruning-design.md`

Do not implement Telegram, Splitter, Jettons, backend/indexer, permissionless pruning, batch pruning, prune rewards, arbitrary payload cleanup, or mainnet release work.

## File Structure

Modify:

- `contracts/types.tolk`: constants, errors, storage schema, proposal schema, owner index helpers, approval mask helpers, status/view helpers, `PruneProposal` message.
- `contracts/Treasury.tolk`: creation cap, approval mask mutation, prune message handling, `Pruned`/`NotFound` getter semantics.
- `tests/contract.test.tolk`: TDD tests for approval-mask migration, retained count/cap, pruning authorization, prunable states, active-state protection, getter semantics, and invariants.
- `scripts/deploy.tolk`: initialize owner indices and `retainedProposalCount`.
- `scripts/testnet-governance-smoke.tolk`: initialize owner indices and `retainedProposalCount`.
- `wrappers/Treasury.gen.tolk`: regenerate only with `acton wrapper Treasury`.
- `wrappers-ts/Treasury.gen.ts`: regenerate only with Acton wrapper tooling.
- `gas-baseline.json`: regenerate snapshot after implementation.
- `docs/security-model.md`: mark pruning implementation evidence.
- `docs/research/track-a-security-checklist.md`: update retention status after tests pass.
- `docs/research/track-a-storage-reserve-policy.md`: link Phase 4 and note the v1 cap.

Create:

- no new contract modules in v1; keep the implementation inside the current Treasury core.

## Implementation Rules

- Keep `ProposalViewStatus` existing numeric values stable; append `Pruned` and `NotFound`.
- Store approvals inside `Proposal` as `approvalMask: uint16` in Task 2.
- Keep `approvalCount: uint8` for threshold checks and UI.
- Change `owners: map<address, uint8>` semantics: the value is now a stable owner index `0..ownerCount-1`.
- Remove `approvals: map<uint256, uint8>` from `Storage` in Task 2.
- Add `retainedProposalCount`.
- Add `MAX_RETAINED_PROPOSALS = 100`.
- Add `MIN_PRUNE_VALUE = ton("0.05")`.
- Add `PruneProposal`.
- Do not add tombstones.
- Do not change `proposalSeqno` during prune.
- Do not claim mainnet readiness.

## Task 1: Owner Index Validation And Retained Count Schema

**Files:**
- Modify: `contracts/types.tolk`
- Modify: `tests/contract.test.tolk`
- Modify: `scripts/deploy.tolk`
- Modify: `scripts/testnet-governance-smoke.tolk`

- [ ] **Step 1: Write failing owner-index validation tests**

Append tests near existing config validation tests in `tests/contract.test.tolk`:

```tolk
get fun `test duplicate owner indexes are rejected`() {
    val ownerA = testTreasury("duplicateIndexOwnerA");
    val ownerB = testTreasury("duplicateIndexOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, 0);
    owners.set(ownerB.address, 0);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.DuplicateOwner,
    });
}

get fun `test owner index outside owner count is rejected`() {
    val ownerA = testTreasury("badIndexOwnerA");
    val ownerB = testTreasury("badIndexOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, 0);
    owners.set(ownerB.address, 2);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidOwnerCount,
    });
}
```

- [ ] **Step 2: Run tests and verify they fail to compile**

Run:

```bash
/root/.acton/bin/acton test --filter "owner index"
```

Expected: FAIL because `retainedProposalCount` and owner-index validation do not exist yet.

- [ ] **Step 3: Update `contracts/types.tolk` schema**

Change constants:

```tolk
const OWNER_INDEX_0: uint8 = 0
const OWNER_INDEX_1: uint8 = 1
const OWNER_INDEX_2: uint8 = 2
const MAX_RETAINED_PROPOSALS: uint16 = 100
const MIN_PRUNE_VALUE: coins = ton("0.05")
```

Keep `OWNER_KEY_VALUE` during Task 1 if legacy approval-map code still uses it. Task 2 removes legacy approval-map storage.

Change `Storage` by adding only `retainedProposalCount` in Task 1. Keep `approvals` until Task 2:

```tolk
struct Storage {
    ownerCount: uint8
    payoutThreshold: uint8
    configThreshold: uint8
    configThresholdMutable: bool
    configVersion: uint32
    proposalSeqno: uint64
    retainedProposalCount: uint16
    feeReserve: coins
    owners: map<address, uint8>
    proposals: map<uint64, Cell<Proposal>>
    approvals: map<uint256, uint8>
}
```

Add owner-index helpers:

```tolk
fun ownerIndexMask(owners: map<address, uint8>, ownerCount: uint8): uint16 {
    var mask: uint16 = 0;
    var entry = owners.findFirst();
    while (entry.isFound) {
        val index = entry.value;
        assert (index < ownerCount) throw Errors.InvalidOwnerCount;
        val bit = (1 as uint16) << index;
        assert ((mask & bit) == 0) throw Errors.DuplicateOwner;
        mask = mask | bit;
        entry = owners.iterateNext(entry);
    }
    return mask;
}

fun Storage.ownerApprovalBit(self, owner: address): uint16 {
    val index = self.owners.mustGet(owner, Errors.NotOwner);
    assert (index < self.ownerCount) throw Errors.InvalidOwnerCount;
    return (1 as uint16) << index;
}
```

Update config validation:

```tolk
assert (ownerIndexMask(self.owners, self.ownerCount) != 0) throw Errors.InvalidOwnerCount;
assert (ownerIndexMask(newOwners, newOwnerCount) != 0) throw Errors.InvalidOwnerCount;
```

- [ ] **Step 4: Update all storage initializers**

In tests and scripts, replace owner map values:

```tolk
owners.set(ownerA.address, 0);
owners.set(ownerB.address, 1);
owners.set(ownerC.address, 2);
```

Add `retainedProposalCount: 0` to empty storage and seeded counts to seeded storage.

- [ ] **Step 5: Run validation tests**

Run:

```bash
/root/.acton/bin/acton test --filter "owner index|invalid treasury config|duplicate owner"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add contracts/types.tolk tests/contract.test.tolk scripts/deploy.tolk scripts/testnet-governance-smoke.tolk
git commit -m "feat: validate Treasury owner indexes"
```

## Task 2: Move Approvals Into Proposal Records

**Files:**
- Modify: `contracts/Treasury.tolk`
- Modify: `contracts/types.tolk`
- Modify: `tests/contract.test.tolk`

- [ ] **Step 1: Write failing approval-mask tests**

Replace legacy approval-key tests with:

```tolk
get fun `test creator approval is stored in proposal approval mask`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.05"),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(1);
    expect(proposal.approvalMask).toEqual(1);
    expect(contract.hasApproval(0, ownerA.address)).toEqual(true);
}

get fun `test second owner approval sets second approval bit`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createPendingPayout(contract, ownerA, outsider);

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: MIN_APPROVE_VALUE });
    expect(res).toHaveSuccessfulTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(2);
    expect(proposal.approvalMask).toEqual(3);
    expect(contract.hasApproval(0, ownerB.address)).toEqual(true);
}
```

Update `ProposalView` in `contracts/types.tolk` to expose `approvalMask: uint16`.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
/root/.acton/bin/acton test --filter "approval mask|duplicate approval|second owner approves"
```

Expected: FAIL because approvals still use global map and `ProposalView.approvalMask` does not exist.

- [ ] **Step 3: Update create and approve logic**

In both create paths, set:

```tolk
approvalCount: 1,
approvalMask: storage.ownerApprovalBit(in.senderAddress),
```

Remove both `storage.approvals.set` calls from the `CreatePayoutProposal` and `CreateConfigProposal` branches.

In `ApproveProposal`, replace global-map logic:

```tolk
val approvalBit = storage.ownerApprovalBit(in.senderAddress);
assert ((proposal.approvalMask & approvalBit) == 0) throw Errors.AlreadyApproved;

proposal.approvalMask = proposal.approvalMask | approvalBit;
proposal.approvalCount = proposal.approvalCount + 1;
storage.proposals.set(msg.proposalId, proposal.toCell());
```

In `has_approval`, return:

```tolk
val approvalBit = storage.ownerApprovalBit(owner);
return (proposal.approvalMask & approvalBit) != 0;
```

- [ ] **Step 4: Remove old approval helpers**

Delete:

```tolk
const APPROVAL_KEY_VALUE: uint8 = 1
fun approvalKey(kind: ProposalKind, proposalId: uint64, owner: address): uint256
approvals: map<uint256, uint8>
```

Remove tests that seed wrong-kind and legacy-id-only approval keys. Replace them with bitmask tests proving stale proposals cannot be affected by owner-set changes.

- [ ] **Step 5: Run approval tests**

Run:

```bash
/root/.acton/bin/acton test --filter "approval|stale"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add contracts/Treasury.tolk contracts/types.tolk tests/contract.test.tolk
git commit -m "feat: store proposal approvals as masks"
```

## Task 3: Retained Proposal Count And Hard Cap

**Files:**
- Modify: `contracts/types.tolk`
- Modify: `contracts/Treasury.tolk`
- Modify: `tests/contract.test.tolk`

- [ ] **Step 1: Write failing retained-count tests**

Append:

```tolk
get fun `test retained proposal count increments on payout create`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    expect(contract.retainedProposalCount()).toEqual(0);
    createPendingPayout(contract, ownerA, outsider);
    expect(contract.retainedProposalCount()).toEqual(1);
}

get fun `test retained proposal count increments on config create`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    var newOwners = threeOwners(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.retainedProposalCount()).toEqual(1);
}
```

- [ ] **Step 2: Add getter and create cap**

Add getter in `contracts/Treasury.tolk`:

```tolk
get fun retained_proposal_count(): uint16 {
    val storage = lazy Storage.load();
    return storage.retainedProposalCount;
}
```

Add wrapper generation later; tests can call generated wrapper after regeneration or direct getter if available.

In both create paths:

```tolk
assert (storage.retainedProposalCount < MAX_RETAINED_PROPOSALS) throw Errors.ProposalLimitReached;
storage.retainedProposalCount = storage.retainedProposalCount + 1;
```

Place the increment after `storage.proposals.set(proposalId, proposal.toCell())` and before `storage.proposalSeqno = proposalId + 1` in both `CreatePayoutProposal` and `CreateConfigProposal`.

Add error:

```tolk
ProposalLimitReached = 153
```

- [ ] **Step 3: Add cap test with seeded storage**

Create a helper that seeds `retainedProposalCount: MAX_RETAINED_PROPOSALS` and verifies create rejects with `Errors.ProposalLimitReached`.

- [ ] **Step 4: Run count/cap tests**

Run:

```bash
/root/.acton/bin/acton test --filter "retained proposal count|proposal cap"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add contracts/Treasury.tolk contracts/types.tolk tests/contract.test.tolk
git commit -m "feat: cap retained Treasury proposals"
```

## Task 4: Pruned And NotFound Getter Semantics

**Files:**
- Modify: `contracts/types.tolk`
- Modify: `contracts/Treasury.tolk`
- Modify: `tests/contract.test.tolk`

- [ ] **Step 1: Write failing getter tests**

Append:

```tolk
get fun `test proposal id beyond seqno returns not found status`() {
    val (contract, _, _, _) = setupTreasury();
    val proposal = contract.proposal(0);
    expect(proposal.status).toEqual(ProposalViewStatus.NotFound);
}

get fun `test missing proposal below seqno returns pruned status`() {
    val (contract, _, _, _) = setupTreasuryWithMissingProposalBelowSeqno();
    val proposal = contract.proposal(0);
    expect(proposal.status).toEqual(ProposalViewStatus.Pruned);
}
```

- [ ] **Step 2: Add statuses and empty view helper**

Append enum values:

```tolk
enum ProposalViewStatus: uint8 {
    Pending = 0
    Executable = 1
    Executed = 2
    Cancelled = 3
    Expired = 4
    Stale = 5
    Pruned = 6
    NotFound = 7
}
```

Add:

```tolk
fun emptyProposalView(proposalId: uint64, status: ProposalViewStatus): ProposalView {
    return ProposalView {
        id: proposalId,
        kind: ProposalKind.PayoutTon,
        creator: zeroAddress(),
        createdAt: 0,
        expiresAt: 0,
        configVersionAtCreation: 0,
        currentConfigVersion: 0,
        status,
        approvalCount: 0,
        approvalMask: 0,
        requiredApprovalCount: 0,
        payoutRecipient: zeroAddress(),
        payoutAmount: 0,
        recipient: zeroAddress(),
        amount: 0,
        newOwnerCount: 0,
        newPayoutThreshold: 0,
        newConfigThreshold: 0,
        newFeeReserve: 0,
    };
}
```

- [ ] **Step 3: Update proposal getter**

Replace `proposal(proposalId)` with:

```tolk
get fun proposal(proposalId: uint64): ProposalView {
    val storage = lazy Storage.load();
    if (proposalId >= storage.proposalSeqno) {
        return emptyProposalView(proposalId, ProposalViewStatus.NotFound);
    }
    val proposalCell = storage.proposals.get(proposalId);
    if (!proposalCell.isFound) {
        return emptyProposalView(proposalId, ProposalViewStatus.Pruned);
    }
    val proposal = proposalCell.value.load();
    return proposal.toView(storage.configVersion, storage.requiredThreshold(proposal.kind));
}
```

Add:

```tolk
get fun proposal_status(proposalId: uint64): ProposalViewStatus {
    return proposal(proposalId).status;
}
```

- [ ] **Step 4: Update strict getters**

`proposal_kind`, `proposal_required_threshold`, and `proposal_config_owners` should still throw for `Pruned` and `NotFound` because there is no retained payload to inspect.

- [ ] **Step 5: Run getter tests**

Run:

```bash
/root/.acton/bin/acton test --filter "not found|pruned status|proposal status"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add contracts/Treasury.tolk contracts/types.tolk tests/contract.test.tolk
git commit -m "feat: expose pruned proposal view states"
```

## Task 5: Owner-Only PruneProposal

**Files:**
- Modify: `contracts/types.tolk`
- Modify: `contracts/Treasury.tolk`
- Modify: `tests/contract.test.tolk`

- [ ] **Step 1: Write failing prune tests**

Add tests for each allowed state:

```tolk
get fun `test owner can prune executed proposal`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createExecutablePayout(contract, ownerA, ownerB, recipient);
    contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });

    val res = contract.sendPruneProposal(ownerA.address, 0, { value: MIN_PRUNE_VALUE });
    expect(res).toHaveSuccessfulTx<PruneProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Pruned);
    expect(contract.retainedProposalCount()).toEqual(0);
}

get fun `test owner can prune stale proposal`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    createPendingPayout(contract, ownerA, ownerC);
    executeNoOpConfigChange(contract, ownerA, ownerB);

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Stale);
    val res = contract.sendPruneProposal(ownerA.address, 0, { value: MIN_PRUNE_VALUE });
    expect(res).toHaveSuccessfulTx<PruneProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Pruned);
}
```

Add rejection tests:

```tolk
get fun `test non owner cannot prune`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createPendingPayout(contract, ownerA, outsider);

    val res = contract.sendPruneProposal(outsider.address, 0, { value: MIN_PRUNE_VALUE });
    expect(res).toHaveFailedTx<PruneProposal>({
        from: outsider.address,
        to: contract.address,
        exitCode: Errors.NotOwner,
    });
}

get fun `test pending proposal cannot be pruned`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createPendingPayout(contract, ownerA, outsider);

    val res = contract.sendPruneProposal(ownerA.address, 0, { value: MIN_PRUNE_VALUE });
    expect(res).toHaveFailedTx<PruneProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPrunable,
    });
}

get fun `test executable proposal cannot be pruned`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createExecutablePayout(contract, ownerA, ownerB, outsider);

    val res = contract.sendPruneProposal(ownerA.address, 0, { value: MIN_PRUNE_VALUE });
    expect(res).toHaveFailedTx<PruneProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPrunable,
    });
}

get fun `test pruned proposal cannot be pruned twice`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createExecutablePayout(contract, ownerA, ownerB, recipient);
    contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    contract.sendPruneProposal(ownerA.address, 0, { value: MIN_PRUNE_VALUE });

    val res = contract.sendPruneProposal(ownerA.address, 0, { value: MIN_PRUNE_VALUE });
    expect(res).toHaveFailedTx<PruneProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalPruned,
    });
}

get fun `test never created proposal cannot be pruned`() {
    val (contract, ownerA, _, _) = setupTreasury();

    val res = contract.sendPruneProposal(ownerA.address, 0, { value: MIN_PRUNE_VALUE });
    expect(res).toHaveFailedTx<PruneProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalNotFound,
    });
}
```

- [ ] **Step 2: Add message and errors**

In `contracts/types.tolk`:

```tolk
ProposalPruned = 151
ProposalNotPrunable = 152
ProposalLimitReached = 153
```

Add:

```tolk
struct (0x54524606) PruneProposal {
    proposalId: uint64
}

type TreasuryMessage =
    | CreatePayoutProposal
    | ApproveProposal
    | ExecuteProposal
    | CancelProposal
    | CreateConfigProposal
    | PruneProposal
```

- [ ] **Step 3: Add prune handler**

In `contracts/Treasury.tolk`:

```tolk
PruneProposal => {
    var storage = lazy Storage.load();
    storage.assertValidConfig();
    requireMinValue(in.valueCoins, MIN_PRUNE_VALUE);
    storage.assertOwner(in.senderAddress);
    assert (msg.proposalId < storage.proposalSeqno) throw Errors.ProposalNotFound;

    val proposalCell = storage.proposals.get(msg.proposalId);
    assert (proposalCell.isFound) throw Errors.ProposalPruned;

    val proposal = proposalCell.value.load();
    val status = proposal.viewStatus(
        storage.configVersion,
        storage.requiredThreshold(proposal.kind),
    );
    val prunable =
        status == ProposalViewStatus.Executed ||
        status == ProposalViewStatus.Cancelled ||
        status == ProposalViewStatus.Expired ||
        status == ProposalViewStatus.Stale;
    assert (prunable) throw Errors.ProposalNotPrunable;

    assert (storage.proposals.delete(msg.proposalId)) throw Errors.ProposalPruned;
    storage.retainedProposalCount = storage.retainedProposalCount - 1;
    storage.save();
}
```

- [ ] **Step 4: Add `can_prune` getter**

```tolk
get fun can_prune(proposalId: uint64): bool {
    val view = proposal(proposalId);
    return view.status == ProposalViewStatus.Executed ||
        view.status == ProposalViewStatus.Cancelled ||
        view.status == ProposalViewStatus.Expired ||
        view.status == ProposalViewStatus.Stale;
}
```

- [ ] **Step 5: Run prune tests**

Run:

```bash
/root/.acton/bin/acton test --filter "prune|Pruned|NotFound"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add contracts/Treasury.tolk contracts/types.tolk tests/contract.test.tolk
git commit -m "feat: prune terminal Treasury proposals"
```

## Task 6: Wrapper Regeneration And Scripts

**Files:**
- Modify: `wrappers/Treasury.gen.tolk`
- Modify: `wrappers-ts/Treasury.gen.ts`
- Modify: `scripts/deploy.tolk`
- Modify: `scripts/testnet-governance-smoke.tolk`

- [ ] **Step 1: Regenerate wrappers**

Run:

```bash
/root/.acton/bin/acton wrapper Treasury
```

Expected: wrappers expose `sendPruneProposal`, `proposalStatus`, `canPrune`, `retainedProposalCount`, `approvalMask`, `Pruned`, and `NotFound`.

- [ ] **Step 2: Update scripts**

Confirm all scripts initialize storage with:

```tolk
proposalSeqno: 0,
retainedProposalCount: 0,
owners,
proposals: [],
```

Confirm owner indices use:

```tolk
owners.set(ownerA.address, 0);
owners.set(ownerB.address, 1);
```

- [ ] **Step 3: Run smoke in emulation**

Run:

```bash
/root/.acton/bin/acton script scripts/testnet-governance-smoke.tolk
```

Expected: `SMOKE_RESULT=PASS`.

- [ ] **Step 4: Commit**

```bash
git add wrappers/Treasury.gen.tolk wrappers-ts/Treasury.gen.ts scripts/deploy.tolk scripts/testnet-governance-smoke.tolk
git commit -m "chore: regenerate Treasury pruning wrappers"
```

## Task 7: Docs, Gas Snapshot, And Final Verification

**Files:**
- Modify: `docs/security-model.md`
- Modify: `docs/research/track-a-security-checklist.md`
- Modify: `docs/research/track-a-storage-reserve-policy.md`
- Modify: `gas-baseline.json`

- [ ] **Step 1: Update docs**

Update docs to state:

```text
Phase 4 implements owner-only pruning for Executed, Cancelled, Expired, and Stale proposals.
Pending and Executable current-version proposals are not prunable.
Approvals are stored inside proposal records as approval masks, so pruning one proposal removes its approvals without orphan state.
MAX_RETAINED_PROPOSALS is 100 in v1.
Mainnet remains blocked pending external review/audit and storage evidence review.
```

- [ ] **Step 2: Regenerate gas snapshot**

Run:

```bash
/root/.acton/bin/acton test --snapshot gas-baseline.json
```

Expected: PASS and snapshot updated.

- [ ] **Step 3: Run full verification**

Run:

```bash
/root/.acton/bin/acton fmt --check
/root/.acton/bin/acton build
/root/.acton/bin/acton check
/root/.acton/bin/acton test
/root/.acton/bin/acton test --coverage
/root/.acton/bin/acton test --snapshot gas-baseline.json
git diff --check
```

Expected:

```text
All formatting/build/check/test commands pass.
Coverage output is reviewed and every new pruning branch has a deterministic test.
git diff --check reports no whitespace errors.
```

- [ ] **Step 4: Run secret/control-character scans**

Run:

```bash
rg -n "mnemonic|private key|seed phrase|TONCENTER_.*=" .
rg -n "[\u202A-\u202E\u2066-\u2069\u200B-\u200F]" .
```

Expected: no committed secrets; no hidden/bidirectional Unicode in changed files.

- [ ] **Step 5: Commit**

```bash
git add docs/security-model.md docs/research/track-a-security-checklist.md docs/research/track-a-storage-reserve-policy.md gas-baseline.json
git commit -m "docs: record Treasury pruning evidence"
```

## Final Acceptance Criteria

- `PruneProposal` is owner-only in v1.
- Only `Executed`, `Cancelled`, `Expired`, and `Stale` proposals can be pruned.
- `Pending` and `Executable` current-version proposals cannot be pruned.
- Prune deletes proposal-local approvals without orphan approval state.
- `proposalSeqno` is monotonic and unchanged by pruning.
- `configVersion`, owners, thresholds, fee reserve, and balance transfer behavior are unchanged by pruning.
- `proposal(id)` returns `NotFound` for `id >= proposalSeqno`.
- `proposal(id)` returns `Pruned` for missing `id < proposalSeqno`.
- `retainedProposalCount` increments on create and decrements once on prune.
- `MAX_RETAINED_PROPOSALS = 100` blocks new proposal creation until pruning frees a slot.
- Wrappers and scripts are regenerated/updated through Acton tooling.
- Deterministic tests, coverage, gas snapshot, and GitHub CI pass.
- No mainnet readiness claim is added.
