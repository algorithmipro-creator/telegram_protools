# Treasury Governance Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Phase 3 governance/config proposals for Track A Treasury so owners can safely change owners, payout threshold, config threshold, and fee reserve through typed on-chain proposals.

**Architecture:** Replace the single payout-only proposal model with a typed proposal envelope that supports `PayoutTon` and `SetTreasuryConfig`. Introduce `payoutThreshold`, `configThreshold`, immutable deploy-time `configThresholdMutable`, `configVersion`, derived `Stale` status, and atomic full-config execution. Keep governance typed and narrow; no arbitrary payloads, Telegram, Splitter, Jettons, backend, storage pruning, Track B, or mainnet release work.

**Tech Stack:** Acton 1.0.0, Tolk smart contracts, Acton test runner, generated Tolk and TypeScript wrappers, PowerShell host with WSL Acton commands.

---

## Source Spec

Implement:

`docs/superpowers/specs/2026-05-17-treasury-governance-config-design.md`

## Scope Check

In scope:

- storage schema migration for Track A testnet prototype;
- typed proposal envelope;
- `PayoutTon` proposal behavior compatible with existing payout behavior;
- `SetTreasuryConfig` proposal creation, approval, cancellation, and execution;
- `payoutThreshold`;
- `configThreshold`;
- immutable `configThresholdMutable`;
- `configVersion`;
- derived `Stale` status;
- config validation and deadlock prevention;
- required getters and generated wrappers;
- deterministic tests, coverage, gas snapshot, and docs updates.

Out of scope:

- Telegram Mini App;
- backend/indexer;
- Splitter;
- Jettons;
- arbitrary payload execution;
- Track B adapter;
- storage pruning or retention implementation;
- mainnet release work or mainnet-ready claims.

## Pre-Flight Rules

- Work on a dedicated branch or worktree named `treasury-governance-config`.
- Do not implement on `main`.
- Do not manually edit generated wrappers.
- Regenerate wrappers only through Acton.
- Commit after each passing TDD slice.
- If Acton wrapper generation changes ABI shapes differently than expected, inspect generated wrappers and update tests to match the actual generated API. Do not hand-edit generated wrapper files.
- If a code task exposes a design contradiction, stop and update the design spec before continuing.

Use this WSL path from the repository root:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
```

Run Acton commands through:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test"
```

## File Map

- Modify `contracts/types.tolk`: constants, errors, proposal kind/status/view types, storage shape, validation helpers, threshold helpers, stale helpers.
- Modify `contracts/Treasury.tolk`: message handlers, typed proposal creation, approval, execution, cancellation, getters.
- Modify `tests/contract.test.tolk`: migration of existing payout tests and new governance/config/stale tests.
- Generate `wrappers/Treasury.gen.tolk`: Acton-generated Tolk wrapper.
- Generate `wrappers-ts/Treasury.gen.ts`: Acton-generated TypeScript wrapper.
- Update `docs/security-model.md`: governance invariants and mainnet blockers.
- Update `docs/research/track-a-security-checklist.md`: governance readiness evidence and follow-up status.
- Update or create `gas-baseline.json`: Acton gas snapshot after implementation.

---

### Task 1: Pre-Flight Branch And Baseline

**Files:**
- No source changes.

- [ ] **Step 1: Inspect current status**

Run:

```powershell
git status --short --branch
git log --oneline --decorate --max-count=5
```

Expected:

- working tree is clean;
- `main` is aligned with `origin/main`;
- latest commits include the governance config design spec.

- [ ] **Step 2: Create isolated worktree**

Run:

```powershell
git fetch origin
git worktree add ".worktrees/treasury-governance-config" -b treasury-governance-config origin/main
Set-Location ".worktrees/treasury-governance-config"
```

Expected:

- new worktree exists;
- current branch is `treasury-governance-config`.

- [ ] **Step 3: Run baseline tests**

Run:

```powershell
$repo = (Get-Location).Path
$drive = $repo.Substring(0,1).ToLower()
$rest = $repo.Substring(3).Replace('\','/')
$wslRepo = "/mnt/$drive/$rest"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test"
```

Expected:

- current baseline tests pass.

- [ ] **Step 4: Commit**

No files changed. Do not create an empty commit.

---

### Task 2: Add Governance Config Validation Tests

**Files:**
- Modify `tests/contract.test.tolk`

- [ ] **Step 1: Replace deploy config expectations**

Update `test deploy exposes treasury config` to expect the new getters:

```tolk
expect(contract.ownerCount()).toEqual(2);
expect(contract.payoutThreshold()).toEqual(2);
expect(contract.configThreshold()).toEqual(2);
expect(contract.configThresholdMutable()).toBeFalse();
expect(contract.configVersion()).toEqual(0);
expect(contract.proposalSeqno()).toEqual(0);
expect(contract.feeReserve()).toEqual(DEFAULT_FEE_RESERVE);
```

- [ ] **Step 2: Add failing deploy validation tests**

