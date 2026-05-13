# Ubuntu VPN Server Work Rules

These rules apply to work on `root@88.218.123.55`, which also runs Amnezia VPN for active users.

## Isolation

- Do not use `root` for development work except one-time bootstrap tasks.
- Use a dedicated Unix user: `tondev`.
- Keep the project under `/home/tondev/work/telegram_protools`.
- Keep Acton under `/home/tondev/.acton`.
- Keep Node/npm user-local if needed; prefer a user-local tarball or `nvm`, not system-wide `apt install nodejs`.
- Keep testnet wallets only under the project user, e.g. `/home/tondev/work/telegram_protools/wallets.toml`.
- Set wallet/secrets files to mode `600`.

## Do Not Touch Without Explicit Approval

- Amnezia configuration.
- VPN services or containers.
- Docker daemon, networks, containers, or compose files.
- `iptables`, `nftables`, `ufw`, routes, or NAT rules.
- System DNS configuration.
- Systemd services unrelated to the `tondev` user session.
- Mainnet wallets, mnemonics, or secrets.

## Allowed Work Scope

- Clone and update this repository as `tondev`.
- Install project-local or user-local development tooling for `tondev`.
- Run Acton build, test, check, format, wrapper generation, and testnet scripts.
- Create new testnet-only wallets for `tondev`.
- Query Toncenter/testnet APIs from the user environment.

## Safety Checks

- Before changing anything global, stop and ask.
- Before testnet deployment, verify the exact branch, Acton version, wallet names, and balances.
- Never print or commit mnemonics, `wallets.toml`, `.env`, keys, or credentials.
- Mainnet remains blocked until explicit release approval.
