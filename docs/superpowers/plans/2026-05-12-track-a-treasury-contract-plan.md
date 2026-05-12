# Track A Treasury Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Acton empty scaffold with a tested Track A Treasury-first contract that supports N-of-M TON payout approvals.

**Architecture:** Implement one `Treasury.tolk` contract using typed Tolk storage, typed message bodies, owner-address maps, proposal maps, and approval maps. The contract handles deposits, payout proposal creation, creator auto-approval, owner approvals, cancellation, expiry checks, and TON payout execution; Splitter, Jettons, frontend, backend, Track B, anonymous approvals, and mainnet remain out of scope.

**Tech Stack:** Acton 1.0.0, Tolk, Acton Tolk wrappers, Acton test runner, WSL Ubuntu.

---

## Scope Check

This plan implements only the Track A Treasury-first MVP described in `docs/superpowers/specs/2026-05-12-track-a-treasury-first-design.md`.

Out of scope for this plan:

- Splitter contract.
- Jetton payouts.
- Telegram Mini App frontend.
- Backend/indexer.
- Official multisig v2 adapter.
- Anonymous/ZK approvals.
- Mainnet deployment.

## File Structure

This plan creates or modifies these files:

- Rename/replace: `contracts/Empty.tolk` -> `contracts/Treasury.tolk`.
- Modify: `contracts/types.tolk` to define Treasury storage, messages, proposal types, status enum, helper methods, and errors.
- Modify: `Acton.toml` to replace `[contracts.Empty]` with `[contracts.Treasury]`.
- Delete: `wrappers/Empty.gen.tolk` after generating `wrappers/Treasury.gen.tolk`.
- Create/generated: `wrappers/Treasury.gen.tolk` via `acton wrapper Treasury`.
- Modify: `tests/contract.test.tolk` to replace Empty tests with deterministic Treasury tests.
- Modify: `scripts/deploy.tolk` to deploy Treasury with a safe testnet-local initial owner set.
- Create/generated when supported by local Node: `wrappers-ts/Treasury.gen.ts` via `acton wrapper Treasury --ts --output-dir wrappers-ts`.

Generated and ignored:

- `.acton/`
- `build/`
- `gen/`

## Implementation Constants

Use these exact constants unless implementation testing proves an Acton/Tolk compiler incompatibility:

```tolk
const OWNER_KEY_VALUE: uint8 = 1
const APPROVAL_KEY_VALUE: uint8 = 1
const DEFAULT_EXPIRY_SECONDS: uint32 = 86400
const DEFAULT_FEE_RESERVE: coins = ton("0.10")
const SEND_MODE_REGULAR: uint8 = 0
```

Use these exact status values:

```tolk
enum ProposalStatus: uint8 {
    Pending = 0
    Executed = 1
    Cancelled = 2
}

enum ProposalViewStatus: uint8 {
    Pending = 0
    Executable = 1
    Executed = 2
    Cancelled = 3
    Expired = 4
}
```

Use these exact error codes:

```tolk
enum Errors {
    NotOwner = 128
    InvalidMessage = 129
    InvalidOwnerCount = 130
    DuplicateOwner = 131
    InvalidThreshold = 132
    InvalidRecipient = 133
    InvalidAmount = 134
    InvalidExpiry = 135
    ProposalNotFound = 136
    ProposalNotPending = 137
    ProposalExpired = 138
    AlreadyApproved = 139
    ThresholdNotReached = 140
    AlreadyExecutable = 141
    InsufficientBalance = 142
    NotCreator = 143
}
```

## Storage And Message Model

Use typed maps rather than low-level `dict` directly:

