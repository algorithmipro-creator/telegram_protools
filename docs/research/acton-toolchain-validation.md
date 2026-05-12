# Acton Toolchain Validation

## Purpose

Confirm that Acton can support the TreasuryFlow TON development workflow: scaffold, build, test, wrapper generation, deployment scripts, gas snapshots, fuzz testing, and source verification.

## Commands To Validate

| Area | Command | Expected Result | Recorded Result |
|---|---|---|---|
| Version | `acton --version` | Acton 1.0.0 or later | PASS: `acton 1.0.0 (3a4f0dc 2026-05-11)` in WSL |
| Help | `acton --help` | Command list is printed | PASS: help printed in WSL |
| Scaffold | `acton new . --template empty --name treasury-flow-ton --description 'TreasuryFlow TON contracts' --license MIT --overwrite` | Project scaffold is created | PASS: root Acton scaffold created |
| Build | `acton build` | Contracts compile | PASS: empty scaffold builds |
| Test | `acton test` | Tests pass | PASS: empty scaffold tests pass |
| Lint | `acton check` | No critical diagnostics | PASS: no critical diagnostics |
| Format | `acton fmt --check` | Formatting check passes | PASS: formatting check passes |
| Wrappers | `acton wrapper --all` | Tolk wrappers generated | Not run in scaffold baseline |
| TypeScript wrappers | `acton wrapper --all --ts` | TypeScript wrappers generated | Not run until Treasury ABI exists |
| Gas snapshot | `acton test --snapshot gas-baseline.json` | Snapshot file created | Not run until Treasury tests exist |
| Verification dry-run | `acton verify <contract> --address <address> --dry-run` | Verifier accepts sources | Not run until testnet deployment exists |

## Validation Notes

Use this file to record the exact local environment and any Windows-specific issues, including PowerShell execution policy problems, PATH problems, Node.js version problems, and Acton installation status.

Native Windows is unsupported by Acton. Local contract development runs through WSL Ubuntu 22+ from the Windows repository checkout. PowerShell commands invoke Acton through `wsl -- bash -lc ...`.

WSL outbound network access was unavailable during local validation, so Acton was installed from the official `acton-x86_64-unknown-linux-gnu.tar.gz` release archive downloaded by Windows and verified against the installer SHA-256. `acton doctor` reported local toolchain health, but external TON API reachability checks were unverified from WSL.

Treasury TypeScript wrapper generation is blocked in the current WSL setup. `acton wrapper Treasury --ts --output-dir wrappers-ts` invokes `npx @ton/tolk-abi-to-typescript@0.5.0` from WSL, but WSL resolves `npx` to the Windows shim at `/mnt/c/Program Files/nodejs/npx` and has no Linux `node` binary in PATH. The Acton command fails with `Error: \`npx @ton/tolk-abi-to-typescript@0.5.0\` failed with exit code 1: ���誮� ������� ��������� ��ப�.` Windows-side checks passed with `gh version 2.92.0` and `npx.cmd @ton/tolk-abi-to-typescript@0.5.0 --help`, but rerunning the Acton TS wrapper command from WSL failed with the same error, so `wrappers-ts/Treasury.gen.ts` was not generated.

## Minimum Accepted Toolchain

- Acton 1.0.0 or later.
- Node.js 22 LTS or later for the Vite frontend scaffold.
- npm and npx available in PATH.
- TON Center testnet API key available before public beta if rate limits interfere with deployment or indexer testing.
