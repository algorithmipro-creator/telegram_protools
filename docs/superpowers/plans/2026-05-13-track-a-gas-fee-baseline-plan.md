# Track A Gas/Fee Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record a live TON testnet gas/fee baseline for the deployed Track A Treasury using a fresh payout proposal.

**Architecture:** Add dedicated testnet gas-baseline scripts for proposal `1`, run them on the Ubuntu validation host, and document exact transaction and balance evidence. Keep contract logic unchanged and update only evidence/readiness docs after the live run.

**Tech Stack:** Acton 1.0.0, Tolk scripts, TON testnet, GitHub PR workflow, Ubuntu validation host `tondev@88.218.123.55`.

---

## Pre-Flight Constraints

- Worktree: `.worktrees/track-a-gas-fee-baseline` from the repository root.
- Branch: `track-a-gas-fee-baseline`.
- Testnet host: `ssh tondev@88.218.123.55`.
- Server repo: `/home/tondev/work/telegram_protools`.
- Acton binary: `/home/tondev/.acton/bin/acton`.
- Treasury: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Current live `proposalSeqno`: `1`, confirmed before writing this plan.
- Baseline proposal ID: `1`.
- Baseline payout amount: `0.02 TON`.
- Message value for each action: `0.05 TON`.
- Do not print or commit mnemonics, `wallets.toml`, `.env`, private keys, or verifier transaction bodies.
- Do not run mainnet commands.
- Do not send the final source verification transaction.
- Do not modify VPN, Amnezia, Docker, firewall, routes, NAT, or system DNS on the server.

## File Map

- Create `scripts/testnet-gas-baseline-create-proposal.tolk`: creates proposal `1`, prints labeled proposal evidence.
- Create `scripts/testnet-gas-baseline-approve-proposal.tolk`: owner `ownerb` approves proposal `1`, prints labeled proposal evidence.
- Create `scripts/testnet-gas-baseline-execute-proposal.tolk`: owner `ownera` executes proposal `1`, prints labeled proposal evidence.
- Create `docs/research/track-a-gas-fee-baseline.md`: records live balances, transactions, observed costs, and assessment.
- Modify `docs/beta/architecture-scorecard.md`: link the new gas/fee baseline and update the gas/fees evidence note.
- Modify `docs/research/track-a-security-checklist.md`: mark gas/fee baseline as recorded while keeping mainnet blockers.
- Modify `docs/security-model.md`: link the gas/fee baseline evidence without unblocking mainnet.

---

### Task 1: Add Dedicated Gas Baseline Scripts

**Files:**
- Create: `scripts/testnet-gas-baseline-create-proposal.tolk`
- Create: `scripts/testnet-gas-baseline-approve-proposal.tolk`
- Create: `scripts/testnet-gas-baseline-execute-proposal.tolk`

- [ ] **Step 1: Create the proposal script**

Use `apply_patch` to create `scripts/testnet-gas-baseline-create-proposal.tolk` with exactly this content:

```tolk
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const BASELINE_PROPOSAL_ID: uint64 = 1
const BASELINE_PAYOUT_AMOUNT: coins = ton("0.02")
const BASELINE_MESSAGE_VALUE: coins = ton("0.05")

fun main() {
    val ownerA = scripts.wallet("ownera");
    val recipient = scripts.wallet("recipient");
    val expiresAt = blockchain.now() + DEFAULT_EXPIRY_SECONDS;

    val createProposalMessage = createMessage({
        bounce: true,
        value: BASELINE_MESSAGE_VALUE,
        dest: TREASURY_ADDRESS,
        body: CreatePayoutProposal {
            recipient: recipient.address,
            amount: BASELINE_PAYOUT_AMOUNT,
            expiresAt,
        },
    });
    val res = net.send(ownerA.address, createProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("GAS_BASELINE_ACTION=create");
        println("GAS_BASELINE_ERROR=Create proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(TREASURY_ADDRESS, "proposal", [BASELINE_PROPOSAL_ID]);
    println("GAS_BASELINE_ACTION=create");
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("OWNER_ADDRESS={}", ownerA.address);
    println("RECIPIENT_ADDRESS={}", recipient.address);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
    println("PAYOUT_AMOUNT={:ton}", proposal.amount);
    println("MESSAGE_VALUE={:ton}", BASELINE_MESSAGE_VALUE);
}
```

- [ ] **Step 2: Create the approval script**

Use `apply_patch` to create `scripts/testnet-gas-baseline-approve-proposal.tolk` with exactly this content:

```tolk
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const BASELINE_PROPOSAL_ID: uint64 = 1
const BASELINE_MESSAGE_VALUE: coins = ton("0.05")

fun main() {
    val ownerB = scripts.wallet("ownerb");

    val approveProposalMessage = createMessage({
        bounce: true,
        value: BASELINE_MESSAGE_VALUE,
        dest: TREASURY_ADDRESS,
        body: ApproveProposal { proposalId: BASELINE_PROPOSAL_ID },
    });
    val res = net.send(ownerB.address, approveProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("GAS_BASELINE_ACTION=approve");
        println("GAS_BASELINE_ERROR=Approve proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(TREASURY_ADDRESS, "proposal", [BASELINE_PROPOSAL_ID]);
    println("GAS_BASELINE_ACTION=approve");
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("OWNER_ADDRESS={}", ownerB.address);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
    println("MESSAGE_VALUE={:ton}", BASELINE_MESSAGE_VALUE);
}
```

- [ ] **Step 3: Create the execution script**

Use `apply_patch` to create `scripts/testnet-gas-baseline-execute-proposal.tolk` with exactly this content:

```tolk
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const BASELINE_PROPOSAL_ID: uint64 = 1
const BASELINE_MESSAGE_VALUE: coins = ton("0.05")

fun main() {
    val ownerA = scripts.wallet("ownera");

    val executeProposalMessage = createMessage({
        bounce: true,
        value: BASELINE_MESSAGE_VALUE,
        dest: TREASURY_ADDRESS,
        body: ExecuteProposal { proposalId: BASELINE_PROPOSAL_ID },
    });
    val res = net.send(ownerA.address, executeProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("GAS_BASELINE_ACTION=execute");
        println("GAS_BASELINE_ERROR=Execute proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(TREASURY_ADDRESS, "proposal", [BASELINE_PROPOSAL_ID]);
    println("GAS_BASELINE_ACTION=execute");
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("OWNER_ADDRESS={}", ownerA.address);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
    println("MESSAGE_VALUE={:ton}", BASELINE_MESSAGE_VALUE);
}
```

- [ ] **Step 4: Run formatting on the new scripts**

Run from the local worktree:

```powershell
git diff -- scripts/testnet-gas-baseline-create-proposal.tolk scripts/testnet-gas-baseline-approve-proposal.tolk scripts/testnet-gas-baseline-execute-proposal.tolk
```

Expected: the three new scripts are the only script changes.

- [ ] **Step 5: Commit the scripts**

Run:

```powershell
git add -- scripts/testnet-gas-baseline-create-proposal.tolk scripts/testnet-gas-baseline-approve-proposal.tolk scripts/testnet-gas-baseline-execute-proposal.tolk
git commit -m "test: add Track A gas baseline scripts"
```

Expected: commit succeeds with three new script files.

---

### Task 2: Validate Scripts On Server Before Broadcast

**Files:**
- No local file changes.

- [ ] **Step 1: Push the branch so the server can fetch scripts**

Run from the local worktree:

```powershell
git push -u origin track-a-gas-fee-baseline
```

Expected: branch `track-a-gas-fee-baseline` is available on GitHub.

- [ ] **Step 2: Check out the branch on the Ubuntu validation host**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && git fetch origin track-a-gas-fee-baseline && git checkout track-a-gas-fee-baseline && git pull --ff-only'
```

Expected: server worktree is on branch `track-a-gas-fee-baseline` with the new scripts.

- [ ] **Step 3: Confirm proposal ID is still safe**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton rpc info --net testnet kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA'
```

Expected: decoded storage includes `proposalSeqno: 1`. If it does not, stop and ask for a revised plan before broadcasting.

- [ ] **Step 4: Validate project commands before live transactions**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton build && /home/tondev/.acton/bin/acton test && /home/tondev/.acton/bin/acton check && /home/tondev/.acton/bin/acton fmt --check'
```

Expected: build succeeds, tests report `20 passed in 1 file`, check succeeds, and format check succeeds.

---

### Task 3: Run Live Testnet Baseline

**Files:**
- Create after run: `docs/research/track-a-gas-fee-baseline.md`

- [ ] **Step 1: Record starting balances**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton rpc info --net testnet kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS && /home/tondev/.acton/bin/acton rpc info --net testnet kQA0ry4vTNE5s78It3Nfojov2wtp93XJzmSushCpIO4RbYNx && /home/tondev/.acton/bin/acton rpc info --net testnet kQAG_JvOHG9s9y-yQjj92iP4CLOMI6-nxC8SM7fvFOimzHqf && /home/tondev/.acton/bin/acton rpc info --net testnet kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA'
```

Expected: output contains `Balance:` lines for ownera, ownerb, recipient, and Treasury. Save the exact nanotons-equivalent values by converting TON to nanotons if Acton prints TON values.