```tolk
struct Storage {
    ownerCount: uint8
    threshold: uint8
    proposalSeqno: uint64
    feeReserve: coins
    owners: map<address, uint8>
    proposals: map<uint64, Cell<PayoutProposal>>
    approvals: map<ApprovalKey, uint8>
}

struct ApprovalKey {
    proposalId: uint64
    owner: address
}

struct PayoutProposal {
    id: uint64
    creator: address
    recipient: address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalStatus
    approvalCount: uint8
}

struct ProposalView {
    id: uint64
    creator: address
    recipient: address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalViewStatus
    approvalCount: uint8
}

struct (0x54524601) CreatePayoutProposal {
    recipient: address
    amount: coins
    expiresAt: uint32
}

struct (0x54524602) ApproveProposal {
    proposalId: uint64
}

struct (0x54524603) ExecuteProposal {
    proposalId: uint64
}

struct (0x54524604) CancelProposal {
    proposalId: uint64
}

type TreasuryMessage = CreatePayoutProposal | ApproveProposal | ExecuteProposal | CancelProposal
```

## Task 1: Rename Empty Scaffold To Treasury Shell

**Files:**
- Rename: `contracts/Empty.tolk` -> `contracts/Treasury.tolk`
- Modify: `Acton.toml`
- Delete: `wrappers/Empty.gen.tolk`
- Generate: `wrappers/Treasury.gen.tolk`
- Modify: `tests/contract.test.tolk`
- Modify: `scripts/deploy.tolk`

- [ ] **Step 1: Rename the contract file**

Run from repository root:

```powershell
Move-Item -LiteralPath "contracts/Empty.tolk" -Destination "contracts/Treasury.tolk"
Remove-Item -LiteralPath "wrappers/Empty.gen.tolk"
```

Expected: `contracts/Treasury.tolk` exists and `wrappers/Empty.gen.tolk` is removed.

- [ ] **Step 2: Update `Acton.toml` contract entry**

Replace the existing `[contracts.Empty]` section with:

```toml
[contracts.Treasury]
display-name = "Treasury"
src = "contracts/Treasury.tolk"
depends = []
```

Expected: `Acton.toml` contains no `contracts.Empty` entry.

- [ ] **Step 3: Replace `contracts/Treasury.tolk` with a Treasury shell**

Use this complete file content:

```tolk
import "types"

contract Treasury {
    author: "TreasuryFlow TON"
    version: "0.1.0"
    description: "Track A Treasury-first TON payout approval prototype"
    storage: Storage
    incomingMessages: TreasuryMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy TreasuryMessage.fromSlice(in.body);

    match (msg) {
        CreatePayoutProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.InvalidMessage;
        }
        ApproveProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.ProposalNotFound;
        }
        ExecuteProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.ProposalNotFound;
        }
        CancelProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            assert (storage.isOwner(in.senderAddress)) throw Errors.NotOwner;
            throw Errors.ProposalNotFound;
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
            val storage = lazy Storage.load();
            storage.assertValidConfig();
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun owner_count(): uint8 {
    val storage = lazy Storage.load();
    return storage.ownerCount;
}

get fun threshold(): uint8 {
    val storage = lazy Storage.load();
    return storage.threshold;
}

get fun proposal_seqno(): uint64 {
    val storage = lazy Storage.load();
    return storage.proposalSeqno;
}

get fun fee_reserve(): coins {
    val storage = lazy Storage.load();
    return storage.feeReserve;
}

get fun is_owner(owner: address): bool {
    val storage = lazy Storage.load();
    return storage.isOwner(owner);
}
```

- [ ] **Step 4: Replace `contracts/types.tolk` with Treasury base types**

Use this complete file content:

```tolk
const OWNER_KEY_VALUE: uint8 = 1
const APPROVAL_KEY_VALUE: uint8 = 1
const DEFAULT_EXPIRY_SECONDS: uint32 = 86400
const DEFAULT_FEE_RESERVE: coins = ton("0.10")
const SEND_MODE_REGULAR: uint8 = 0

enum Errors {
    NotOwner = 128
    InvalidMessage = 129
    InvalidOwnerCount = 130
    DuplicateOwner = 131
    InvalidThreshold = 132
    InvalidRecipient = 133
    InvalidAmount = 134
    InvalidExpiry = 135
    ProposalNotFound = 136
    ProposalNotPending = 137
    ProposalExpired = 138
    AlreadyApproved = 139
    ThresholdNotReached = 140
    AlreadyExecutable = 141
    InsufficientBalance = 142
    NotCreator = 143
}

enum ProposalStatus: uint8 {
    Pending = 0
    Executed = 1
    Cancelled = 2
}

enum ProposalViewStatus: uint8 {
    Pending = 0
    Executable = 1
    Executed = 2
    Cancelled = 3
    Expired = 4
}

struct ApprovalKey {
    proposalId: uint64
    owner: address
}

struct PayoutProposal {
    id: uint64
    creator: address
    recipient: address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalStatus
    approvalCount: uint8
}

struct ProposalView {
    id: uint64
    creator: address
    recipient: address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalViewStatus
    approvalCount: uint8
}

struct Storage {
    ownerCount: uint8
    threshold: uint8
    proposalSeqno: uint64
    feeReserve: coins
    owners: map<address, uint8>
    proposals: map<uint64, Cell<PayoutProposal>>
    approvals: map<ApprovalKey, uint8>
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun Storage.assertValidConfig(self) {
    assert (self.ownerCount > 0) throw Errors.InvalidOwnerCount;
    assert (self.owners.size() == self.ownerCount) throw Errors.DuplicateOwner;
    assert (self.threshold > 0) throw Errors.InvalidThreshold;
    assert (self.threshold <= self.ownerCount) throw Errors.InvalidThreshold;
}

fun Storage.isOwner(self, owner: address): bool {
    return self.owners.exists(owner);
}

fun Storage.assertOwner(self, owner: address) {
    assert (self.isOwner(owner)) throw Errors.NotOwner;
}

fun Storage.mustGetProposal(self, proposalId: uint64): PayoutProposal {
    val proposalCell = self.proposals.mustGet(proposalId, Errors.ProposalNotFound);
    return proposalCell.load();
}

fun PayoutProposal.isExpired(self): bool {
    return blockchain.now() >= self.expiresAt;
}

fun PayoutProposal.viewStatus(self, threshold: uint8): ProposalViewStatus {
    if (self.status == ProposalStatus.Executed) {
        return ProposalViewStatus.Executed;
    }
    if (self.status == ProposalStatus.Cancelled) {
        return ProposalViewStatus.Cancelled;
    }
    if (self.isExpired()) {
        return ProposalViewStatus.Expired;
    }
    if (self.approvalCount >= threshold) {
        return ProposalViewStatus.Executable;
    }
    return ProposalViewStatus.Pending;
}

fun PayoutProposal.toView(self, threshold: uint8): ProposalView {
    return ProposalView {
        id: self.id,
        creator: self.creator,
        recipient: self.recipient,
        amount: self.amount,
        createdAt: self.createdAt,
        expiresAt: self.expiresAt,
        status: self.viewStatus(threshold),
        approvalCount: self.approvalCount,
    };
}

struct (0x54524601) CreatePayoutProposal {
    recipient: address
    amount: coins
    expiresAt: uint32
}

struct (0x54524602) ApproveProposal {
    proposalId: uint64
}

struct (0x54524603) ExecuteProposal {
    proposalId: uint64
}

struct (0x54524604) CancelProposal {
    proposalId: uint64
}

type TreasuryMessage = CreatePayoutProposal | ApproveProposal | ExecuteProposal | CancelProposal
```

- [ ] **Step 5: Replace tests with deployment and config tests**

Use this complete `tests/contract.test.tolk` content:

