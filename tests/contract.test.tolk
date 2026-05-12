import "@acton/ffi"
import "@acton/emulation/network"
import "@acton/testing/expect"
import "@acton/types/transaction"

import "@contracts/types"
import "@wrappers/Treasury.gen"

get fun `test deploy exposes treasury config`() {
    val (contract, ownerA, ownerB, _) = setupTreasury();

    expect(contract.ownerCount()).toEqual(2);
    expect(contract.threshold()).toEqual(2);
    expect(contract.proposalSeqno()).toEqual(0);
    expect(contract.feeReserve()).toEqual(DEFAULT_FEE_RESERVE);
    expect(contract.isOwner(ownerA.address)).toBeTrue();
    expect(contract.isOwner(ownerB.address)).toBeTrue();
}

get fun `test non owner cannot create proposal`() {
    val (contract, _, _, outsider) = setupTreasury();

    val res = contract.sendCreatePayoutProposal(
        outsider.address,
        outsider.address,
        ton("0.20"),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: ton("0.05") },
    );

    expect(res).toHaveFailedTx<CreatePayoutProposal>({
        from: outsider.address,
        to: contract.address,
        exitCode: Errors.NotOwner,
    });
}

get fun `test plain TON deposit succeeds`() {
    val (contract, _, _, outsider) = setupTreasury();

    val res = contract.sendAny(outsider.address, createEmptyCell(), { value: ton("0.30") });
    expect(res).toHaveSuccessfulTx({
        from: outsider.address,
        to: contract.address,
    });
}

get fun `test invalid treasury config is rejected`() {
    val ownerA = testTreasury("invalidOwnerA");
    val ownerB = testTreasury("invalidOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val badThreshold = Treasury.fromStorage(Storage {
        ownerCount: 2,
        threshold: 3,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });
    val thresholdDeploy = badThreshold.deploy(ownerA.address, { value: ton("1.00") });
    expect(thresholdDeploy).toHaveFailedTx({
        from: ownerA.address,
        to: badThreshold.address,
        exitCode: Errors.InvalidThreshold,
    });

    var duplicateCollapsedOwners: map<address, uint8> = [];
    duplicateCollapsedOwners.set(ownerA.address, OWNER_KEY_VALUE);
    val duplicateCollapsed = Treasury.fromStorage(Storage {
        ownerCount: 2,
        threshold: 1,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners: duplicateCollapsedOwners,
        proposals: [],
        approvals: [],
    });
    val duplicateDeploy = duplicateCollapsed.deploy(ownerA.address, { value: ton("1.00") });
    expect(duplicateDeploy).toHaveFailedTx({
        from: ownerA.address,
        to: duplicateCollapsed.address,
        exitCode: Errors.DuplicateOwner,
    });
}

get fun `test owner creates payout proposal with creator auto approval`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    val expiresAt = blockchain.now() + DEFAULT_EXPIRY_SECONDS;

    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        expiresAt,
        { value: ton("0.05") },
    );

    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.id).toEqual(0);
    expect(proposal.creator).toEqual(ownerA.address);
    expect(proposal.recipient).toEqual(outsider.address);
    expect(proposal.amount).toEqual(ton("0.20"));
    expect(proposal.expiresAt).toEqual(expiresAt);
    expect(proposal.status).toEqual(ProposalViewStatus.Pending);
    expect(proposal.approvalCount).toEqual(1);
    expect(contract.hasApproval(0, ownerA.address)).toBeTrue();
    expect(contract.proposalSeqno()).toEqual(1);
}

get fun `test create proposal rejects invalid amount and expiry`() {
    val (contract, ownerA, _, outsider) = setupTreasury();

    val zeroAmount = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        0,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: ton("0.05") },
    );
    expect(zeroAmount).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidAmount,
    });

    val expired = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        blockchain.now(),
        { value: ton("0.05") },
    );
    expect(expired).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidExpiry,
    });
}

get fun `test second owner approves proposal`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(2);
    expect(proposal.status).toEqual(ProposalViewStatus.Executable);
    expect(contract.hasApproval(0, ownerB.address)).toBeTrue();
}

get fun `test duplicate approval is rejected`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.AlreadyApproved,
    });

    expect(contract.proposal(0).approvalCount).toEqual(1);
}

get fun `test non owner cannot approve proposal`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(outsider.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: outsider.address,
        to: contract.address,
        exitCode: Errors.NotOwner,
    });
}

get fun `test creator cancels pending non executable proposal`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Cancelled);
}

get fun `test non creator cannot cancel proposal`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendCancelProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.NotCreator,
    });
}

get fun `test executable proposal cannot be cancelled`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.AlreadyExecutable,
    });
}

get fun `test expired proposal cannot be approved`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        blockchain.now() + 1,
        { value: ton("0.05") },
    );
    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    testSetNow((blockchain.now() + 2) as uint32);

    val approval = contract.sendApproveProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(approval).toHaveFailedTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.ProposalExpired,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Expired);
}

get fun `test execute before threshold fails`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ThresholdNotReached,
    });
}

get fun `test execute after threshold sends TON payout`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(res).toHaveTx({
        from: contract.address,
        to: recipient.address,
        value: ton("0.20"),
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Executed);
}