- [ ] **Step 2: Create proposal `1`**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton script scripts/testnet-gas-baseline-create-proposal.tolk --net testnet --explorer tonviewer'
```

Expected: output includes `GAS_BASELINE_ACTION=create`, `PROPOSAL_ID=1`, `APPROVAL_COUNT=1`, `PAYOUT_AMOUNT=0.02`, and a Tonviewer transaction URL. Save the transaction hash and URL.

- [ ] **Step 3: Record balances after create**

Run the same balance command from Task 3 Step 1.

Expected: ownera and Treasury balances changed; ownerb and recipient are unchanged except for unrelated external activity. Save exact observed values.

- [ ] **Step 4: Approve proposal `1`**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton script scripts/testnet-gas-baseline-approve-proposal.tolk --net testnet --explorer tonviewer'
```

Expected: output includes `GAS_BASELINE_ACTION=approve`, `PROPOSAL_ID=1`, `APPROVAL_COUNT=2`, and a Tonviewer transaction URL. Save the transaction hash and URL.

- [ ] **Step 5: Record balances after approve**

Run the same balance command from Task 3 Step 1.

Expected: ownerb and Treasury balances changed; recipient is unchanged except for unrelated external activity. Save exact observed values.

- [ ] **Step 6: Execute proposal `1`**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton script scripts/testnet-gas-baseline-execute-proposal.tolk --net testnet --explorer tonviewer'
```

Expected: output includes `GAS_BASELINE_ACTION=execute`, `PROPOSAL_ID=1`, `PROPOSAL_STATUS=ProposalViewStatus.Executed`, `APPROVAL_COUNT=2`, and a Tonviewer transaction URL. Save the transaction hash and URL.

- [ ] **Step 7: Record final balances and decoded storage**

Run the same balance command from Task 3 Step 1, then run Treasury info once more:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton rpc info --net testnet kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA'
```

Expected: recipient balance increased according to observed testnet balances, Treasury proposal `1` exists, proposal `1` has approval count `2`, and proposal `1` status is executed. Compare the observed recipient delta against the nominal `0.02 TON` payout instead of assuming they are exactly equal.

- [ ] **Step 8: Create the gas/fee evidence document**

Create `docs/research/track-a-gas-fee-baseline.md` using the observed values from Task 3 Steps 1-7. The document must include these exact sections and must not include secrets:

```markdown
# Track A Gas/Fee Baseline

## Environment

- Date: 2026-05-13
- Host: Ubuntu 24.04.4 LTS server `88.218.123.55`
- User isolation: `tondev`
- Project path: `/home/tondev/work/telegram_protools`
- Branch: `track-a-gas-fee-baseline`
- Acton: `acton 1.0.0 (3a4f0dc 2026-05-11)`
- Network: TON testnet
- Treasury address: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`

## Scenario

- Proposal ID: `1`
- Payout amount: `0.02 TON`
- Create message value: `0.05 TON`
- Approve message value: `0.05 TON`
- Execute message value: `0.05 TON`
- Creator/executor wallet: `ownera` (`kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS`)
- Approver wallet: `ownerb` (`kQA0ry4vTNE5s78It3Nfojov2wtp93XJzmSushCpIO4RbYNx`)
- Recipient wallet: `recipient` (`kQAG_JvOHG9s9y-yQjj92iP4CLOMI6-nxC8SM7fvFOimzHqf`)

## Balance Timeline

| Checkpoint | ownera | ownerb | recipient | Treasury |
|---|---:|---:|---:|---:|
| Before create | observed nanotons | observed nanotons | observed nanotons | observed nanotons |
| After create | observed nanotons | observed nanotons | observed nanotons | observed nanotons |
| After approve | observed nanotons | observed nanotons | observed nanotons | observed nanotons |
| After execute | observed nanotons | observed nanotons | observed nanotons | observed nanotons |

## Transactions

| Action | Actor | Transaction | Proposal status | Approval count |
|---|---|---|---|---:|
| Create | `ownera` | observed Tonviewer URL | observed status | 1 |
| Approve | `ownerb` | observed Tonviewer URL | observed status | 2 |
| Execute | `ownera` | observed Tonviewer URL | `Executed` | 2 |

## Observed Costs

| Action | Actor | Balance before | Balance after | Known payout | Observed actor-side cost |
|---|---|---:|---:|---:|---:|
| Create | `ownera` | observed nanotons | observed nanotons | 0 | calculated nanotons |
| Approve | `ownerb` | observed nanotons | observed nanotons | 0 | calculated nanotons |
| Execute | `ownera` | observed nanotons | observed nanotons | 0 | calculated nanotons |

Recipient received: observed nanotons.

Treasury balance delta across full scenario: observed nanotons.

## Assessment

