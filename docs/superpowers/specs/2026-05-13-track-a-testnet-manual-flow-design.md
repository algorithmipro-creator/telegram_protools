# Track A Testnet Manual Flow Design

## Purpose

Validate the deployed Track A Treasury contract on TON testnet with a real end-to-end payout flow: proposal creation, second-owner approval, execution, and recipient balance verification.

## Scope

- Network: testnet only.
- Host: Ubuntu server `88.218.123.55`.
- User isolation: `tondev` only.
- Deployed Treasury: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`.
- Owners:
  - `ownera`: `kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS`
  - `ownerb`: `kQA0ry4vTNE5s78It3Nfojov2wtp93XJzmSushCpIO4RbYNx`

## Design

Create a third local testnet wallet named `recipient` under `/home/tondev/work/telegram_protools/wallets.toml`. The recipient wallet is testnet-only and is used to verify that executed payouts transfer TON to a non-owner destination.

Use a small payout amount, `0.05 TON`, to preserve testnet balance while still proving real transfer behavior. `ownera` creates proposal `0`, `ownerb` approves it, and `ownera` executes it after the threshold is reached.

## Safety Rules

- Do not touch Amnezia, VPN services, Docker, firewall, routes, NAT, or system DNS.
- Do not use mainnet.
- Do not print mnemonics, `wallets.toml`, `.env`, keys, or credentials.
- Keep all wallet files mode `600` and owned by `tondev`.
- Stop if any transaction fails or decoded storage does not match expectations.

## Success Criteria

- `recipient` wallet exists and has a testnet address.
- Proposal creation transaction is observed on testnet.
- Approval transaction from `ownerb` is observed on testnet.
- Execution transaction is observed on testnet.
- `proposal(0)` reports `Executed` after execution.
- `recipient` balance increases by the payout amount minus any wallet-side fees only if it later sends messages; for a passive recipient, the received value should be visible as incoming balance.
- Evidence is added to `docs/research/track-a-testnet-deployment.md` without secrets.

## Out of Scope

- Mainnet deployment.
- UI/backend/indexer work.
- Jettons or Splitter logic.
- Anonymous approvals.
- Changing deployed Treasury code.
