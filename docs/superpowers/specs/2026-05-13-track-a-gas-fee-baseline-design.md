# Track A Gas/Fee Baseline Design

## Goal

Record a real TON testnet gas/fee baseline for the deployed Track A custom Treasury by running a fresh payout lifecycle and documenting observed wallet and Treasury balance deltas.

## Context

Track A has deterministic contract tests, testnet deployment evidence, a manual payout flow for proposal `0`, source verification dry-run evidence, and a security review checklist. The architecture scorecard still notes that no formal gas/fee baseline has been recorded.

This work closes that evidence gap for Track A only. It does not change contract logic, does not run mainnet operations, does not send the final source verification transaction, and does not make any public claim that source verification is complete.

## Environment

The live baseline will run on the Ubuntu validation host as user `tondev` from `/home/tondev/work/telegram_protools`. The local Windows/WSL environment remains unreliable for Acton network execution, so local execution is not the source of truth for this task.

Server work must continue following `docs/operations/ubuntu-vpn-server-work-rules.md`: use the isolated `tondev` user, do not touch VPN/Amnezia/Docker/firewall/routing/system DNS, and never print or commit wallet secrets.

## Approach

Use a new live testnet proposal instead of reusing proposal `0`. The baseline should run the same user-visible lifecycle that beta users will depend on:

1. Record starting balances for `ownera`, `ownerb`, `recipient`, and the Treasury.
2. Create a new payout proposal from `ownera` with a small payout amount.
3. Record the create transaction hash, explorer URL, proposal state, approval count, and balances after create.
4. Approve the proposal from `ownerb`.
5. Record the approve transaction hash, explorer URL, proposal state, approval count, and balances after approve.
6. Execute the proposal from `ownera`.
7. Record the execute transaction hash, explorer URL, proposal state, approval count, recipient receipt, and final balances.
8. Calculate observed costs from balance deltas, separating payout amount from wallet-side transaction costs.

## Data Model

Create `docs/research/track-a-gas-fee-baseline.md` with these sections:

- Environment: date, host, user, repo commit, Acton version, network, Treasury address.
- Scenario: proposal ID, sender wallets, recipient wallet, payout amount, attached message values.
- Balance timeline: balances before create, after create, after approve, after execute.
- Transaction table: action, actor, transaction hash, explorer URL, observed proposal state, approval count.
- Observed cost table: actor, balance before, balance after, known payout amount where applicable, observed wallet-side cost.
- Assessment: what the data proves, what it does not prove, and mainnet limitations.

Use nanotons for exact arithmetic and TON values only as human-readable annotations. Do not record mnemonics, `wallets.toml`, private keys, environment files, verifier transaction bodies, or other secrets.

## Scripts

The existing scripts are fixed to proposal `0` and were useful for the first manual flow. For this baseline, add dedicated testnet scripts instead of editing the old evidence scripts in place. This keeps the original manual-flow reproduction stable and makes the gas baseline explicit.

The new scripts should hard-code only public testnet addresses, public proposal constants, payout amount, and attached values. They should print machine-readable labels for transaction hash, proposal ID, proposal status, approval count, and relevant balances so the evidence can be copied into the research doc without parsing secrets.

Expected scripts:

- `scripts/testnet-gas-baseline-create-proposal.tolk`
- `scripts/testnet-gas-baseline-approve-proposal.tolk`
- `scripts/testnet-gas-baseline-execute-proposal.tolk`

The implementation plan should confirm the next proposal ID from on-chain storage before choosing script constants. If the deployed Treasury already has `proposalSeqno = 1`, the baseline proposal should use ID `1`.

## Calculations

Observed costs should be calculated from balance deltas, not assumed from explorer UI labels.

For create:

```text
ownera_create_cost = ownera_before_create - ownera_after_create
```

For approve:

```text
ownerb_approve_cost = ownerb_before_approve - ownerb_after_approve
```

For execute:

```text
ownera_execute_cost = ownera_before_execute - ownera_after_execute
recipient_received = recipient_after_execute - recipient_before_execute
treasury_delta = treasury_after_execute - treasury_before_execute
```

The execute assessment must explicitly separate recipient payout from `ownera` transaction cost. If the Treasury receives attached value during execute, the Treasury balance delta may include both inbound value and outbound payout effects.

## Documentation Updates

Update these docs after the baseline is recorded:

- `docs/beta/architecture-scorecard.md`: replace the current gas/fees caveat with a link to the baseline evidence while keeping mainnet blocked.
- `docs/research/track-a-security-checklist.md`: mark gas/fee baseline as recorded, while keeping external review/audit as required.
- `docs/security-model.md`: keep gas/fee understanding as a mainnet blocker unless the evidence is judged sufficient later.

## Verification

Before opening a PR, run:

- Server: `/home/tondev/.acton/bin/acton build`
- Server: `/home/tondev/.acton/bin/acton test`
- Server: `/home/tondev/.acton/bin/acton check`
- Server: `/home/tondev/.acton/bin/acton fmt --check`
- Local: `git diff --check`
- Local docs scan for accidental secrets and prepared verifier payloads.

Local Windows `acton` is not expected to work unless the toolchain has changed.

## Success Criteria

- A fresh proposal is created, approved, and executed on TON testnet.
- The recipient receives the expected testnet payout.
- Transaction hashes and explorer URLs are recorded for create, approve, and execute.
- Balance snapshots allow observed wallet-side costs to be calculated.
- `docs/research/track-a-gas-fee-baseline.md` records the baseline without secrets.
- Scorecard and security docs link to the baseline evidence.
- Mainnet remains blocked.

## Out Of Scope

- Mainnet deployment or mainnet transactions.
- Final source verification transaction.
- Contract logic changes.
- Track B official multisig v2 validation.
- Frontend, backend/indexer, Splitter, Jettons, anonymous approvals, or ZK flows.
- General gas optimization work.