```tolk
import "@acton/emulation/network"
import "@acton/emulation/testing"
import "@acton/testing/expect"

import "@contracts/types"
import "@wrappers/Treasury.gen"

get fun `test deploy exposes treasury config`() {
    val (contract, ownerA, ownerB, _) = setupTreasury();

    expect(contract.ownerCount()).toEqual(2);
    expect(contract.threshold()).toEqual(2);
    expect(contract.proposalSeqno()).toEqual(0);
    expect(contract.feeReserve()).toEqual(DEFAULT_FEE_RESERVE);
    expect(contract.isOwner(ownerA.address)).toBeTrue();
    expect(contract.isOwner(ownerB.address)).toBeTrue();
}

get fun `test non owner cannot create proposal`() {
    val (contract, _, _, outsider) = setupTreasury();

    val res = contract.sendCreatePayoutProposal(
        outsider.address,
        outsider.address,
        ton("0.20"),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: ton("0.05") },
    );

    expect(res).toHaveFailedTx<CreatePayoutProposal>({
        from: outsider.address,
        to: contract.address,
        exitCode: Errors.NotOwner,
    });
}

get fun `test plain TON deposit succeeds`() {
    val (contract, _, _, outsider) = setupTreasury();

    val res = contract.sendAny(outsider.address, createEmptyCell(), { value: ton("0.30") });
    expect(res).toHaveSuccessfulTx({
        from: outsider.address,
        to: contract.address,
    });
}

get fun `test invalid treasury config is rejected`() {
    val ownerA = testing.treasury("invalidOwnerA");
    val ownerB = testing.treasury("invalidOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val badThreshold = Treasury.fromStorage(Storage {
        ownerCount: 2,
        threshold: 3,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });
    val thresholdDeploy = badThreshold.deploy(ownerA.address, { value: ton("1.00") });
    expect(thresholdDeploy).toHaveSuccessfulDeploy({ to: badThreshold.address });
    val thresholdRes = badThreshold.sendAny(ownerA.address, createEmptyCell(), { value: ton("0.05") });
    expect(thresholdRes).toHaveFailedTx({
        from: ownerA.address,
        to: badThreshold.address,
        exitCode: Errors.InvalidThreshold,
    });

    var duplicateCollapsedOwners: map<address, uint8> = [];
    duplicateCollapsedOwners.set(ownerA.address, OWNER_KEY_VALUE);
    val duplicateCollapsed = Treasury.fromStorage(Storage {
        ownerCount: 2,
        threshold: 1,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners: duplicateCollapsedOwners,
        proposals: [],
        approvals: [],
    });
    val duplicateDeploy = duplicateCollapsed.deploy(ownerA.address, { value: ton("1.00") });
    expect(duplicateDeploy).toHaveSuccessfulDeploy({ to: duplicateCollapsed.address });
    val duplicateRes = duplicateCollapsed.sendAny(ownerA.address, createEmptyCell(), { value: ton("0.05") });
    expect(duplicateRes).toHaveFailedTx({
        from: ownerA.address,
        to: duplicateCollapsed.address,
        exitCode: Errors.DuplicateOwner,
    });
}

fun setupTreasury(): (Treasury, Treasury, Treasury, Treasury) {
    val ownerA = testing.treasury("ownerA");
    val ownerB = testing.treasury("ownerB");
    val outsider = testing.treasury("outsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        threshold: 2,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, outsider);
}
```

- [ ] **Step 6: Generate Treasury Tolk wrapper**

Run from PowerShell:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury"
```

Expected: `wrappers/Treasury.gen.tolk` exists and imports `@contracts/types`.

- [ ] **Step 7: Run the first test and verify expected failure**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'deploy exposes treasury config'"
```

Expected before fixing generated wrapper names: compile fails if the wrapper method names differ from the test method names. If wrapper names differ, update only the test calls to match generated names, then rerun until this test passes.

- [ ] **Step 8: Run all current tests**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test"
```

Expected: deployment config, plain deposit, invalid config, and non-owner create tests pass.

- [ ] **Step 9: Commit Treasury shell**

Run:

```powershell
git add Acton.toml contracts tests wrappers scripts
git commit -m "feat: introduce Treasury contract shell"
```

## Task 2: Implement Proposal Creation And Read Getters

**Files:**
- Modify: `contracts/Treasury.tolk`
- Modify: `contracts/types.tolk`
- Modify: `tests/contract.test.tolk`
- Generate: `wrappers/Treasury.gen.tolk`

- [ ] **Step 1: Add proposal getter tests**

Append these tests above `setupTreasury()` in `tests/contract.test.tolk`:

```tolk
get fun `test owner creates payout proposal with creator auto approval`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    val expiresAt = blockchain.now() + DEFAULT_EXPIRY_SECONDS;

    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        expiresAt,
        { value: ton("0.05") },
    );

    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.id).toEqual(0);
    expect(proposal.creator).toEqual(ownerA.address);
    expect(proposal.recipient).toEqual(outsider.address);
    expect(proposal.amount).toEqual(ton("0.20"));
    expect(proposal.expiresAt).toEqual(expiresAt);
    expect(proposal.status).toEqual(ProposalViewStatus.Pending);
    expect(proposal.approvalCount).toEqual(1);
    expect(contract.hasApproval(0, ownerA.address)).toBeTrue();
    expect(contract.proposalSeqno()).toEqual(1);
}