- This baseline records real testnet wallet-side costs for Track A create, approve, and execute actions.
- The data is testnet evidence, not a mainnet fee guarantee.
- The execute transaction must be interpreted with the `0.02 TON` outbound payout and `0.05 TON` attached execute message value in mind.
- No mainnet operation was performed.
- No mnemonics, `wallets.toml`, `.env`, private keys, or credentials were printed or committed.
```

Replace each `observed ...` phrase with the exact observed value before committing. If any `observed ...` phrase remains, do not commit.

---

### Task 4: Update Readiness Docs

**Files:**
- Modify: `docs/beta/architecture-scorecard.md`
- Modify: `docs/research/track-a-security-checklist.md`
- Modify: `docs/security-model.md`

- [ ] **Step 1: Update architecture scorecard gas evidence**

In `docs/beta/architecture-scorecard.md`, change the gas/fees row from:

```markdown
| Gas/fees | 15 | 3 | 0 | Real testnet balances and fees were observed, but no formal gas snapshot baseline has been recorded yet. |
```

to:

```markdown
| Gas/fees | 15 | 3 | 0 | Real testnet balances, transaction links, and observed wallet-side costs are recorded for Track A create/approve/execute; no mainnet fee guarantee exists yet. |
```

- [ ] **Step 2: Add gas evidence bullet to scorecard snapshot**

In `docs/beta/architecture-scorecard.md`, add this bullet after the source verification dry-run bullet:

```markdown
- Gas/fee baseline for create, approve, and execute: `docs/research/track-a-gas-fee-baseline.md`.
```

- [ ] **Step 3: Update security checklist mainnet blocker**

In `docs/research/track-a-security-checklist.md`, change:

```markdown
- Record gas and fee baseline for normal and rejection paths.
```

to:

```markdown
- Review recorded Track A gas/fee baseline and add rejection-path fee evidence before mainnet.
```

- [ ] **Step 4: Add gas evidence to security model**

In `docs/security-model.md`, add this bullet under `Track A hardening evidence:` after the source verification dry-run bullet:

```markdown
- Gas/fee baseline: `docs/research/track-a-gas-fee-baseline.md`.
```

- [ ] **Step 5: Commit evidence and doc updates**

Run:

```powershell
git add -- docs/research/track-a-gas-fee-baseline.md docs/beta/architecture-scorecard.md docs/research/track-a-security-checklist.md docs/security-model.md
git commit -m "docs: record Track A gas fee baseline"
```

Expected: commit succeeds with the evidence document and three readiness doc updates.

---

### Task 5: Final Verification And PR

**Files:**
- No new file changes expected unless verification reveals issues.

- [ ] **Step 1: Run server verification**

Run:

```powershell
ssh tondev@88.218.123.55 'cd /home/tondev/work/telegram_protools && /home/tondev/.acton/bin/acton build && /home/tondev/.acton/bin/acton test && /home/tondev/.acton/bin/acton check && /home/tondev/.acton/bin/acton fmt --check'
```

Expected: build succeeds, tests report `20 passed in 1 file`, check succeeds, and format check succeeds.

- [ ] **Step 2: Run local diff checks**

Run:

```powershell
git diff --check
```

Expected: no whitespace errors. Windows may print LF/CRLF warnings; warnings are acceptable if there are no whitespace errors.

- [ ] **Step 3: Check docs for accidental secrets or verifier payloads**

Run with the available repository search tool or `rg` if installed:

```powershell
rg -n "mnemonic|wallets\.toml|private key|b5ee9c|Message body: [0-9a-f]{32,}|observed nanotons|observed Tonviewer URL|calculated nanotons" docs scripts
```

Expected: no secrets, no verifier payloads, and no remaining evidence placeholders such as `observed nanotons`, `observed Tonviewer URL`, or `calculated nanotons`. If `rg` is unavailable locally, use the repository Grep tool for the same patterns.

- [ ] **Step 4: Inspect branch diff**

Run:

```powershell
git status --short --branch
git diff --stat origin/main...HEAD
git log --oneline origin/main..HEAD
```

Expected: branch contains the design commit, plan commit, script commit, and evidence commit. No unrelated root checkout changes are included.

- [ ] **Step 5: Push branch and create PR**

Run:

```powershell
git push -u origin track-a-gas-fee-baseline
gh pr create --base main --head track-a-gas-fee-baseline --title "docs: record Track A gas fee baseline" --body @'
## Summary
- Add dedicated Track A testnet gas baseline scripts for proposal create, approve, and execute.
- Record live testnet gas/fee baseline evidence with transaction links, balances, and observed wallet-side costs.
- Update architecture/security docs to point to the recorded baseline while keeping mainnet blocked.

## Test Plan
- Server: `acton build`
- Server: `acton test`
- Server: `acton check`
- Server: `acton fmt --check`
- Live testnet: create/approve/execute proposal `1`
- Local: `git diff --check`
- Local/docs: checked for secrets, verifier payloads, and unreplaced evidence placeholders
'@
```

Expected: PR URL is printed.
