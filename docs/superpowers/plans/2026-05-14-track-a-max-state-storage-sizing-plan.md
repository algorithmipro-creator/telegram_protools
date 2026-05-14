# Track A Max-State Storage Sizing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reproducible Acton sandbox measurements for Track A Treasury storage size at bounded proposal counts and record the measured reserve evidence in docs.

**Architecture:** Extend the existing Tolk contract test file with a focused storage sizing helper that reads the deployed Treasury account data cell from Acton emulation, measures the cell tree, and computes storage fees. Use the first run to collect exact measured values, then lock those values into deterministic tests and update the storage reserve policy docs.

**Tech Stack:** Acton 1.0.0, Tolk contract tests, TON cell size primitives, Markdown docs, Git.

---

## File Map

- Modify `tests/contract.test.tolk`: add storage sizing tests and helper functions near existing Treasury test utilities.
- Modify `docs/research/track-a-storage-reserve-policy.md`: replace approximate bounded scenario rows with measured sandbox evidence and preserve the testnet observed-state note.
- Modify `docs/research/track-a-security-checklist.md`: update storage sizing status after bounded fixtures are measured.
- Modify `docs/beta/architecture-scorecard.md`: update Track A gas/storage evidence wording after measured fixtures are available.
- Modify `docs/beta-test-plan.md`: update readiness wording from "needs measured max-state tests" to "bounded fixtures measured; retention policy still required".
- No contract logic files should be changed.

---

### Task 1: Add Storage Measurement Test Harness

**Files:**
- Modify: `tests/contract.test.tolk`

- [ ] **Step 1: Add the failing storage measurement test**

Insert this test after `test invalid treasury config is rejected` and before `test owner creates payout proposal with creator auto approval`:

```tolk
get fun `test storage size measurements are generated for bounded proposal counts`() {
    val zero = measureStorageScenario(0);
    val ten = measureStorageScenario(10);
    val hundred = measureStorageScenario(100);

    printStorageMeasurement(zero);
    printStorageMeasurement(ten);
    printStorageMeasurement(hundred);

    expect(zero.proposalCount).toEqual(0);
    expect(ten.proposalCount).toEqual(10);
    expect(hundred.proposalCount).toEqual(100);

    expect(zero.cells).toEqual(0);
    expect(zero.bits).toEqual(0);
    expect(zero.refs).toEqual(0);
    expect(ten.cells > zero.cells).toBeTrue();
    expect(ten.bits > zero.bits).toBeTrue();
    expect(hundred.cells > ten.cells).toBeTrue();
    expect(hundred.bits > ten.bits).toBeTrue();
}
```

This is intentionally red because `measureStorageScenario`, `printStorageMeasurement`, and `StorageMeasurement` do not exist yet. The exact `zero` size assertions are temporary and will also fail after the helper exists.

- [ ] **Step 2: Run the focused test and verify the expected red state**

Run on the Ubuntu validation host from `/home/tondev/work/telegram_protools` after syncing this branch there:

```bash
/home/tondev/.acton/bin/acton test
```

Expected: FAIL with compile errors naming `measureStorageScenario` and `printStorageMeasurement` as unknown symbols. If the command fails for unrelated environment reasons, stop and fix the environment before editing more test code.

- [ ] **Step 3: Add storage measurement constants and struct**

Insert this block before `fun setupTreasury()`:

```tolk
const STORAGE_SIZE_MAX_CELLS: int = 10000
const STORAGE_ONE_YEAR_SECONDS: int = 31536000
const STORAGE_FIVE_YEAR_SECONDS: int = 157680000
const STORAGE_TEN_YEAR_SECONDS: int = 315360000

struct StorageMeasurement {
    proposalCount: int
    cells: int
    bits: int
    refs: int
    oneYearFee: coins
    fiveYearFee: coins
    tenYearFee: coins
}
```

- [ ] **Step 4: Add storage measurement helpers**

Insert these helpers after the `StorageMeasurement` struct and before `fun setupTreasury()`:

```tolk
fun measureStorageScenario(proposalCount: int): StorageMeasurement {
    val (contract, ownerA, _, recipient) = setupTreasury();
    createStorageSizingProposals(contract, ownerA, recipient, proposalCount);
    return measureTreasuryStorage(contract, proposalCount);
}

fun createStorageSizingProposals(
    contract: Treasury,
    creator: TestTreasury,
    recipient: TestTreasury,
    proposalCount: int,
) {
    var i = 0;
    while (i < proposalCount) {
        val res = contract.sendCreatePayoutProposal(
            creator.address,
            recipient.address,
            ton("0.01"),
            blockchain.now() + DEFAULT_EXPIRY_SECONDS,
            { value: ton("0.05") },
        );
        expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
            from: creator.address,
            to: contract.address,
        });
        i += 1;
    }
}

fun measureTreasuryStorage(contract: Treasury, proposalCount: int): StorageMeasurement {
    val data = testTreasuryDataCell(contract.address);
    val (cells, bits, refs) = data.calculateSizeStrict(STORAGE_SIZE_MAX_CELLS);

    return StorageMeasurement {
        proposalCount,
        cells,
        bits,
        refs,
        oneYearFee: calculateStorageFee(0, STORAGE_ONE_YEAR_SECONDS, bits, cells),
        fiveYearFee: calculateStorageFee(0, STORAGE_FIVE_YEAR_SECONDS, bits, cells),
        tenYearFee: calculateStorageFee(0, STORAGE_TEN_YEAR_SECONDS, bits, cells),
    };
}

fun testTreasuryDataCell(addr: address): cell {
    val shard = testGetShardAccount(addr)!;
    var account = shard.account.load();
    match (account) {
        TlbAccountInfo => {
            var state = account.storage.state;
            match (state) {
                TlbAccountStateActive => {
                    return state.stateInit.data!;
                }
                else => {
                    throw 998;
                }
            }
        }
        else => {
            throw 999;
        }
    }
}

fun printStorageMeasurement(measurement: StorageMeasurement) {
    println(
        "storage-size proposals={} cells={} bits={} refs={} oneYearFee={} fiveYearFee={} tenYearFee={}",
        measurement.proposalCount,
        measurement.cells,
        measurement.bits,
        measurement.refs,
        measurement.oneYearFee,
        measurement.fiveYearFee,
        measurement.tenYearFee,
    );
}
```

- [ ] **Step 5: Run the focused test and collect measured output**

Run:

```bash
/home/tondev/.acton/bin/acton test
```

Expected: FAIL only on the temporary exact `zero.cells`, `zero.bits`, or `zero.refs` assertions. The output must include three `storage-size proposals=...` lines for proposal counts `0`, `10`, and `100`. Save those lines in the working notes for Task 2 and Task 3.

If the compile fails because `calculateStorageFee` is unavailable in the test namespace, add this import at the top of `tests/contract.test.tolk` with the other imports and rerun:

```tolk
import "@acton/tolk-stdlib/gas-payments"
```

If the compile fails because `println` formatting rejects `coins`, print fees without `{:ton}` formatting as shown in Step 4. Do not convert fees to floating TON values inside the test.

---

### Task 2: Lock Exact Storage Size Assertions

**Files:**
- Modify: `tests/contract.test.tolk`

- [ ] **Step 1: Replace temporary zero-size assertions with exact measured values**

Edit the test from Task 1 so the temporary `0` expectations for `zero.cells`, `zero.bits`, and `zero.refs` become exact integer expectations from the printed `storage-size proposals=0 ...` line.

Add exact integer expectations for the `10` and `100` proposal rows immediately after the `zero` expectations. The final test must assert these fields for all three measurements:

```tolk
expect(zero.cells).toEqual(123);
expect(zero.bits).toEqual(456);
expect(zero.refs).toEqual(7);
expect(ten.cells).toEqual(1234);
expect(ten.bits).toEqual(5678);
expect(ten.refs).toEqual(90);
expect(hundred.cells).toEqual(12345);
expect(hundred.bits).toEqual(67890);
expect(hundred.refs).toEqual(123);
```

The numbers above are examples of the required shape. In the actual file, every `toEqual(...)` argument must be the exact integer printed by the Task 1 run for that scenario and field. Do not commit the example numbers unless they exactly match the printed measurement output.

- [ ] **Step 2: Run tests and verify the exact assertions pass**

Run:

```bash
/home/tondev/.acton/bin/acton test
```

Expected: PASS with all existing Treasury tests plus the new storage sizing test. The output should still print the three measurement lines.

- [ ] **Step 3: Commit the deterministic measurement test**

Run:

```bash
git add -- tests/contract.test.tolk
git commit -m "test: measure Track A storage size fixtures"
```