get fun `test create proposal rejects invalid amount and expiry`() {
    val (contract, ownerA, _, outsider) = setupTreasury();

    val zeroAmount = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        0,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: ton("0.05") },
    );
    expect(zeroAmount).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidAmount,
    });

    val expired = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        blockchain.now(),
        { value: ton("0.05") },
    );
    expect(expired).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidExpiry,
    });
}
```

- [ ] **Step 2: Run proposal tests and verify failure**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'owner creates payout proposal|invalid amount'"
```

Expected: compile fails because getters and create implementation are not present yet, or runtime fails with `Errors.InvalidMessage` from the shell.

- [ ] **Step 3: Implement create proposal path**

Replace the `CreatePayoutProposal` match arm in `contracts/Treasury.tolk` with:

```tolk
        CreatePayoutProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);
            assert (msg.amount > 0) throw Errors.InvalidAmount;
            assert (msg.expiresAt > blockchain.now()) throw Errors.InvalidExpiry;

            val proposalId = storage.proposalSeqno;
            val proposal = PayoutProposal {
                id: proposalId,
                creator: in.senderAddress,
                recipient: msg.recipient,
                amount: msg.amount,
                createdAt: blockchain.now() as uint32,
                expiresAt: msg.expiresAt,
                status: ProposalStatus.Pending,
                approvalCount: 1,
            };

            storage.proposals.set(proposalId, proposal.toCell());
            storage.approvals.set(ApprovalKey { proposalId, owner: in.senderAddress }, APPROVAL_KEY_VALUE);
            storage.proposalSeqno = proposalId + 1;
            storage.save();
        }
```

- [ ] **Step 4: Add proposal getters to `contracts/Treasury.tolk`**

Append these getters after `is_owner`:

```tolk
get fun proposal(proposalId: uint64): ProposalView {
    val storage = lazy Storage.load();
    val proposal = storage.mustGetProposal(proposalId);
    return proposal.toView(storage.threshold);
}

get fun has_approval(proposalId: uint64, owner: address): bool {
    val storage = lazy Storage.load();
    return storage.approvals.exists(ApprovalKey { proposalId, owner });
}
```

- [ ] **Step 5: Regenerate wrapper**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury"
```

Expected: generated wrapper exposes send helper for `CreatePayoutProposal`, `proposal`, and `hasApproval`/matching getter helper names. If getter helper names differ, update test calls to the generated names only.

- [ ] **Step 6: Run proposal tests**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'owner creates payout proposal|invalid amount|non owner cannot create'"
```

Expected: all selected tests pass.

- [ ] **Step 7: Commit proposal creation**

Run:

```powershell
git add contracts tests wrappers
git commit -m "feat: add Treasury payout proposals"
```

## Task 3: Implement Owner Approvals And Duplicate Protection

**Files:**
- Modify: `contracts/Treasury.tolk`
- Modify: `tests/contract.test.tolk`
- Generate: `wrappers/Treasury.gen.tolk`

- [ ] **Step 1: Add approval tests**

Append these tests above `setupTreasury()`:

```tolk
get fun `test second owner approves proposal`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(2);
    expect(proposal.status).toEqual(ProposalViewStatus.Executable);
    expect(contract.hasApproval(0, ownerB.address)).toBeTrue();
}

get fun `test duplicate approval is rejected`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.AlreadyApproved,
    });

    expect(contract.proposal(0).approvalCount).toEqual(1);
}

get fun `test non owner cannot approve proposal`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(outsider.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: outsider.address,
        to: contract.address,
        exitCode: Errors.NotOwner,
    });
}
```

