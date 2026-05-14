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
- Payout amount: `0.02 TON` (`20000000` nanotons)
- Create message value: `0.05 TON`
- Approve message value: `0.05 TON`
- Execute message value: `0.05 TON`
- Creator/executor wallet: `ownera` (`kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS`)
- Approver wallet: `ownerb` (`kQA0ry4vTNE5s78It3Nfojov2wtp93XJzmSushCpIO4RbYNx`)
- Recipient wallet: `recipient` (`kQAG_JvOHG9s9y-yQjj92iP4CLOMI6-nxC8SM7fvFOimzHqf`)

## Balance Timeline

| Checkpoint | ownera | ownerb | recipient | Treasury |
|---|---:|---:|---:|---:|
| Before create | `896201913` | `1948964126` | `50000000` | `1097945544` |
| After create | `845582270` | `1948964126` | `50000000` | `1147255088` |
| After approve | `845582270` | `1898393679` | `50000000` | `1196546012` |
| After execute | `795013392` | `1898393679` | `69999928` | `1225841802` |

## Transactions

| Action | Actor | Transaction | Proposal status | Approval count |
|---|---|---|---|---:|
| Create | `ownera` | https://testnet.tonviewer.com/transaction/eb9dc3d4f96be89e1d0a2912b2196073718e7d4bad29e45670599a22fc68f098 | `ProposalViewStatus.Pending` | 1 |
| Approve | `ownerb` | https://testnet.tonviewer.com/transaction/d27b4ed69ada418ab7c1cb5d32bfc77304a2041f92bb7fa9bc040e4e1e91f63b | `ProposalViewStatus.Executable` | 2 |
| Execute | `ownera` | https://testnet.tonviewer.com/transaction/92d043b9b51cf2f99524b8b1ab5153d5f895cb6cbcacb3f864eb8d08166b6ccd | `ProposalViewStatus.Executed` | 2 |

## Observed Costs

| Action | Actor | Balance before | Balance after | Known payout | Observed actor-side cost |
|---|---|---:|---:|---:|---:|
| Create | `ownera` | `896201913` | `845582270` | 0 | `50619643` |
| Approve | `ownerb` | `1948964126` | `1898393679` | 0 | `50570447` |
| Execute | `ownera` | `845582270` | `795013392` | 0 | `50568878` |

Recipient received: `19999928` nanotons.

Treasury balance delta across full scenario: `127896258` nanotons.

## Treasury Deltas

| Segment | Treasury before | Treasury after | Delta |
|---|---:|---:|---:|
| Create | `1097945544` | `1147255088` | `49309544` |
| Approve | `1147255088` | `1196546012` | `49290924` |
| Execute | `1196546012` | `1225841802` | `29295790` |
| Full scenario | `1097945544` | `1225841802` | `127896258` |

## Final Decoded State

- `proposalSeqno`: `2`
- Proposal `1` amount: `20000000`
- Proposal `1` approval count: `2`
- Proposal `1` creator: `kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS`
- Proposal `1` recipient: `kQAG/JvOHG9s9y+yQjj92iP4CLOMI6+nxC8SM7fvFOimzHqf`
- Proposal `1` status: `1` (`Executed`)

## Assessment

- This baseline records real testnet wallet-side costs for Track A create, approve, and execute actions.
- The data is testnet evidence, not a mainnet fee guarantee.
- The execute transaction must be interpreted with the `0.02 TON` outbound payout and `0.05 TON` attached execute message value in mind.
- The observed recipient balance delta was `19999928` nanotons, `72` nanotons below the nominal payout amount, so downstream reporting should use observed balance deltas rather than assuming exact nominal receipt.
- No mainnet operation was performed.
- No mnemonics, `wallets.toml`, `.env`, private keys, or credentials were printed or committed.
