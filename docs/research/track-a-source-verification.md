# Track A Source Verification Dry Run

## Environment

- Date: 2026-05-13
- Host: Ubuntu 24.04.4 LTS server `88.218.123.55`
- User isolation: `tondev`
- Project path: `/home/tondev/work/telegram_protools`
- Branch: `main`
- Commit: `31fca96 docs: summarize Track A testnet validation`
- Acton: `acton 1.0.0 (3a4f0dc 2026-05-11)`
- Network: TON testnet
- Treasury address: `kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA`

## Initial Non-Interactive Run

Command:

```bash
/home/tondev/.acton/bin/acton verify Treasury --address kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA --net testnet --dry-run
```

Result:

```text
  -> Contract: Treasury
  -> Compiling contract
Error: Cannot prompt for wallet selection in a non-interactive environment.

Pass the wallet name explicitly. Available wallets: ownera, ownerb, recipient
  OK Compiled successfully
  -> Code hash: 0x85f218964140d0162cd0999cb2373c083a2764535579430e9d98eee0417843f1
  -> Contract address: 0QAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhXQF
```

Finding: Acton verification dry-runs compile successfully in SSH automation, but wallet selection must be explicit because the command otherwise attempts an interactive prompt.

## Successful Dry Run

Command:

```bash
/home/tondev/.acton/bin/acton verify Treasury --address kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA --net testnet --wallet ownera --dry-run
```

Result:

```text
  -> Contract: Treasury
  -> Compiling contract
  OK Compiled successfully
  -> Code hash: 0x85f218964140d0162cd0999cb2373c083a2764535579430e9d98eee0417843f1
  -> Contract address: 0QAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhXQF
  -> Using wallet: ownera 0QDCXDR7HQM0lSkKLRZ2nIEJdnjeVGQgwXUsUM5Tby2y8IZX
  -> Using built-in verifier backends
  OK Found 1 backend for testnet
  -> Collecting source files
  OK Collected 2 source files
  -> Sending sources to backend for verification
  -> Using backend: https://verifier-testnet.tonstudio.io/source
  OK Backend verification successful
  -> Waiting for Toncenter rate limit
  -> Waiting for Toncenter rate limit
  -> Collecting signatures (need 1 of 1)
  OK All signatures collected
  i Dry run mode: skipping transaction send

OK Contract verification prepared successfully!
  Message body: intentionally omitted from this document because it is a prepared verifier transaction payload.

Run without --dry-run to send the verification transaction.
```

## Assessment

- Dry-run source verification is confirmed for the deployed Track A Treasury.
- The compiled code hash is `0x85f218964140d0162cd0999cb2373c083a2764535579430e9d98eee0417843f1`, matching the deployed contract evidence.
- Acton collected 2 source files and the testnet Ton Studio verifier backend accepted them.
- No verifier transaction was sent because `--dry-run` was used.
- The prepared verifier transaction message body is intentionally not recorded in the repository.
- Final source verification transaction remains blocked until explicit approval.
- Do not publicly claim the source is verified until the final verifier transaction is sent and confirmed.
- Mainnet remains blocked.