Append this helper below `setupTreasury()`:

```tolk
fun createProposal(contract: Treasury, creator: Treasury, recipient: address, amount: coins) {
    val res = contract.sendCreatePayoutProposal(
        creator.address,
        recipient,
        amount,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: ton("0.05") },
    );
    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: creator.address,
        to: contract.address,
    });
}
```

- [ ] **Step 2: Run approval tests and verify failure**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'approves proposal|duplicate approval|cannot approve'"
```

Expected: selected tests fail because `ApproveProposal` still throws `Errors.ProposalNotFound`.

- [ ] **Step 3: Implement approve path**

Replace the `ApproveProposal` match arm in `contracts/Treasury.tolk` with:

```tolk
        ApproveProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;

            val key = ApprovalKey { proposalId: msg.proposalId, owner: in.senderAddress };
            assert (!storage.approvals.exists(key)) throw Errors.AlreadyApproved;

            storage.approvals.set(key, APPROVAL_KEY_VALUE);
            proposal.approvalCount = proposal.approvalCount + 1;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();
        }
```

- [ ] **Step 4: Regenerate wrapper and run approval tests**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury && /root/.acton/bin/acton test --filter 'approves proposal|duplicate approval|cannot approve'"
```

Expected: selected tests pass.

- [ ] **Step 5: Commit approvals**

Run:

```powershell
git add contracts tests wrappers
git commit -m "feat: add Treasury proposal approvals"
```

## Task 4: Implement Cancellation And Expiry Enforcement

**Files:**
- Modify: `contracts/Treasury.tolk`
- Modify: `tests/contract.test.tolk`
- Generate: `wrappers/Treasury.gen.tolk`

- [ ] **Step 1: Add cancellation and expiry tests**

Append these tests above `setupTreasury()`:

```tolk
get fun `test creator cancels pending non executable proposal`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Cancelled);
}

get fun `test non creator cannot cancel proposal`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendCancelProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.NotCreator,
    });
}

get fun `test executable proposal cannot be cancelled`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.AlreadyExecutable,
    });
}
```

Append this helper below `createProposal()`:

```tolk
fun approveProposal(contract: Treasury, owner: Treasury, proposalId: uint64) {
    val res = contract.sendApproveProposal(owner.address, proposalId, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ApproveProposal>({
        from: owner.address,
        to: contract.address,
    });
}
```

- [ ] **Step 2: Run cancellation tests and verify failure**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'cancel'"
```

Expected: selected tests fail because `CancelProposal` is not implemented.

- [ ] **Step 3: Implement cancel path**

Replace the `CancelProposal` match arm in `contracts/Treasury.tolk` with:

```tolk
        CancelProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;
            assert (proposal.creator == in.senderAddress) throw Errors.NotCreator;
            assert (proposal.approvalCount < storage.threshold) throw Errors.AlreadyExecutable;

            proposal.status = ProposalStatus.Cancelled;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();
        }
```

- [ ] **Step 4: Add expiry rejection test for approval**

Append this test above `setupTreasury()`:

```tolk
get fun `test expired proposal cannot be approved`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        blockchain.now() + 1,
        { value: ton("0.05") },
    );
    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    testing.advanceTime(2);

    val approval = contract.sendApproveProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(approval).toHaveFailedTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.ProposalExpired,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Expired);
}
```

If `testing.advanceTime` is not available in Acton 1.0.0, search the installed Acton package sources for the exact emulation time helper and replace only the time travel call:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && find .acton -type f -name '*.tolk' -print | xargs grep -n 'advance\|time\|now'"
```

