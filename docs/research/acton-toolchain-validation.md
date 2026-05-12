# Acton Toolchain Validation

## Purpose

Confirm that Acton can support the TreasuryFlow TON development workflow: scaffold, build, test, wrapper generation, deployment scripts, gas snapshots, fuzz testing, and source verification.

## Commands To Validate

| Area | Command | Expected Result | Recorded Result |
|---|---|---|---|
| Version | `acton --version` | Acton 1.0.0 or later | Not run yet |
| Help | `acton --help` | Command list is printed | Not run yet |
| Scaffold | `acton new treasury-flow-ton --template counter --app` | Project scaffold is created | Not run yet |
| Build | `acton build` | Contracts compile | Not run yet |
| Test | `acton test` | Tests pass | Not run yet |
| Lint | `acton check` | No critical diagnostics | Not run yet |
| Format | `acton fmt --check` | Formatting check passes | Not run yet |
| Wrappers | `acton wrapper --all --ts` | TypeScript wrappers generated | Not run yet |
| Gas snapshot | `acton test --snapshot gas-baseline.json` | Snapshot file created | Not run yet |
| Verification dry-run | `acton verify <contract> --address <address> --dry-run` | Verifier accepts sources | Not run yet |

## Validation Notes

Use this file to record the exact local environment and any Windows-specific issues, including PowerShell execution policy problems, PATH problems, Node.js version problems, and Acton installation status.

## Minimum Accepted Toolchain

- Acton 1.0.0 or later.
- Node.js 22 LTS or later for the Vite frontend scaffold.
- npm and npx available in PATH.
- TON Center testnet API key available before public beta if rate limits interfere with deployment or indexer testing.