get fun `test execute allows exact reserve before inbound value`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.90"));
    approveProposal(contract, ownerB, 0);
    testSetBalance(contract.address, ton("1.00"));

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(res).toHaveTx({
        from: contract.address,
        to: recipient.address,
        value: ton("0.90"),
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Executed);
}

get fun `test executed proposal cannot execute twice`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);
    executeProposal(contract, ownerA, 0);

    val res = contract.sendExecuteProposal(ownerB.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}

get fun `test fee reserve prevents draining treasury`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("1.05"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InsufficientBalance,
    });
}

get fun `test expired proposal cannot be executed`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    val create = contract.sendCreatePayoutProposal(
        ownerA.address,
        recipient.address,
        ton("0.20"),
        blockchain.now() + 1,
        { value: ton("0.05") },
    );
    expect(create).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);

    testSetNow((blockchain.now() + 2) as uint32);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalExpired,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Expired);
}

get fun `test executed proposal cannot be cancelled`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);
    executeProposal(contract, ownerA, 0);

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: ton("0.05") });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}

fun setupTreasury(): (Treasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("ownerA");
    val ownerB = testTreasury("ownerB");
    val outsider = testTreasury("outsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_KEY_VALUE);
    owners.set(ownerB.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        threshold: 2,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, outsider);
}

fun createProposal(contract: Treasury, creator: TestTreasury, recipient: address, amount: coins) {
    val res = contract.sendCreatePayoutProposal(
        creator.address,
        recipient,
        amount,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: ton("0.05") },
    );
    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: creator.address,
        to: contract.address,
    });
}

fun approveProposal(contract: Treasury, owner: TestTreasury, proposalId: uint64) {
    val res = contract.sendApproveProposal(owner.address, proposalId, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ApproveProposal>({
        from: owner.address,
        to: contract.address,
    });
}

fun executeProposal(contract: Treasury, owner: TestTreasury, proposalId: uint64) {
    val res = contract.sendExecuteProposal(owner.address, proposalId, { value: ton("0.05") });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: owner.address,
        to: contract.address,
    });
}

// SAFETY: Test-only mirror of Acton's emulation time helper, limited to C7 reads.
fun testGetC7OutsideContract(): tuple
    asm "c7 PUSHCTR"

// SAFETY: Test-only mirror of Acton's emulation time helper, limited to restoring C7.
fun testSetC7OutsideContract(c7: tuple): void
    asm "c7 POPCTR"

fun testSetNow(now: uint32) {
    var c7 = testGetC7OutsideContract();
    var params = c7.get(0) as tuple;
    params.set(now, 3);
    c7.set(params, 0);
    testSetC7OutsideContract(c7);
    ffi.setNow(now);
}

fun testSetBalance(addr: address, balance: coins) {
    var shard = testGetShardAccount(addr)!;
    var account = shard.account.load();
    match (account) {
        TlbAccountInfo => {
            var storage = account.storage;
            var currency = storage.balance;
            currency.grams = balance;
            storage.balance = currency;
            account.storage = storage;
            shard.account = beginCell().storeAny<TlbAccount>(account).endCell() as Cell<TlbAccount>;
            testSetShardAccount(addr, shard);
        }
        TlbAccountNone => {
            throw 999;
        }
    }
}

fun testGetShardAccount(addr: address): TlbShardAccount? {
    val raw = ffi.getShardAccount(addr);
    if (raw == null) {
        return null;
    }
    return TlbShardAccount.fromCell(raw);
}

fun testSetShardAccount(addr: address, account: TlbShardAccount) {
    ffi.setShardAccount(addr, account.toCell());
}

// SAFETY: Uses Acton's documented emulation EXTCALL 28 to move test blockchain time.
fun ffi.setNow(now: int): void
    asm "28 EXTCALL"

// SAFETY: Test-only mirror of Acton's emulation shard-account reader.
fun ffi.getShardAccount(addr: address): cell?
    asm "33 EXTCALL"

// SAFETY: Test-only mirror of Acton's emulation shard-account writer.
fun ffi.setShardAccount(addr: address, account: cell?): void
    asm "34 EXTCALL"

struct TestTreasury {
    address: address
}

fun testTreasury(name: string): TestTreasury {
    val stateInit: ContractState = {
        code: testTreasuryCode(),
        data: beginCell().storeSlice(name.beginParse()).endCell(),
    };
    val deployer = address("0:0000000000000000000000000000000000000000000000000000000000000000");
    val address = AutoDeployAddress { stateInit }.calculateAddress();
    net.registerAddress(address, name);

    val deployMsg = createMessage({
        bounce: false,
        value: ton("10000"),
        dest: { workchain: 0, stateInit },
    });
    net.send(deployer, deployMsg);
    return TestTreasury { address };
}

// SAFETY: Embeds fixed Acton test treasury code for deterministic local test accounts.
fun testTreasuryCode(): cell asm """
    "te6cckEBBAEARQABFP8A9KQT9LzyyAsBAgEgAwIAWvLT/+1E0NP/0RK68qL0BNH4AH+OFiGAEPR4b6UgmALTB9QwAfsAkTLiAbPmWwAE0jD+omUe" base64>B B>boc PUSHREF
"""