Expected: commit succeeds and includes only `tests/contract.test.tolk`.

---

### Task 3: Attempt Optional 1000 Proposal Probe

**Files:**
- Modify only if stable: `tests/contract.test.tolk`
- Modify: `docs/research/track-a-storage-reserve-policy.md`

- [ ] **Step 1: Temporarily add a 1000 proposal measurement test**

Add this test after the bounded proposal measurement test:

```tolk
get fun `test storage size measurement optional thousand proposal probe`() {
    val thousand = measureStorageScenario(1000);
    printStorageMeasurement(thousand);

    expect(thousand.proposalCount).toEqual(1000);
    expect(thousand.cells > 0).toBeTrue();
    expect(thousand.bits > 0).toBeTrue();
}
```

- [ ] **Step 2: Run the optional probe once**

Run:

```bash
/home/tondev/.acton/bin/acton test
```

Expected if stable: PASS and one `storage-size proposals=1000 ...` line appears.

Expected if too slow or unstable: the test run takes materially longer than the normal suite, hits emulator limits, or fails due resource constraints. If that happens, remove the temporary 1000 test before committing and record in the docs that the `1000` proposal probe was deferred because it is not suitable for the normal quality gate.

- [ ] **Step 3: Decide whether to keep the 1000 probe**

If the run is fast and stable, replace the temporary lower-bound assertions with exact `cells`, `bits`, and `refs` values from the printed output and keep the test.

If the run is slow or unstable, delete the entire `test storage size measurement optional thousand proposal probe` function. Do not leave a skipped or flaky test in the suite.

- [ ] **Step 4: Run tests after the 1000 decision**

Run:

```bash
/home/tondev/.acton/bin/acton test
```

Expected: PASS. If the 1000 test was removed, the suite still includes exact tests for `0`, `10`, and `100` proposals.

- [ ] **Step 5: Commit the 1000 decision only if the test file changed after Task 2**

If the 1000 exact test was kept, run:

```bash
git add -- tests/contract.test.tolk
git commit -m "test: record thousand proposal storage probe"
```

If the 1000 temporary test was removed and `git status --short` shows no test change, do not create a commit for this task.

---

### Task 4: Update Storage Reserve Policy Docs

**Files:**
- Modify: `docs/research/track-a-storage-reserve-policy.md`

- [ ] **Step 1: Update the evidence section**

Replace the current evidence bullets about approximate state-size modeling with wording that separates testnet observed state from sandbox measured fixtures:

```markdown
- Track A Treasury testnet address: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Current observed deployed testnet state after proposal `1`: `45 cells`, `11094 bits`; this remains live-chain evidence, not the deterministic sizing fixture.
- Deterministic Acton sandbox fixtures now measure retained proposal scenarios for `0`, `10`, and `100` proposals through contract messages.
- Current MVP `feeReserve`: `0.1 TON`.
- Mainnet basechain storage parameters used for the policy estimate: `bit_price_ps = 1`, `cell_price_ps = 500`, `freeze_due_limit = 0.1 TON`, `delete_due_limit = 1 TON`.
```

- [ ] **Step 2: Replace the storage fee table with measured bounded rows**

Update the `Storage Fee Estimates` table so it includes rows for:

- Observed testnet after proposal `1`.
- Sandbox `0` proposals.
- Sandbox `10` proposals.
- Sandbox `100` proposals.
- Sandbox `1000` proposals only if Task 3 kept or recorded the probe.

Use this exact column structure:

```markdown
| Scenario | Source | State Size | 1 Year | 5 Years | 10 Years | Notes |
|---|---|---:|---:|---:|---:|---|
```

For sandbox rows, use the exact `cells`, `bits`, and fee values printed by `printStorageMeasurement`. Fee values should remain in nanotons unless you also calculate TON strings carefully in docs. If you include TON strings, keep the nanotons too.

- [ ] **Step 3: Update interpretation text**

Adjust the `Interpretation` section so it says:

```markdown
- `0.1 TON` remains acceptable for low-value MVP/testnet validation with a small number of proposals.
- Measured sandbox fixtures give a deterministic baseline for `0`, `10`, and `100` retained proposals.
- The measured `100` proposal scenario is the current bounded-history sizing input; mainnet still needs a chosen retention window and safety margin.
- Unbounded on-chain history remains unacceptable for mainnet scale.
```

