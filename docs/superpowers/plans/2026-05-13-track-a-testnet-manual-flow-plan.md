# Track A Testnet Manual Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate the deployed Track A Treasury on testnet with a real create, approve, execute payout flow to a third recipient wallet.

**Architecture:** Add small Acton/Tolk scripts that send typed Treasury messages directly through `createMessage` and configured local wallets. Scripts are network-safe by requiring the deployed Treasury address to be hardcoded for the current testnet validation and by using tiny values.

**Tech Stack:** Acton 1.0.0, Tolk scripts, Treasury message types, TON testnet.

---

## File Structure

- Modify: `scripts/testnet-create-proposal.tolk` to create proposal `0` from `ownera` to `recipient` for `0.05 TON`.
- Modify: `scripts/testnet-approve-proposal.tolk` to approve proposal `0` from `ownerb`.
- Modify: `scripts/testnet-execute-proposal.tolk` to execute proposal `0` from `ownera`.
- Modify: `docs/research/track-a-testnet-deployment.md` to append transaction evidence.

## Task 1: Create Recipient Wallet

**Files:**
- Remote only: `/home/tondev/work/telegram_protools/wallets.toml`

- [ ] **Step 1: Create local recipient wallet without printing secrets**

Run on server as `tondev`:

```bash
cd /home/tondev/work/telegram_protools
/home/tondev/.acton/bin/acton wallet new --local --secure false --name recipient --version v5r1 --json >/home/tondev/work/create-recipient.out 2>/home/tondev/work/create-recipient.err
rm -f /home/tondev/work/create-recipient.out /home/tondev/work/create-recipient.err
chmod 600 wallets.toml
/home/tondev/.acton/bin/acton wallet list --json
```

Expected: wallet list includes `recipient` with an address and no mnemonic output.

## Task 2: Add Testnet Interaction Scripts

**Files:**
- Create: `scripts/testnet-create-proposal.tolk`
- Create: `scripts/testnet-approve-proposal.tolk`
- Create: `scripts/testnet-execute-proposal.tolk`

- [ ] **Step 1: Write scripts that target deployed Treasury**

Each script must use:

```tolk
const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const PROPOSAL_ID: uint64 = 0
```

The create script sends `CreatePayoutProposal` with `recipient`, `ton("0.05")`, and `blockchain.now() + DEFAULT_EXPIRY_SECONDS`.

The approve script sends `ApproveProposal { proposalId: 0 }` from `ownerb`.

The execute script sends `ExecuteProposal { proposalId: 0 }` from `ownera`.

- [ ] **Step 2: Run local verification**

Run:

```bash
acton check scripts/testnet-create-proposal.tolk
acton check scripts/testnet-approve-proposal.tolk
acton check scripts/testnet-execute-proposal.tolk
acton fmt --check
```

Expected: all commands pass.

## Task 3: Execute Testnet Flow

**Files:**
- Remote wallet state only.

- [ ] **Step 1: Record balances before**

Run:

```bash
acton wallet list -b --json
acton rpc info --net testnet kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA
```

- [ ] **Step 2: Create proposal**

Run:

```bash
acton script scripts/testnet-create-proposal.tolk --net testnet --explorer tonviewer
```

Expected: transaction is applied and proposal `0` exists with approval count `1`.

- [ ] **Step 3: Approve proposal**

Run:

```bash
acton script scripts/testnet-approve-proposal.tolk --net testnet --explorer tonviewer
```

Expected: transaction is applied and proposal `0` becomes executable with approval count `2`.

- [ ] **Step 4: Execute proposal**

Run:

```bash
acton script scripts/testnet-execute-proposal.tolk --net testnet --explorer tonviewer
```

Expected: transaction is applied and proposal `0` status is `Executed`.

## Task 4: Record Evidence

**Files:**
- Modify: `docs/research/track-a-testnet-deployment.md`

- [ ] **Step 1: Append transaction hashes, recipient address, and final balances**

Add a `Manual Flow` section with:

- recipient address
- create proposal tx hash
- approve proposal tx hash
- execute proposal tx hash
- final Treasury and recipient balances
- decoded proposal status

- [ ] **Step 2: Verify no secrets were written**

Run:

```bash
git diff -- docs/research/track-a-testnet-deployment.md scripts/testnet-create-proposal.tolk scripts/testnet-approve-proposal.tolk scripts/testnet-execute-proposal.tolk
```

Expected: no mnemonic, `wallets.toml`, `.env`, keys, or credentials.