Append tests near existing config validation tests:

```tolk
get fun `test payout threshold above config threshold is rejected`() {
    val ownerA = testTreasury("payoutAboveConfigA");
    val ownerB = testTreasury("payoutAboveConfigB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 1,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test config threshold above owner count is rejected`() {
    val ownerA = testTreasury("configAboveOwnerA");
    val ownerB = testTreasury("configAboveOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 3,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test config threshold mutable true deploy succeeds`() {
    val (contract, _, _, _) = setupTreasuryMutableConfig();
    expect(contract.configThresholdMutable()).toBeTrue();
    expect(contract.configVersion()).toEqual(0);
}
```

- [ ] **Step 3: Add setup helper for mutable config**

Append near `setupTreasury()`:

```tolk
fun setupTreasuryMutableConfig(): (Treasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("mutableOwnerA");
    val ownerB = testTreasury("mutableOwnerB");
    val outsider = testTreasury("mutableOutsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: true,
        configVersion: 0,
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

- [ ] **Step 4: Run tests and verify expected compile failure**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'deploy exposes|payout threshold above|config threshold above|mutable true deploy'"
```

Expected:

- compile fails because new storage fields, getters, and errors do not exist yet.

- [ ] **Step 5: Leave tests uncommitted**

Run:

```powershell
git status --short tests/contract.test.tolk
```

Expected:

- `tests/contract.test.tolk` is modified and uncommitted.

---

### Task 3: Implement Governance Config Storage Primitives

**Files:**
- Modify `contracts/types.tolk`
- Modify `contracts/Treasury.tolk`
- Modify `tests/contract.test.tolk`
- Modify `scripts/deploy.tolk`
- Regenerate `wrappers/Treasury.gen.tolk`
- Regenerate `wrappers-ts/Treasury.gen.ts`

- [ ] **Step 1: Add constants and errors**

In `contracts/types.tolk`, extend constants and errors:

```tolk
const MIN_FEE_RESERVE: coins = DEFAULT_FEE_RESERVE

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
    InsufficientMessageValue = 144
    InvalidPayoutThreshold = 145
    InvalidConfigThreshold = 146
    ConfigThresholdLocked = 147
    InvalidFeeReserve = 148
    ProposalStale = 149
    InvalidProposalKind = 150
}
```

- [ ] **Step 2: Replace storage threshold fields**

Replace `threshold: uint8` with:

```tolk
payoutThreshold: uint8
configThreshold: uint8
configThresholdMutable: bool
configVersion: uint32
```

Keep:

```tolk
proposalSeqno: uint64
feeReserve: coins
owners: map<address, uint8>
proposals: map<uint64, Cell<PayoutProposal>>
approvals: map<uint256, uint8>
```

- [ ] **Step 3: Add config validation helpers**

Replace `Storage.assertValidConfig` with validation of the current config:

```tolk
fun Storage.assertValidConfig(self) {
    assert (self.ownerCount >= MIN_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (self.ownerCount <= MAX_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (self.ownerMapCount() == self.ownerCount) throw Errors.DuplicateOwner;
    assert (self.payoutThreshold > 0) throw Errors.InvalidPayoutThreshold;
    assert (self.configThreshold > 0) throw Errors.InvalidConfigThreshold;
    assert (self.payoutThreshold <= self.configThreshold) throw Errors.InvalidConfigThreshold;
    assert (self.configThreshold <= self.ownerCount) throw Errors.InvalidConfigThreshold;
    assert (self.feeReserve >= MIN_FEE_RESERVE) throw Errors.InvalidFeeReserve;
}
```

- [ ] **Step 4: Update existing payout-core references**

Keep the existing `PayoutProposal` struct and payout proposal storage unchanged in this task. Update current payout logic to use the new payout threshold field:

```tolk
storage.threshold -> storage.payoutThreshold
```

Do not add `ProposalKind`, typed proposal payloads, stale behavior, or config proposal messages in this task. Those belong to Task 4 and later tasks.

- [ ] **Step 5: Update setup helpers**

In `tests/contract.test.tolk`, update `setupTreasury()` to use:

```tolk
ownerCount: 2,
payoutThreshold: 2,
configThreshold: 2,
configThresholdMutable: false,
configVersion: 0,
proposalSeqno: 0,
feeReserve: DEFAULT_FEE_RESERVE,
owners,
proposals: [],
approvals: [],
```

Update all existing `Storage { threshold: ... }` test literals to the new fields.

- [ ] **Step 6: Update deploy storage literal**

In `scripts/deploy.tolk`, replace the old `threshold` initialization with the new config fields:

```tolk
payoutThreshold: 2,
configThreshold: 2,
configThresholdMutable: false,
configVersion: 0,
```

- [ ] **Step 7: Add new getters**

In `contracts/Treasury.tolk`, replace `threshold()` getter with:

```tolk
get fun payout_threshold(): uint8 {
    val storage = lazy Storage.load();
    return storage.payoutThreshold;
}

get fun config_threshold(): uint8 {
    val storage = lazy Storage.load();
    return storage.configThreshold;
}

get fun config_threshold_mutable(): bool {
    val storage = lazy Storage.load();
    return storage.configThresholdMutable;
}

get fun config_version(): uint32 {
    val storage = lazy Storage.load();
    return storage.configVersion;
}
```

- [ ] **Step 8: Regenerate wrappers**

Run wrapper generation through Acton tooling:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury --ts --output-dir wrappers-ts"
```

Do not keep test-local getter shims after generated wrappers expose the new getters.

- [ ] **Step 9: Run validation tests**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'deploy exposes|invalid treasury config|owner count|zero threshold|payout threshold above|config threshold above|mutable true deploy'"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton script scripts/deploy.tolk"
```

Expected:

- selected tests, full tests, and deploy emulation pass.

- [ ] **Step 10: Commit**

Run:

```powershell
git add contracts/types.tolk contracts/Treasury.tolk tests/contract.test.tolk scripts/deploy.tolk wrappers/Treasury.gen.tolk wrappers-ts/Treasury.gen.ts
git commit -m "feat: add Treasury governance config primitives"
```

---

### Task 4: Migrate Payout Proposals To Typed Proposal Envelope

**Files:**
- Modify `contracts/types.tolk`
- Modify `contracts/Treasury.tolk`
- Modify `tests/contract.test.tolk`
- Regenerate `wrappers/Treasury.gen.tolk`
- Regenerate `wrappers-ts/Treasury.gen.ts`

- [ ] **Step 1: Add proposal kind and stale view status**

In `contracts/types.tolk`, extend enums:

```tolk
enum ProposalKind: uint8 {
    PayoutTon = 0
    SetTreasuryConfig = 1
}

enum ProposalViewStatus: uint8 {
    Pending = 0
    Executable = 1
    Executed = 2
    Cancelled = 3
    Expired = 4
    Stale = 5
}
```

- [ ] **Step 2: Add typed proposal envelope structs**

Replace `PayoutProposal` with a typed proposal envelope:

```tolk
struct PayoutTonPayload {
    recipient: address
    amount: coins
}

struct SetTreasuryConfigPayload {
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
    newOwners: map<address, uint8>
}

type ProposalPayload = PayoutTonPayload | SetTreasuryConfigPayload

struct Proposal {
    id: uint64
    kind: ProposalKind
    creator: address
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    status: ProposalStatus
    approvalCount: uint8
    payload: ProposalPayload
}
```

Change storage from:

```tolk
proposals: map<uint64, Cell<PayoutProposal>>
```

to:

```tolk
proposals: map<uint64, Cell<Proposal>>
```

- [ ] **Step 3: Add threshold helper**

Add:

```tolk
fun Storage.requiredThreshold(self, kind: ProposalKind): uint8 {
    if (kind == ProposalKind.PayoutTon) {
        return self.payoutThreshold;
    }
    if (kind == ProposalKind.SetTreasuryConfig) {
        return self.configThreshold;
    }
    throw Errors.InvalidProposalKind;
}
```

- [ ] **Step 4: Update payout view tests**

Update existing payout proposal assertions to read the typed proposal view:

```tolk
expect(proposal.id).toEqual(0);
expect(proposal.kind).toEqual(ProposalKind.PayoutTon);
expect(proposal.creator).toEqual(ownerA.address);
expect(proposal.status).toEqual(ProposalViewStatus.Pending);
expect(proposal.approvalCount).toEqual(1);
expect(proposal.requiredApprovalCount).toEqual(contract.payoutThreshold());
expect(proposal.configVersionAtCreation).toEqual(0);
expect(proposal.payoutRecipient).toEqual(outsider.address);
expect(proposal.payoutAmount).toEqual(ton("0.20"));
```

- [ ] **Step 5: Update ProposalView**

In `contracts/types.tolk`, replace `ProposalView` with a typed view containing neutral fields and type-specific preview fields:

```tolk
struct ProposalView {
    id: uint64
    kind: ProposalKind
    creator: address
    createdAt: uint32
    expiresAt: uint32
    configVersionAtCreation: uint32
    currentConfigVersion: uint32
    status: ProposalViewStatus
    approvalCount: uint8
    requiredApprovalCount: uint8
    payoutRecipient: address
    payoutAmount: coins
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
}
```

Use zero address and zero values for fields that do not apply to a proposal kind.

- [ ] **Step 6: Add view status priority**

Implement view-status priority:

```tolk
fun Proposal.viewStatus(self, currentConfigVersion: uint32, requiredThreshold: uint8): ProposalViewStatus {
    if (self.status == ProposalStatus.Executed) {
        return ProposalViewStatus.Executed;
    }
    if (self.status == ProposalStatus.Cancelled) {
        return ProposalViewStatus.Cancelled;
    }
    if (self.isStale(currentConfigVersion)) {
        return ProposalViewStatus.Stale;
    }
    if (self.isExpired()) {
        return ProposalViewStatus.Expired;
    }
    if (self.approvalCount >= requiredThreshold) {
        return ProposalViewStatus.Executable;
    }
    return ProposalViewStatus.Pending;
}
```

- [ ] **Step 7: Update CreatePayoutProposal handler**

In `contracts/Treasury.tolk`, create a generic `Proposal` with:

```tolk
kind: ProposalKind.PayoutTon,
configVersionAtCreation: storage.configVersion,
payload: PayoutTonPayload {
    recipient: msg.recipient,
    amount: msg.amount,
},
```

Keep creator auto-approval and proposal seqno behavior unchanged.

- [ ] **Step 8: Update approve/execute/cancel for typed proposal**

Update common checks to use:

```tolk
val required = storage.requiredThreshold(proposal.kind);
assert (!proposal.isStale(storage.configVersion)) throw Errors.ProposalStale;
```

For payout execute:

```tolk
assert (proposal.kind == ProposalKind.PayoutTon) throw Errors.InvalidProposalKind;
val payout = proposal.payload as PayoutTonPayload;
```

Then preserve the pre-inbound reserve check:

```tolk
val availableBalance = contract.getOriginalBalance() - in.valueCoins;
assert (
    availableBalance >= payout.amount + storage.feeReserve
) throw Errors.InsufficientBalance;
```

- [ ] **Step 9: Regenerate wrappers**

Run wrapper generation through Acton tooling:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury --ts --output-dir wrappers-ts"
```

- [ ] **Step 10: Run payout compatibility tests**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'owner creates payout|second owner approves|execute after threshold|exact reserve|draining|action phase|terminal|insufficient inbound|expiry|self recipient'"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton check"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton fmt --check"
```

Expected:

- selected payout tests, full tests, contract checks, and formatting pass under the typed proposal envelope.

- [ ] **Step 11: Commit**

Run:

```powershell
git add contracts/types.tolk contracts/Treasury.tolk tests/contract.test.tolk wrappers/Treasury.gen.tolk wrappers-ts/Treasury.gen.ts
git commit -m "feat: migrate payouts to typed proposals"
```

---

### Task 5: Add Config Proposal Creation And Validation

**Files:**
- Modify `contracts/types.tolk`
- Modify `contracts/Treasury.tolk`
- Modify `tests/contract.test.tolk`
- Regenerate `wrappers/Treasury.gen.tolk`
- Regenerate `wrappers-ts/Treasury.gen.ts`

- [ ] **Step 1: Add message type**

In `contracts/types.tolk`, add:

```tolk
struct (0x54524605) CreateConfigProposal {
    newOwnerCount: uint8
    newPayoutThreshold: uint8
    newConfigThreshold: uint8
    newFeeReserve: coins
    newOwners: map<address, uint8>
    expiresAt: uint32
}
```

Extend:

```tolk
type TreasuryMessage =
    CreatePayoutProposal |
    CreateConfigProposal |
    ApproveProposal |
    ExecuteProposal |
    CancelProposal
```

- [ ] **Step 2: Add failing creation tests**

Add tests:

```tolk
get fun `test owner creates config proposal with creator auto approval`() {
    val (contract, ownerA, ownerB, _) = setupTreasuryMutableConfig();
    val ownerC = testTreasury("newConfigOwnerC");
    var newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.proposalSeqno()).toEqual(1);
    expect(contract.hasApproval(0, ownerA.address)).toBeTrue();
    val proposal = contract.proposal(0);
    expect(proposal.kind).toEqual(ProposalKind.SetTreasuryConfig);
    expect(proposal.status).toEqual(ProposalViewStatus.Pending);
    expect(proposal.approvalCount).toEqual(1);
    expect(proposal.requiredApprovalCount).toEqual(contract.configThreshold());
    expect(proposal.newOwnerCount).toEqual(3);
    expect(contract.ownerCount()).toEqual(2);
    expect(contract.payoutThreshold()).toEqual(2);
    expect(contract.configThreshold()).toEqual(2);
    expect(contract.configVersion()).toEqual(0);
}
```

Add helper:

```tolk
fun twoOwnersPlus(ownerA: TestTreasury, ownerB: TestTreasury, ownerC: TestTreasury): map<address, uint8> {
    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);
    owners.set(ownerC.address, OWNER_KEY_VALUE);
    return owners;
}
```

- [ ] **Step 3: Add failing validation tests**

Add tests for:

```text
non owner cannot create config proposal
config proposal rejects duplicate owners
config proposal rejects owner count below minimum
config proposal rejects owner count above maximum
config proposal rejects config threshold zero
config proposal rejects payout threshold above config threshold
config proposal rejects config threshold above new owner count
config proposal rejects fee reserve below minimum
config proposal rejects config threshold change when locked
```

Each test should call `sendCreateConfigProposal` and expect the matching error from the design spec.

- [ ] **Step 4: Run creation tests and verify failure**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'config proposal'"
```

Expected:

- compile fails until wrapper/message implementation exists.

- [ ] **Step 5: Implement config validation helper**

Add helper in `contracts/types.tolk`:

```tolk
fun Storage.assertValidProposedConfig(
    self,
    newOwnerCount: uint8,
    newPayoutThreshold: uint8,
    newConfigThreshold: uint8,
    newFeeReserve: coins,
    newOwners: map<address, uint8>,
) {
    assert (newOwnerCount >= MIN_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (newOwnerCount <= MAX_OWNER_COUNT) throw Errors.InvalidOwnerCount;
    assert (ownerMapCount(newOwners) == newOwnerCount) throw Errors.DuplicateOwner;
    assert (newPayoutThreshold > 0) throw Errors.InvalidPayoutThreshold;
    assert (newPayoutThreshold <= newConfigThreshold) throw Errors.InvalidConfigThreshold;
    assert (newConfigThreshold <= newOwnerCount) throw Errors.InvalidConfigThreshold;
    assert (newFeeReserve >= MIN_FEE_RESERVE) throw Errors.InvalidFeeReserve;
    if (!self.configThresholdMutable) {
        assert (newConfigThreshold == self.configThreshold) throw Errors.ConfigThresholdLocked;
    }
}
```

If Tolk requires map-count helper as a free function rather than method, implement:

```tolk
fun ownerMapCount(owners: map<address, uint8>): int {
    var count = 0;
    var entry = owners.findFirst();
    while (entry.isFound) {
        count += 1;
        entry = owners.iterateNext(entry);
    }
    return count;
}
```

- [ ] **Step 6: Implement CreateConfigProposal handler**

In `contracts/Treasury.tolk`, add a match arm before `ApproveProposal`:

```tolk
CreateConfigProposal => {
    var storage = lazy Storage.load();
    storage.assertValidConfig();
    requireMinValue(in.valueCoins, MIN_CREATE_VALUE);
    storage.assertOwner(in.senderAddress);
    val now = blockchain.now();
    assert (msg.expiresAt > now) throw Errors.InvalidExpiry;
    assert (msg.expiresAt <= now + MAX_EXPIRY_SECONDS) throw Errors.InvalidExpiry;
    storage.assertValidProposedConfig(
        msg.newOwnerCount,
        msg.newPayoutThreshold,
        msg.newConfigThreshold,
        msg.newFeeReserve,
        msg.newOwners,
    );

    val proposalId = storage.proposalSeqno;
    val proposal = Proposal {
        id: proposalId,
        kind: ProposalKind.SetTreasuryConfig,
        creator: in.senderAddress,
        createdAt: now as uint32,
        expiresAt: msg.expiresAt,
        configVersionAtCreation: storage.configVersion,
        status: ProposalStatus.Pending,
        approvalCount: 1,
        payload: SetTreasuryConfigPayload {
            newOwnerCount: msg.newOwnerCount,
            newPayoutThreshold: msg.newPayoutThreshold,
            newConfigThreshold: msg.newConfigThreshold,
            newFeeReserve: msg.newFeeReserve,
            newOwners: msg.newOwners,
        },
    };

    storage.proposals.set(proposalId, proposal.toCell());
    storage.approvals.set(approvalKey(proposal.kind, proposalId, in.senderAddress), APPROVAL_KEY_VALUE);
    storage.proposalSeqno = proposalId + 1;
    storage.save();
}
```

- [ ] **Step 7: Run config creation tests**

Regenerate wrappers before running tests:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury --ts --output-dir wrappers-ts"
```

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'config proposal|threshold mutable|owner count'"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton check"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton fmt --check"
```

Expected:

- config creation and validation tests, full tests, contract checks, and formatting pass.

- [ ] **Step 8: Commit**

Run:

```powershell
git add contracts/types.tolk contracts/Treasury.tolk tests/contract.test.tolk wrappers/Treasury.gen.tolk wrappers-ts/Treasury.gen.ts
git commit -m "feat: add Treasury config proposals"
```

---

### Task 6: Implement Config Proposal Approval And Execution

**Files:**
- Modify `contracts/Treasury.tolk`
- Modify `tests/contract.test.tolk`

- [ ] **Step 1: Add threshold behavior tests**

Add tests:

```text
config proposal requires configThreshold approvals
config proposal cannot execute with only payoutThreshold approvals
creator auto approval counts for config proposal
execution of config threshold decrease still requires old current configThreshold
config proposal execution does not require proposed future configThreshold
```

Use a helper that deploys 3 owners:

```tolk
fun setupThreeOwnerTreasury(payoutThreshold: uint8, configThreshold: uint8, mutable: bool): (Treasury, TestTreasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("threeOwnerA");
    val ownerB = testTreasury("threeOwnerB");
    val ownerC = testTreasury("threeOwnerC");
    val outsider = testTreasury("threeOwnerOutsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);
    owners.set(ownerC.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 3,
        payoutThreshold,
        configThreshold,
        configThresholdMutable: mutable,
        configVersion: 0,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });
    return (contract, ownerA, ownerB, ownerC, outsider);
}
```

- [ ] **Step 2: Add execution update tests**

Add tests:

```text
execute SetTreasuryConfig updates owners
execute SetTreasuryConfig updates payoutThreshold
execute SetTreasuryConfig updates feeReserve
execute SetTreasuryConfig increments configVersion
execute SetTreasuryConfig keeps configThreshold unchanged when locked
execute SetTreasuryConfig updates configThreshold when mutable
execute SetTreasuryConfig marks proposal Executed
executed config proposal cannot be executed twice
removed owner cannot approve new proposals after execution
added owner can approve new proposals after execution
old pending payout proposal becomes Stale after config execution
old pending config proposal becomes Stale after another config execution
```

- [ ] **Step 3: Implement approval threshold checks**

In approve logic, continue to share one `ApproveProposal` message. Load proposal kind, require current owner, not stale, not expired, and no duplicate approval. Increment `approvalCount` for both proposal kinds.

- [ ] **Step 4: Implement config execution**

In `ExecuteProposal`, branch by proposal kind:

```tolk
if (proposal.kind == ProposalKind.SetTreasuryConfig) {
    val required = storage.requiredThreshold(proposal.kind);
    assert (proposal.approvalCount >= required) throw Errors.ThresholdNotReached;
    val config = proposal.payload as SetTreasuryConfigPayload;
    storage.assertValidProposedConfig(
        config.newOwnerCount,
        config.newPayoutThreshold,
        config.newConfigThreshold,
        config.newFeeReserve,
        config.newOwners,
    );
    proposal.status = ProposalStatus.Executed;
    storage.proposals.set(msg.proposalId, proposal.toCell());
    storage.ownerCount = config.newOwnerCount;
    storage.payoutThreshold = config.newPayoutThreshold;
    storage.configThreshold = config.newConfigThreshold;
    storage.feeReserve = config.newFeeReserve;
    storage.owners = config.newOwners;
    storage.configVersion = storage.configVersion + 1;
    storage.save();
    return;
}
```

Preserve payout execution in the `PayoutTon` branch.

Important execution rules:

- Required approvals must be checked against the current `storage.configThreshold`, never the proposed future threshold.
- The proposed config must have no effect unless `ExecuteProposal` succeeds.
- The config update and proposal terminal status update must happen in one successful transaction.
- After `configVersion` increments, existing pending proposals with older `configVersionAtCreation` are stale by derived view/status logic.

- [ ] **Step 5: Run execution tests**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'config proposal requires|cannot execute with only payout|execute SetTreasuryConfig|removed owner|added owner|config threshold decrease'"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton check"
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton fmt --check"
```

Expected:

- selected config approval and execution tests, full tests, contract checks, and formatting pass.

- [ ] **Step 6: Commit**

Run:

```powershell
git add contracts/Treasury.tolk tests/contract.test.tolk
git commit -m "feat: execute Treasury config proposals"
```

---

### Task 7: Implement Derived Stale Semantics

**Files:**
- Modify `contracts/types.tolk`
- Modify `contracts/Treasury.tolk`
- Modify `tests/contract.test.tolk`

- [ ] **Step 1: Add stale tests**

Add tests:

```text
payout proposal created at configVersion N becomes Stale after configVersion N plus 1
config proposal created at configVersion N becomes Stale after another config execution
stale proposal cannot be approved
stale proposal cannot be executed
stale proposal cannot be cancelled
executed proposal does not become Stale
cancelled proposal does not become Stale
stale proposal view status has priority over Expired
stale status is derived and cannot be forced by message field
```

- [ ] **Step 2: Verify failing tests**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'Stale|stale'"
```

Expected:

- stale tests fail until checks and view priority are complete.

- [ ] **Step 3: Enforce stale checks**

In approve, execute, and cancel paths, after loading pending proposal and before expiry checks:

```tolk
assert (!proposal.isStale(storage.configVersion)) throw Errors.ProposalStale;
```

- [ ] **Step 4: Confirm view status priority**

Ensure `Proposal.viewStatus` uses:

```text
Executed
Cancelled
Stale
Expired
Executable
Pending
```

- [ ] **Step 5: Run stale tests**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'Stale|stale|Expired|expired'"
```

Expected:

- selected stale and expiry tests pass.

- [ ] **Step 6: Commit**

Run:

```powershell
git add contracts/types.tolk contracts/Treasury.tolk tests/contract.test.tolk
git commit -m "feat: derive stale proposal status"
```

---

### Task 8: Implement Governance Cancellation And Deadlock Protections

**Files:**
- Modify `contracts/Treasury.tolk`
- Modify `tests/contract.test.tolk`

- [ ] **Step 1: Add cancellation tests**

Add tests:

```text
creator cancels pending config proposal
non creator cannot cancel config proposal
executable config proposal cannot be cancelled
expired config proposal cannot be cancelled
stale config proposal cannot be cancelled
```

- [ ] **Step 2: Add deadlock tests**

Add tests:

```text
reject config proposal where newOwnerCount is below locked current configThreshold
reject config proposal where newConfigThreshold is above newOwnerCount
reject owner removal that would make final configThreshold impossible
```

- [ ] **Step 3: Update cancel logic**

Use required threshold by proposal kind:

```tolk
val required = storage.requiredThreshold(proposal.kind);
assert (proposal.approvalCount < required) throw Errors.AlreadyExecutable;
```

- [ ] **Step 4: Confirm proposed config validation blocks deadlocks**

The existing `assertValidProposedConfig` from Task 5 should reject:

```text
newPayoutThreshold > newConfigThreshold
newConfigThreshold > newOwnerCount
locked newConfigThreshold != current configThreshold
```

- [ ] **Step 5: Run tests**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'cancel config|deadlock|newOwnerCount|newConfigThreshold'"
```

Expected:

- selected cancellation and deadlock tests pass.

- [ ] **Step 6: Commit**

Run:

```powershell
git add contracts/Treasury.tolk tests/contract.test.tolk
git commit -m "feat: guard Treasury config cancellation"
```

---

### Task 9: Add Required Getters And Regenerate Wrappers

**Files:**
- Modify `contracts/Treasury.tolk`
- Modify `tests/contract.test.tolk`
- Generate `wrappers/Treasury.gen.tolk`
- Generate `wrappers-ts/Treasury.gen.ts`

- [ ] **Step 1: Add getter tests**

Add tests:

```text
getters expose governance thresholds and config version
proposal kind getter returns payout and config kinds
proposal required threshold getter returns payoutThreshold for payouts
proposal required threshold getter returns configThreshold for config proposals
has approval works for typed proposals
```

- [ ] **Step 2: Implement getters**

Add or update getters:

```tolk
get fun payout_threshold(): uint8
get fun config_threshold(): uint8
get fun config_threshold_mutable(): bool
get fun config_version(): uint32
get fun proposal_kind(proposalId: uint64): ProposalKind
get fun proposal_required_threshold(proposalId: uint64): uint8
get fun has_approval(proposalId: uint64, owner: address): bool
```

`has_approval` should load the proposal to include proposal kind in the approval key:

```tolk
val proposal = storage.mustGetProposal(proposalId);
return storage.approvals.exists(approvalKey(proposal.kind, proposalId, owner));
```

- [ ] **Step 3: Run getter tests before wrapper generation**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --filter 'getter|proposal kind|required threshold|has approval'"
```

Expected:

- selected getter tests pass.

- [ ] **Step 4: Regenerate Tolk wrapper**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury"
```

Expected:

- `wrappers/Treasury.gen.tolk` updates through Acton.

- [ ] **Step 5: Regenerate TypeScript wrapper**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton wrapper Treasury --ts --output-dir wrappers-ts"
```

Expected:

- `wrappers-ts/Treasury.gen.ts` updates through Acton.

- [ ] **Step 6: Inspect wrapper diff**

Run:

```powershell
git diff -- wrappers/Treasury.gen.tolk wrappers-ts/Treasury.gen.ts
```

Expected:

- generated diffs reflect new messages, getters, statuses, errors, and proposal view fields;
- no manual edits are present.

- [ ] **Step 7: Commit**

Run:

```powershell
git add contracts/Treasury.tolk tests/contract.test.tolk wrappers/Treasury.gen.tolk wrappers-ts/Treasury.gen.ts
git commit -m "chore: regenerate Treasury governance wrappers"
```

---

### Task 10: Update Security Documentation

**Files:**
- Modify `docs/security-model.md`
- Modify `docs/research/track-a-security-checklist.md`

- [ ] **Step 1: Update security model**

Add governance invariants:

```markdown
| Current-config authority | Config changes require current owners and current config threshold |
| Typed config governance | Config changes use only `SetTreasuryConfigProposal`; arbitrary payloads remain excluded |
| Config threshold lock | `configThresholdMutable` is immutable after deploy |
| Stale after config change | Pending proposals from old config versions cannot approve, execute, or cancel |
| Governance deadlock prevention | Final config must satisfy `1 <= payoutThreshold <= configThreshold <= ownerCount` |
```

- [ ] **Step 2: Update security checklist**

Add or update rows:

```markdown
| Governance config changes | Covered by tests, needs external review | `SetTreasuryConfigProposal` updates owners, thresholds, and fee reserve atomically under current config threshold. |
| Config threshold lock | Covered by tests, needs external review | `configThresholdMutable` is deploy-time only and immutable. |
| Stale proposal semantics | Covered by tests, needs external review | Stale status is derived from `configVersionAtCreation` and current `configVersion`. |
| Governance deadlock prevention | Covered by tests, needs external review | Final config rejects impossible threshold and owner-count states. |
```

- [ ] **Step 3: Keep mainnet blocked**

Confirm docs still state:

```text
mainnet remains blocked pending review/audit and release checklist
```

- [ ] **Step 4: Commit docs**

Run:

```powershell
git add docs/security-model.md docs/research/track-a-security-checklist.md
git commit -m "docs: record Treasury governance security model"
```

---

### Task 11: Full Verification And Gas Snapshot

**Files:**
- Modify or create `gas-baseline.json`
- Modify generated files only if Acton commands regenerate them

- [ ] **Step 1: Run formatting**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton fmt"
```

Expected:

- formatting succeeds.

- [ ] **Step 2: Run build, tests, and check**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton build && /root/.acton/bin/acton test && /root/.acton/bin/acton check"
```

Expected:

- build succeeds;
- all tests pass;
- check reports no critical diagnostics.

- [ ] **Step 3: Run coverage**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --coverage"
```

Expected:

- coverage command succeeds.

- [ ] **Step 4: Generate gas snapshot**

Run:

```powershell
wsl -- bash -lc "cd '$wslRepo' && /root/.acton/bin/acton test --snapshot gas-baseline.json"
```

Expected:

- `gas-baseline.json` is created or updated.

- [ ] **Step 5: Run whitespace and hidden character checks**

Run:

```powershell
git diff --check
rg -n "[\u202A-\u202E\u2066-\u2069\u200B-\u200F\uFEFF]|mnemonic|wallets\.toml|private key|b5ee9c|Message body: [0-9a-f]{32,}" contracts tests wrappers wrappers-ts docs gas-baseline.json
```

Expected:

- no whitespace errors;
- no hidden Unicode;
- no secrets;
- references warning not to commit secrets are acceptable only in unchanged docs after inspection.

- [ ] **Step 6: Commit verification artifacts**

If formatting, wrapper generation, docs, or gas snapshot changed files, run:

```powershell
git add contracts tests wrappers wrappers-ts docs gas-baseline.json
git commit -m "chore: verify Treasury governance config"
```

If no files changed, do not create an empty commit.

---

### Task 12: Final Branch Review And PR

**Files:**
- No source changes expected.

- [ ] **Step 1: Inspect branch**

Run:

```powershell
git status --short --branch
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
```

Expected:

- worktree is clean;
- branch contains only governance config implementation, wrappers, docs, and verification artifacts.

- [ ] **Step 2: Confirm excluded scope did not enter code**

Run:

```powershell
rg -n "Telegram|Splitter|Jetton|arbitrary payload|Track B|backend|indexer|mainnet ready|mainnet-ready" contracts tests wrappers wrappers-ts
```

Expected:

- no matches in contract, tests, or wrappers.

- [ ] **Step 3: Push branch**

Run:

```powershell
git push -u origin treasury-governance-config
```

Expected:

- branch is pushed to GitHub.

- [ ] **Step 4: Create PR**

Run:

```powershell
gh pr create --base main --head treasury-governance-config --title "feat: add Treasury governance config proposals" --body @'
## Summary
- Add typed `PayoutTon` and `SetTreasuryConfig` proposal support.
- Add payout/config thresholds, immutable deploy-time config threshold mutability flag, config versioning, and derived stale proposal semantics.
- Extend tests, wrappers, docs, and gas snapshot for governance/config behavior.

## Test Plan
- `acton fmt`
- `acton build`
- `acton test`
- `acton check`
- `acton test --coverage`
- `acton test --snapshot gas-baseline.json`
- `git diff --check`
- Hidden Unicode and secret scan
'@
```

Expected:

- PR URL is printed.

## Self-Review Checklist

Spec coverage:

- Atomic `SetTreasuryConfigProposal`: Tasks 5 and 6.
- `payoutThreshold` and `configThreshold`: Tasks 2, 3, 6, 9.
- Immutable `configThresholdMutable`: Tasks 2, 3, 5, 6.
- `configVersion` and stale semantics: Tasks 3 and 7.
- Full invariant `1 <= payoutThreshold <= configThreshold <= ownerCount`: Tasks 2, 3, 5, 8.
- Current config threshold for config execution: Task 6.
- Deadlock prevention: Task 8.
- Getter/UI preview support: Task 9.
- Docs and no mainnet claim: Task 10.
- Verification and PR: Tasks 11 and 12.

Placeholder scan:

- This plan contains no placeholder markers or unspecified implementation sections.
- Every test category has named behavior and expected result.
- Every command includes expected output.

Type consistency:

- `ProposalKind.PayoutTon` and `ProposalKind.SetTreasuryConfig` are used consistently.
- `configThresholdMutable` is the deploy-time immutable flag.
- `ProposalViewStatus.Stale` is derived, not stored.
- `Errors.ProposalStale` is the stale/version mismatch error.