If Task 3 removed the 1000 probe, add:

```markdown
- The `1000` proposal scenario is intentionally not part of routine validation until it can be measured without slowing or destabilizing the suite.
```

If Task 3 kept the 1000 probe, add:

```markdown
- The `1000` proposal scenario is recorded as stress evidence, not as a recommended normal treasury retention target.
```

- [ ] **Step 4: Update limitations**

In `Limitations`, replace the old line about linear assumptions with:

```markdown
- Bounded scenario sizes are measured in Acton sandbox from contract messages; live-chain state can differ because of code/data layout, network config, and future contract changes.
- Network config can change; values must be regenerated before mainnet release.
- This document does not implement cleanup, pruning, indexer behavior, or contract-level reserve changes.
```

- [ ] **Step 5: Review the doc diff**

Run:

```bash
git diff -- docs/research/track-a-storage-reserve-policy.md
```

Expected: the diff replaces approximate bounded scenario language with measured sandbox fixture evidence and keeps mainnet blocked until retention policy approval.

---

### Task 5: Update Security And Beta Status Docs

**Files:**
- Modify: `docs/research/track-a-security-checklist.md`
- Modify: `docs/beta/architecture-scorecard.md`
- Modify: `docs/beta-test-plan.md`

- [ ] **Step 1: Update security checklist storage status**

In `docs/research/track-a-security-checklist.md`, change the storage sizing row from:

```markdown
| Storage reserve sizing | Policy recorded, needs measured max-state tests | See `docs/research/track-a-storage-reserve-policy.md`; regenerate estimates before mainnet. |
```

to:

```markdown
| Storage reserve sizing | Bounded fixtures measured, needs mainnet retention decision | See `docs/research/track-a-storage-reserve-policy.md`; regenerate estimates from current network config before mainnet. |
```

- [ ] **Step 2: Update security checklist mainnet blocker**

In `docs/research/track-a-security-checklist.md`, change:

```markdown
- Measure max-state storage size and approve bounded history or cleanup/indexer strategy before mainnet.
```

to:

```markdown
- Approve bounded history or cleanup/indexer strategy and regenerate storage sizing before mainnet.
```

- [ ] **Step 3: Update architecture scorecard gas/storage wording**

In `docs/beta/architecture-scorecard.md`, change the `Gas/fees` row to:

```markdown
| Gas/fees | 15 | 3 | 0 | Real testnet action costs and measured sandbox storage fixtures are recorded for Track A; mainnet still needs retention policy approval and final network-config sizing. |
```

- [ ] **Step 4: Update architecture scorecard decision blocker**

In `docs/beta/architecture-scorecard.md`, change the `Current Decision` paragraph so the blocker phrase becomes:

```markdown
final source verification transaction, bounded history or cleanup/indexer policy, final storage reserve sizing from current network config, security review/audit readiness, and a release checklist
```

Keep the rest of the paragraph unchanged.

- [ ] **Step 5: Update beta test plan progress and readiness wording**

In `docs/beta-test-plan.md`, change:

```markdown
- Storage reserve policy is recorded in `docs/research/track-a-storage-reserve-policy.md`; mainnet reserve sizing still requires measured max-state tests.
```

to:

```markdown
- Storage reserve policy is recorded in `docs/research/track-a-storage-reserve-policy.md`; bounded sandbox fixtures are measured, but mainnet reserve sizing still requires retention policy approval and current network config.
```

Then change:

```markdown
- Measure max-state storage size and decide bounded on-chain history versus cleanup/indexer strategy before mainnet candidate work.
```

to:

```markdown
- Decide bounded on-chain history versus cleanup/indexer strategy and regenerate final storage reserve sizing before mainnet candidate work.
```

- [ ] **Step 6: Review doc diffs**

Run:

```bash
git diff -- docs/research/track-a-security-checklist.md docs/beta/architecture-scorecard.md docs/beta-test-plan.md
```

Expected: wording moves from "measurement missing" to "bounded fixtures measured; retention/final sizing still blocked".

- [ ] **Step 7: Commit documentation updates**

Run:

```bash
git add -- docs/research/track-a-storage-reserve-policy.md docs/research/track-a-security-checklist.md docs/beta/architecture-scorecard.md docs/beta-test-plan.md
git commit -m "docs: record measured storage sizing evidence"
```

Expected: commit succeeds and includes only docs.

---