- [ ] **Step 5: Regenerate wrapper and run cancellation/expiry tests**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury && /root/.acton/bin/acton test --filter 'cancel|expired proposal'"
```

Expected: selected tests pass.

- [ ] **Step 6: Commit cancellation and expiry**

Run:

```powershell
git add contracts tests wrappers
git commit -m "feat: add Treasury cancellation and expiry checks"
```

## Task 5: Implement TON Payout Execution And Fee Reserve

**Files:**
- Modify: `contracts/Treasury.tolk`
- Modify: `tests/contract.test.tolk`
- Generate: `wrappers/Treasury.gen.tolk`

- [ ] **Step 1: Add execution tests**

Append these tests above `setupTreasury()`:

```tolk
get fun `test execute before threshold fails`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ThresholdNotReached,
    });
}

get fun `test execute after threshold sends TON payout`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(res).toHaveTx({
        from: contract.address,
        to: recipient.address,
        value: ton("0.20"),
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Executed);
}

get fun `test executed proposal cannot execute twice`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);
    executeProposal(contract, ownerA, 0);

    val res = contract.sendExecuteProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}

get fun `test fee reserve prevents draining treasury`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.95"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InsufficientBalance,
    });
}

get fun `test expired proposal cannot be executed`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    val create = contract.sendCreatePayoutProposal(
        ownerA.address,
        recipient.address,
        ton("0.20"),
        blockchain.now() + 1,
        { value: ton("0.05") },
    );
    expect(create).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);

    testing.advanceTime(2);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalExpired,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Expired);
}

get fun `test executed proposal cannot be cancelled`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);
    executeProposal(contract, ownerA, 0);

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}
```

Append this helper below `approveProposal()`:

```tolk
fun executeProposal(contract: Treasury, owner: Treasury, proposalId: uint64) {
    val res = contract.sendExecuteProposal(owner.address, proposalId, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: owner.address,
        to: contract.address,
    });
}
```

- [ ] **Step 2: Run execution tests and verify failure**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'execute|fee reserve'"
```

Expected: selected tests fail because execute path is not implemented.

- [ ] **Step 3: Implement payout send helper**

Append this helper to `contracts/Treasury.tolk` above the getters:

```tolk
fun sendTonPayout(recipient: address, amount: coins) {
    val payout = createMessage({
        bounce: false,
        dest: recipient,
        value: amount,
    });
    payout.send(SEND_MODE_REGULAR);
}
```

- [ ] **Step 4: Implement execute path**

Replace the `ExecuteProposal` match arm in `contracts/Treasury.tolk` with:

```tolk
        ExecuteProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;
            assert (proposal.approvalCount >= storage.threshold) throw Errors.ThresholdNotReached;
            assert (contract.getOriginalBalance() >= proposal.amount + storage.feeReserve) throw Errors.InsufficientBalance;

            proposal.status = ProposalStatus.Executed;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();

            sendTonPayout(proposal.recipient, proposal.amount);
        }
```

- [ ] **Step 5: Regenerate wrapper and run execution tests**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury && /root/.acton/bin/acton test --filter 'execute|fee reserve'"
```

Expected: selected tests pass.

- [ ] **Step 6: Commit execution**

Run:

```powershell
git add contracts tests wrappers
git commit -m "feat: execute Treasury TON payouts"
```

## Task 6: Replace Deployment Script And Generate TypeScript Wrapper

**Files:**
- Modify: `scripts/deploy.tolk`
- Modify: `Acton.toml`
- Create/generated: `wrappers-ts/Treasury.gen.ts`

- [ ] **Step 1: Replace `scripts/deploy.tolk`**

Use this complete file content:

```tolk
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"
import "@wrappers/Treasury.gen"

fun main() {
    val ownerA = scripts.wallet("ownerA");
    val ownerB = scripts.wallet("ownerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        threshold: 2,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    if (res.waitForFirstTransaction() == null) {
        println("Treasury deployment transaction was not observed");
        return;
    }

    println("TREASURY_ADDRESS={}", contract.address);
    println("Owner count: {}", contract.ownerCount());
    println("Threshold: {}", contract.threshold());
    println("Fee reserve: {:ton}", contract.feeReserve());
}
```

- [ ] **Step 2: Add wrapper output config to `Acton.toml`**

Add this section below `[test]`:

```toml
[wrappers.tolk]
output-dir = "wrappers"

