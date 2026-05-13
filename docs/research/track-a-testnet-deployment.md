# Track A Testnet Deployment

## Environment

- Date: 2026-05-13
- Host: Ubuntu 24.04.4 LTS server `88.218.123.55`
- User isolation: `tondev`
- Project path: `/home/tondev/work/telegram_protools`
- Branch: `fix-deploy-wallet-names`
- Commit: `c171526 fix: use lowercase deploy wallet names`
- Acton: `acton 1.0.0 (3a4f0dc 2026-05-11)`

## Verification

Command:

```bash
acton build && acton test && acton check && acton fmt --check && acton script scripts/deploy.tolk
```

Result:

- Build: pass
- Tests: `20 passed in 1 file`
- Check: pass
- Format check: pass
- Emulated deploy script: pass

## Testnet Wallets

- `ownera`: `kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS`
- `ownerb`: `kQA0ry4vTNE5s78It3Nfojov2wtp93XJzmSushCpIO4RbYNx`

Balances before deploy:

- `ownera`: `1999999999` nanotons
- `ownerb`: `1999999999` nanotons

## Deployment

Command:

```bash
acton script scripts/deploy.tolk --net testnet --explorer tonviewer
```

Result:

- Treasury address: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`
- Transaction: `527e66692a2fb3226025b5b6dbb96834e82c102c129a2a682d96d16a3cb70c7f`
- Explorer: https://testnet.tonviewer.com/transaction/527e66692a2fb3226025b5b6dbb96834e82c102c129a2a682d96d16a3cb70c7f
- Owner count: `2`
- Threshold: `2`
- Fee reserve: `0.1 TON`

## On-Chain Verification

Command:

```bash
acton rpc info --net testnet kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA
```

Result:

- Status: `active`
- Balance: `0.999734932 TON`
- Last Tx LT: `69333579000003`
- Last Tx Hash: `qE7e3MFmmX4Cn9RGKi0zfh5oPFT0hqLoa7Ln392T46M=`
- Code Hash: `0x85f218964140d0162cd0999cb2373c083a2764535579430e9d98eee0417843f1`
- Data Hash: `0x62075e9338c2d0ad66ab79f51a0066bdc3146f80660aff01ed929e8259a5327f`

Decoded storage:

- `ownerCount`: `2`
- `threshold`: `2`
- `proposalSeqno`: `0`
- `feeReserve`: `100000000`
- `owners`:
  - `kQA0ry4vTNE5s78It3Nfojov2wtp93XJzmSushCpIO4RbYNx`
  - `kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS`
- `proposals`: empty
- `approvals`: empty

Balances after deploy:

- `ownera`: `997388928` nanotons
- `ownerb`: `1999999999` nanotons
- Treasury: `999734932` nanotons

## Notes

- Server work followed `docs/operations/ubuntu-vpn-server-work-rules.md`.
- No mainnet operation was performed.
- No mnemonics, `wallets.toml`, `.env`, keys, or credentials were printed or committed.

## Manual Flow

Purpose: validate real testnet payout lifecycle after deployment.

Recipient wallet:

- `recipient`: `kQAG_JvOHG9s9y-yQjj92iP4CLOMI6-nxC8SM7fvFOimzHqf`

Pre-flow balances:

- `ownera`: `997388928` nanotons
- `ownerb`: `1999999999` nanotons
- `recipient`: `0` nanotons
- Treasury: `0.999734932 TON`

Create proposal:

- Command: `acton script scripts/testnet-create-proposal.tolk --net testnet --explorer tonviewer`
- Transaction: `869e952d66ea95e64f8535b3a7d7ce030bcbc3c1e6e419e7682706d68156efd9`
- Explorer: https://testnet.tonviewer.com/transaction/869e952d66ea95e64f8535b3a7d7ce030bcbc3c1e6e419e7682706d68156efd9
- Proposal ID: `0`
- Status after create: `ProposalViewStatus.Pending`
- Approval count after create: `1`
- Payout amount: `0.05 TON`

Approve proposal:

- Command: `acton script scripts/testnet-approve-proposal.tolk --net testnet --explorer tonviewer`
- Transaction: `ead1526f089ee7c2689d003b8d07f84e0d948b75b41021bee2937fd51858d6b2`
- Explorer: https://testnet.tonviewer.com/transaction/ead1526f089ee7c2689d003b8d07f84e0d948b75b41021bee2937fd51858d6b2
- Proposal ID: `0`
- Status after approve: `ProposalViewStatus.Executable`
- Approval count after approve: `2`

Execute proposal:

- Command: `acton script scripts/testnet-execute-proposal.tolk --net testnet --explorer tonviewer`
- Transaction: `ba43948018c3621993005c5476bea0f0ecd66e051317fce6975876bd23a850e8`
- Explorer: https://testnet.tonviewer.com/transaction/ba43948018c3621993005c5476bea0f0ecd66e051317fce6975876bd23a850e8
- Proposal ID: `0`
- Status after execute: `ProposalViewStatus.Executed`
- Approval count after execute: `2`

Final balances:

- `ownera`: `896201913` nanotons
- `ownerb`: `1948964126` nanotons
- `recipient`: `50000000` nanotons
- Treasury: `1.097945544 TON`

Decoded final proposal storage:

- `proposalSeqno`: `1`
- Proposal `0` amount: `50000000`
- Proposal `0` approval count: `2`
- Proposal `0` creator: `kQDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8NuS`
- Proposal `0` recipient: `kQAG/JvOHG9s9y+yQjj92iP4CLOMI6+nxC8SM7fvFOimzHqf`
- Proposal `0` status: `1` (`Executed`)