### Task 6: Full Verification And PR Readiness

**Files:**
- No new file changes expected unless verification finds a concrete issue.

- [ ] **Step 1: Run formatting check**

Run on Ubuntu validation host:

```bash
/home/tondev/.acton/bin/acton fmt --check
```

Expected: PASS. If formatting fails, run `/home/tondev/.acton/bin/acton fmt`, review the diff, and commit formatting changes with the relevant code/doc commit if not already committed.

- [ ] **Step 2: Run build**

Run:

```bash
/home/tondev/.acton/bin/acton build
```

Expected: PASS.

- [ ] **Step 3: Run tests**

Run:

```bash
/home/tondev/.acton/bin/acton test
```

Expected: PASS. The suite must include exact storage size assertions for `0`, `10`, and `100` proposals.

- [ ] **Step 4: Run Acton check**

Run:

```bash
/home/tondev/.acton/bin/acton check
```

Expected: PASS.

- [ ] **Step 5: Run whitespace check**

Run locally or on Ubuntu:

```bash
git diff --check
```

Expected: no whitespace errors. Windows CRLF warnings are acceptable only if no whitespace errors are reported.

- [ ] **Step 6: Scan changed files for secrets and placeholders**

Run:

```bash
git grep -n -I -E "T[B]D|T[O]DO|FIXME|wallets\.toml|mnemonic|private key|b5ee9c|Message body: [0-9a-f]{32,}" -- tests/contract.test.tolk docs/research/track-a-storage-reserve-policy.md docs/research/track-a-security-checklist.md docs/beta/architecture-scorecard.md docs/beta-test-plan.md docs/superpowers/specs/2026-05-14-track-a-max-state-storage-sizing-design.md docs/superpowers/plans/2026-05-14-track-a-max-state-storage-sizing-plan.md
```

Expected: no matches except policy text that explicitly says not to include secrets. If the plan file matches because it contains this scan command, that is acceptable.

- [ ] **Step 7: Review branch diff**

Run:

```bash
git status --short --branch
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD -- tests/contract.test.tolk docs/research/track-a-storage-reserve-policy.md docs/research/track-a-security-checklist.md docs/beta/architecture-scorecard.md docs/beta-test-plan.md
```

Expected: branch contains the design spec commit, this implementation plan commit, test measurement commit, optional 1000 decision commit if kept, and docs evidence commit. Root checkout unrelated local changes are not included.

- [ ] **Step 8: Commit this implementation plan if it is not already committed**

Run:

```bash
git add -- docs/superpowers/plans/2026-05-14-track-a-max-state-storage-sizing-plan.md
git commit -m "docs: plan Track A max-state storage sizing"
```

Expected: commit succeeds if the plan was not committed earlier. If `git status --short` shows the plan already committed, skip this step.

---

### Task 7: Code Review And Pull Request

**Files:**
- No file changes expected unless review finds a concrete issue.

- [ ] **Step 1: Request code review**

Use the code review workflow with:

```text
Base SHA: origin/main
Head SHA: HEAD
What was implemented: Track A deterministic storage sizing tests and measured storage reserve evidence docs.
Requirements: no contract logic changes, no secrets, `0/10/100` proposal fixtures measured and exact assertions added, optional `1000` documented or kept only if stable, mainnet remains blocked until retention/final reserve policy.
```

Expected: reviewer returns no Critical or Important findings. Fix valid findings before continuing.

- [ ] **Step 2: Push branch**

Run:

```bash
git push -u origin track-a-max-state-storage-sizing
```

Expected: branch is pushed.

- [ ] **Step 3: Create PR**

Run:

```bash
gh pr create --base main --head track-a-max-state-storage-sizing --title "test: measure Track A storage sizing fixtures" --body @'
## Summary
- Add deterministic Acton sandbox storage sizing fixtures for Track A Treasury retained proposal counts.
- Record measured cells/bits/refs and storage fee evidence in the storage reserve policy docs.
- Update security, beta, and scorecard docs to keep mainnet blocked on retention policy and final reserve sizing.

## Test Plan
- `/home/tondev/.acton/bin/acton fmt --check`
- `/home/tondev/.acton/bin/acton build`
- `/home/tondev/.acton/bin/acton test`
- `/home/tondev/.acton/bin/acton check`
- `git diff --check`
- Secret/placeholder scan over changed tests and docs
'@
```

Expected: PR URL is printed.
