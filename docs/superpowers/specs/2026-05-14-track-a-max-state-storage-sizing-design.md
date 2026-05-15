# Track A Max-State Storage Sizing Design

## Goal

Replace the current approximate Track A storage reserve model with reproducible sandbox measurements for bounded proposal counts before any mainnet candidate work continues.

The first implementation target is deterministic measurement for `0`, `10`, and `100` retained proposals. A `1000` proposal scenario may be attempted only as an optional experiment if it does not make the normal Acton test suite slow or unstable.

## Context

Track A custom Tolk Treasury is already deployed and validated on testnet for the basic create, approve, and execute payout flow. PR #9 recorded the storage reserve policy and made max-state storage sizing an explicit mainnet blocker.

The current policy document uses approximate state-size values from the deployed testnet Treasury after proposal `1`. That is useful for risk framing, but it is not strong enough for release decisions. Mainnet reserve sizing needs deterministic fixtures that can be rerun after contract changes.

Relevant implementation details:

- Persistent Treasury state is held in `Storage` with `owners`, `proposals`, and `approvals` maps.
- Each proposal stores a `PayoutProposal` cell in `proposals`.
- Each approval stores one `uint256 -> uint8` entry in `approvals`.
- Acton/Tolk exposes `cell.calculateSizeStrict(maxCells)` for exact cell-tree size and `calculateStorageFee(workchain, seconds, bits, cells)` for fee estimation against the active sandbox config.

## Recommended Approach

Add a deterministic Acton sandbox measurement test/helper, then update the storage policy docs with measured results.

The measurement should use contract behavior, not manually constructed storage, so it follows the same serialization paths as real Treasury state. It should deploy a Treasury, create proposals through `sendCreatePayoutProposal`, and then measure `contract.getData()`.

The normal test suite should cover `0`, `10`, and `100` proposals. The optional `1000` scenario should be tried separately and only promoted into the normal suite if it runs quickly and reliably on the Ubuntu validation host.

## Components

### Measurement Helper

Add a small test helper near existing test utilities:

- Creates a Treasury through the existing `setupTreasury()` path.
- Creates `N` payout proposals with unique recipients or repeated safe recipients.
- Uses a long expiry so proposal status does not change during measurement.
- Measures `contract.getData().calculateSizeStrict(maxCells)`.
- Calculates storage fees for 1, 5, and 10 years with `calculateStorageFee(0, seconds, bits, cells)`.

The helper should return a compact struct or tuple with `proposalCount`, `cells`, `bits`, `refs`, `oneYearFee`, `fiveYearFee`, and `tenYearFee`.

### Deterministic Tests

Add test coverage that records and guards expected measured values for:

- `0` proposals after deploy.
- `10` pending proposals.
- `100` pending proposals.

The assertions should be deterministic but not overfit to unrelated fee-config behavior. Assert exact `cells`, `bits`, and `refs` expectations for contract data size. Compute fee values for documentation; assert them only if Acton's sandbox config makes them stable across validation hosts.

### Optional 1000 Proposal Probe

Try a `1000` proposal measurement outside the normal quality gate first. If it is fast and stable, include it in the docs as additional evidence. If it is slow, keep it out of the normal test suite and document it as not part of routine validation.

### Documentation Updates

Update `docs/research/track-a-storage-reserve-policy.md` so it distinguishes:

- Observed testnet deployed state after proposal `1`.
- Deterministic sandbox measured state for `0`, `10`, and `100` retained proposals.
- Optional `1000` measurement status if attempted.

Also update security/beta docs only if wording needs to move from "needs measured max-state tests" to "measured for bounded fixtures; retention policy still required".

## Data Flow

1. Deploy fresh Treasury in sandbox.
2. Create `N` proposals via existing contract messages.
3. Read persistent data cell with `contract.getData()`.
4. Calculate cell-tree size with `calculateSizeStrict(maxCells)`.
5. Calculate 1/5/10 year storage fee estimates from measured bits/cells.
6. Assert deterministic sizing values in tests.
7. Copy measured evidence into docs with limitations.

## Error Handling And Limits

- Use a `maxCells` value high enough for `100` proposals with margin. If `calculateSizeStrict` throws, the test should fail because the state is larger than the expected measurement bound.
- Do not send mainnet transactions or source-verifier transactions.
- Do not include wallet files, mnemonics, private keys, or verifier message bodies.
- If local Windows lacks `acton`, run final validation on the Ubuntu `tondev` environment.
- If `1000` proposals are too slow or hit emulator/resource limits, document that result instead of forcing it into the normal suite.

## Testing

Required verification after implementation:

- `acton fmt --check`
- `acton build`
- `acton test`
- `acton check`
- `git diff --check`
- Secret/placeholder scan over changed docs and tests

Because local Windows currently lacks `acton`, Acton validation should run on the Ubuntu host used for prior Track A validation.

## Success Criteria

- Sandbox tests deterministically measure Track A storage size for `0`, `10`, and `100` retained proposals.
- Storage policy docs include measured cells/bits/refs and storage fee estimates for those scenarios.
- Docs no longer rely only on the approximate linear model for the bounded scenarios.
- `1000` proposal measurement is either recorded as optional evidence or explicitly deferred with the reason.
- No contract behavior changes are introduced unless needed only for test observability, and any such change must be justified separately.
- Mainnet remains blocked until a retention policy and final reserve sizing are approved.

## Out Of Scope

- Implementing proposal pruning or cleanup.
- Implementing an off-chain indexer.
- Changing `feeReserve` in the deployed testnet Treasury.
- Changing owner/threshold governance.
- Sending final source verification transaction.
- Mainnet deployment.