[wrappers.typescript]
output-dir = "wrappers-ts"
```

- [ ] **Step 3: Generate Tolk and TypeScript wrappers**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury && /root/.acton/bin/acton wrapper Treasury --ts --output-dir wrappers-ts"
```

Expected: `wrappers/Treasury.gen.tolk` and `wrappers-ts/Treasury.gen.ts` exist. If WSL networking prevents `npx @ton/tolk-abi-to-typescript@0.5.0`, run the TypeScript wrapper command from Windows after ensuring Node/npm are available:

```powershell
& "C:\Program Files\GitHub CLI\gh.exe" --version
npx.cmd @ton/tolk-abi-to-typescript@0.5.0 --help
```

Then rerun the Acton TypeScript wrapper command after WSL network is repaired, and record the failure in `docs/research/acton-toolchain-validation.md` if it remains blocked.

- [ ] **Step 4: Verify deploy script in emulation**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton script scripts/deploy.tolk"
```

Expected: output includes `TREASURY_ADDRESS=`, `Owner count: 2`, and `Threshold: 2`.

- [ ] **Step 5: Commit deploy and wrappers**

Run:

```powershell
git add Acton.toml scripts wrappers wrappers-ts docs/research/acton-toolchain-validation.md
git commit -m "chore: add Treasury deploy script and wrappers"
```

## Task 7: Final Verification And Documentation Update

**Files:**
- Modify only if needed: `docs/research/acton-toolchain-validation.md`

- [ ] **Step 1: Run full Acton verification**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton build && /root/.acton/bin/acton test && /root/.acton/bin/acton check && /root/.acton/bin/acton fmt --check"
```

Expected: build succeeds, all Treasury tests pass, check reports no critical diagnostics, format check passes.

- [ ] **Step 2: Run wrapper generation verification**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper --all"
```

Expected: Tolk wrapper generation succeeds.

- [ ] **Step 3: Run TypeScript wrapper generation verification**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper --all --ts"
```

Expected: TypeScript wrapper generation succeeds if WSL can reach npm. If it fails due WSL network resolution/connectivity, leave generated TypeScript wrapper out of the commit and update `docs/research/acton-toolchain-validation.md` with the exact failure.

- [ ] **Step 4: Verify git status and ignored generated state**

Run:

```powershell
git status --short --branch
git status --ignored --short .acton build gen
```

Expected: branch has only intended tracked changes; `.acton/`, `build/`, and `gen/` appear only as ignored if present.

- [ ] **Step 5: Commit final normalization only if files changed**

Run:

```powershell
git status --short
```

If files changed during verification, inspect them and commit only intended source, wrapper, script, or documentation changes:

```powershell
git add Acton.toml contracts tests wrappers wrappers-ts scripts docs/research/acton-toolchain-validation.md
git commit -m "chore: verify Treasury contract baseline"
```

## Self-Review

Spec coverage:

- Owners, threshold, duplicate-owner/mismatched owner-set rejection, plain TON deposits, creator auto-approval, owner approvals, public approval getter, proposal expiry, cancellation, execution, fee reserve, and core deterministic tests are mapped to Tasks 1-5.
- Acton build, test, check, fmt, Tolk wrapper generation, TypeScript wrapper generation, and deployment script verification are mapped to Tasks 6-7.
- Splitter, Jettons, frontend, backend, Track B, anonymous/ZK approvals, and mainnet are explicitly excluded.

Placeholder scan:

- This plan contains no unfinished placeholders. The TypeScript wrapper branch has a concrete failure handling path because WSL networking was already observed as blocked during scaffold validation.

Type consistency:

- Contract key, wrapper name, imports, and tests consistently use `Treasury`.
- Message names are consistently `CreatePayoutProposal`, `ApproveProposal`, `ExecuteProposal`, and `CancelProposal`.
- Getter names are declared as snake_case in contract and called through generated wrapper names after wrapper generation confirms exact casing.
