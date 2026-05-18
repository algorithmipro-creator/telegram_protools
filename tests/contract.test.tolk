import "@acton/ffi"
import "@acton/emulation/network"
import "@acton/testing/expect"
import "@acton/tlb/maybe"
import "@acton/types/transaction"

import "@contracts/types"
import "@wrappers/Treasury.gen"

get fun `test deploy exposes treasury config`() {
    val (contract, ownerA, ownerB, _) = setupTreasury();

    expect(contract.ownerCount()).toEqual(2);
    expect(contract.payoutThreshold()).toEqual(2);
    expect(contract.configThreshold()).toEqual(2);
    expect(contract.configThresholdMutable()).toBeFalse();
    expect(contract.configVersion()).toEqual(0);
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
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val badThreshold = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 3,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });
    val thresholdDeploy = badThreshold.deploy(ownerA.address, { value: ton("1.00") });
    expect(thresholdDeploy).toHaveFailedTx({
        from: ownerA.address,
        to: badThreshold.address,
        exitCode: Errors.InvalidConfigThreshold,
    });

    var duplicateCollapsedOwners: map<address, uint8> = [];
    duplicateCollapsedOwners.set(ownerA.address, OWNER_INDEX_0);
    val duplicateCollapsed = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 1,
        configThreshold: 1,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners: duplicateCollapsedOwners,
        proposals: [],
    });
    val duplicateDeploy = duplicateCollapsed.deploy(ownerA.address, { value: ton("1.00") });
    expect(duplicateDeploy).toHaveFailedTx({
        from: ownerA.address,
        to: duplicateCollapsed.address,
        exitCode: Errors.DuplicateOwner,
    });
}

get fun `test duplicate owner indexes are rejected`() {
    val ownerA = testTreasury("duplicateIndexOwnerA");
    val ownerB = testTreasury("duplicateIndexOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, 0);
    owners.set(ownerB.address, 0);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.DuplicateOwner,
    });
}

get fun `test owner index outside owner count is rejected`() {
    val ownerA = testTreasury("badIndexOwnerA");
    val ownerB = testTreasury("badIndexOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, 0);
    owners.set(ownerB.address, 2);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidOwnerCount,
    });
}

get fun `test owner count below minimum is rejected`() {
    val ownerA = testTreasury("singleOwnerA");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: MIN_OWNER_COUNT - 1,
        payoutThreshold: 1,
        configThreshold: 1,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidOwnerCount,
    });
}

get fun `test owner count above maximum is rejected`() {
    val owner1 = testTreasury("maxOwner1");
    val owner2 = testTreasury("maxOwner2");
    val owner3 = testTreasury("maxOwner3");
    val owner4 = testTreasury("maxOwner4");
    val owner5 = testTreasury("maxOwner5");
    val owner6 = testTreasury("maxOwner6");
    val owner7 = testTreasury("maxOwner7");
    val owner8 = testTreasury("maxOwner8");
    val owner9 = testTreasury("maxOwner9");
    val owner10 = testTreasury("maxOwner10");
    val owner11 = testTreasury("maxOwner11");

    var owners: map<address, uint8> = [];
    owners.set(owner1.address, 0);
    owners.set(owner2.address, 1);
    owners.set(owner3.address, 2);
    owners.set(owner4.address, 3);
    owners.set(owner5.address, 4);
    owners.set(owner6.address, 5);
    owners.set(owner7.address, 6);
    owners.set(owner8.address, 7);
    owners.set(owner9.address, 8);
    owners.set(owner10.address, 9);
    owners.set(owner11.address, 10);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: MAX_OWNER_COUNT + 1,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(owner1.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: owner1.address,
        to: contract.address,
        exitCode: Errors.InvalidOwnerCount,
    });
}

get fun `test zero threshold is rejected`() {
    val ownerA = testTreasury("zeroThresholdA");
    val ownerB = testTreasury("zeroThresholdB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 0,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidPayoutThreshold,
    });
}

get fun `test config threshold zero is rejected`() {
    val ownerA = testTreasury("zeroConfigThresholdA");
    val ownerB = testTreasury("zeroConfigThresholdB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 1,
        configThreshold: 0,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test payout threshold above config threshold is rejected`() {
    val ownerA = testTreasury("payoutAboveConfigA");
    val ownerB = testTreasury("payoutAboveConfigB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 1,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test config threshold above owner count is rejected`() {
    val ownerA = testTreasury("configAboveOwnerA");
    val ownerB = testTreasury("configAboveOwnerB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 3,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test fee reserve below minimum is rejected`() {
    val ownerA = testTreasury("feeReserveBelowA");
    val ownerB = testTreasury("feeReserveBelowB");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: MIN_FEE_RESERVE - 1,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveFailedTx({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidFeeReserve,
    });
}

get fun `test config threshold mutable true deploy succeeds`() {
    val (contract, _, _, _) = setupTreasuryMutableConfig();
    expect(contract.configThresholdMutable()).toBeTrue();
    expect(contract.configVersion()).toEqual(0);
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
    expect(proposal.kind).toEqual(ProposalKind.PayoutTon);
    expect(contract.proposalKind(0)).toEqual(ProposalKind.PayoutTon);
    expect(proposal.creator).toEqual(ownerA.address);
    expect(proposal.configVersionAtCreation).toEqual(0);
    expect(proposal.currentConfigVersion).toEqual(0);
    expect(proposal.expiresAt).toEqual(expiresAt);
    expect(proposal.status).toEqual(ProposalViewStatus.Pending);
    expect(proposal.approvalCount).toEqual(1);
    expect(proposal.requiredApprovalCount).toEqual(2);
    expect(contract.proposalRequiredThreshold(0)).toEqual(contract.payoutThreshold());
    expect(proposal.payoutRecipient).toEqual(outsider.address);
    expect(proposal.payoutAmount).toEqual(ton("0.20"));
    expect(proposal.recipient).toEqual(proposal.payoutRecipient);
    expect(proposal.amount).toEqual(proposal.payoutAmount);
    expect(proposal.newOwnerCount).toEqual(0);
    expect(proposal.newPayoutThreshold).toEqual(0);
    expect(proposal.newConfigThreshold).toEqual(0);
    expect(proposal.newFeeReserve).toEqual(0);
    expect(contract.hasApproval(0, ownerA.address)).toBeTrue();
    expect(contract.proposalSeqno()).toEqual(1);
}

get fun `test owner creates config proposal with creator auto approval`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val expiresAt = blockchain.now() + DEFAULT_EXPIRY_SECONDS;
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        expiresAt,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.id).toEqual(0);
    expect(proposal.kind).toEqual(ProposalKind.SetTreasuryConfig);
    expect(contract.proposalKind(0)).toEqual(ProposalKind.SetTreasuryConfig);
    expect(proposal.creator).toEqual(ownerA.address);
    expect(proposal.configVersionAtCreation).toEqual(0);
    expect(proposal.currentConfigVersion).toEqual(0);
    expect(proposal.expiresAt).toEqual(expiresAt);
    expect(proposal.status).toEqual(ProposalViewStatus.Pending);
    expect(proposal.approvalCount).toEqual(1);
    expect(proposal.requiredApprovalCount).toEqual(contract.configThreshold());
    expect(contract.proposalRequiredThreshold(0)).toEqual(contract.configThreshold());
    expect(proposal.newOwnerCount).toEqual(3);
    expect(proposal.newPayoutThreshold).toEqual(2);
    expect(proposal.newConfigThreshold).toEqual(2);
    expect(proposal.newFeeReserve).toEqual(DEFAULT_FEE_RESERVE);
    expect(contract.hasApproval(0, ownerA.address)).toBeTrue();
    expect(contract.proposalSeqno()).toEqual(1);

    expect(contract.ownerCount()).toEqual(2);
    expect(contract.payoutThreshold()).toEqual(2);
    expect(contract.configThreshold()).toEqual(2);
    expect(contract.configVersion()).toEqual(0);
}

get fun `test creator approval is stored in proposal approval mask`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.05"),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(1);
    expect(proposal.approvalMask).toEqual(1);
    expect(contract.hasApproval(0, ownerA.address)).toEqual(true);
}

get fun `test config proposal creator approval is stored in proposal approval mask`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(1);
    expect(proposal.approvalMask).toEqual(1);
    expect(contract.hasApproval(0, ownerA.address)).toEqual(true);
}

get fun `test retained proposal count increments on payout create`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    expect(contract.retainedProposalCount()).toEqual(0);

    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    expect(contract.retainedProposalCount()).toEqual(1);
}

get fun `test retained proposal count increments on config create`() {
    val (contract, ownerA, ownerB, _) = setupTreasuryMutableConfig();
    val newOwners = twoOwners(ownerA, ownerB);
    expect(contract.retainedProposalCount()).toEqual(0);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.retainedProposalCount()).toEqual(1);
}

get fun `test proposal cap blocks payout proposal create`() {
    val (contract, ownerA, _, outsider) = setupTreasuryAtProposalCap(false);

    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalLimitReached,
    });
    expect(contract.retainedProposalCount()).toEqual(MAX_RETAINED_PROPOSALS);
    expect(contract.proposalSeqno()).toEqual(0);
}

get fun `test proposal cap blocks config proposal create`() {
    val (contract, ownerA, ownerB, _) = setupTreasuryAtProposalCap(true);
    val newOwners = twoOwners(ownerA, ownerB);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalLimitReached,
    });
    expect(contract.retainedProposalCount()).toEqual(MAX_RETAINED_PROPOSALS);
    expect(contract.proposalSeqno()).toEqual(0);
}

get fun `test proposal id beyond seqno returns not found status`() {
    val (contract, _, _, _) = setupTreasury();

    val proposal = contract.proposal(0);

    expect(proposal.id).toEqual(0);
    expect(proposal.status).toEqual(ProposalViewStatus.NotFound);
    expect(proposal.approvalCount).toEqual(0);
    expect(proposal.approvalMask).toEqual(0);
    expect(proposal.requiredApprovalCount).toEqual(0);
    expect(proposal.creator).toEqual(zeroAddress());
    expect(proposal.payoutRecipient).toEqual(zeroAddress());
    expect(proposal.payoutAmount).toEqual(0);
}

get fun `test missing proposal below seqno returns pruned status`() {
    val (contract, _, _, _) = setupTreasuryWithMissingProposalBelowSeqno();

    val proposal = contract.proposal(0);

    expect(proposal.id).toEqual(0);
    expect(proposal.status).toEqual(ProposalViewStatus.Pruned);
    expect(proposal.approvalCount).toEqual(0);
    expect(proposal.approvalMask).toEqual(0);
    expect(proposal.requiredApprovalCount).toEqual(0);
    expect(proposal.creator).toEqual(zeroAddress());
    expect(proposal.payoutRecipient).toEqual(zeroAddress());
    expect(proposal.payoutAmount).toEqual(0);
}

get fun `test proposal status getter returns matching not found and pruned status`() {
    val (emptyContract, _, _, _) = setupTreasury();
    val (prunedContract, _, _, _) = setupTreasuryWithMissingProposalBelowSeqno();

    val notFoundStatus = emptyContract.proposalStatus(0);
    val prunedStatus = prunedContract.proposalStatus(0);

    expect(notFoundStatus).toEqual(emptyContract.proposal(0).status);
    expect(prunedStatus).toEqual(prunedContract.proposal(0).status);
}

get fun `test proposal kind getter returns payout kind for payout proposal`() {
    val (contract, ownerA, _, _, outsider) = setupThreeOwnerTreasury(1, 3, true);

    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    expect(contract.proposalKind(0)).toEqual(ProposalKind.PayoutTon);
    expect(contract.hasApproval(0, ownerA.address)).toBeTrue();
}

get fun `test proposal kind getter returns config kind for config proposal`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(1, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        1,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    expect(contract.proposalKind(0)).toEqual(ProposalKind.SetTreasuryConfig);
    expect(contract.hasApproval(0, ownerA.address)).toBeTrue();
}

get fun `test proposal required threshold getter returns payout threshold for payout proposal`() {
    val (contract, ownerA, _, _, outsider) = setupThreeOwnerTreasury(1, 3, true);

    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    expect(contract.proposalRequiredThreshold(0)).toEqual(contract.payoutThreshold());
}

get fun `test proposal required threshold getter returns config threshold for config proposal`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(1, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        1,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    expect(contract.proposalRequiredThreshold(0)).toEqual(contract.configThreshold());
}

get fun `test proposal config owners exposes proposed owner set`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val outsider = testTreasury("proposalConfigOwnersOutsider");
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(res).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val proposalOwners = contract.proposalConfigOwners(0);
    expect(proposalOwners.exists(ownerA.address)).toBeTrue();
    expect(proposalOwners.exists(ownerB.address)).toBeTrue();
    expect(proposalOwners.exists(ownerC.address)).toBeTrue();
    expect(proposalOwners.exists(outsider.address)).toBeFalse();
}

get fun `test config proposal requires current config threshold approvals`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ThresholdNotReached,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Pending);
}

get fun `test config proposal cannot execute with only payout approvals when payout threshold lower`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ThresholdNotReached,
    });
    expect(contract.proposal(0).approvalCount).toEqual(2);
    expect(contract.proposal(0).requiredApprovalCount).toEqual(3);
}

get fun `test config proposal creator auto approval counts for config proposal`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(1, 2, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        1,
        2,
        ton("0.20"),
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.configVersion()).toEqual(1);
    expect(contract.feeReserve()).toEqual(ton("0.20"));
}

get fun `test config threshold decrease requires old current config threshold`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);

    val early = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(early).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ThresholdNotReached,
    });

    approveProposal(contract, ownerC, 0);
    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.configThreshold()).toEqual(2);
}

get fun `test config proposal execution does not require proposed future config threshold`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 2, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.configThreshold()).toEqual(3);
    expect(contract.configVersion()).toEqual(1);
}

get fun `test creator can cancel config proposal while pending`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE });
    expect(res).toHaveSuccessfulTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Cancelled);
}

get fun `test non creator cannot cancel config proposal`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val res = contract.sendCancelProposal(ownerB.address, 0, { value: MIN_CANCEL_VALUE });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.NotCreator,
    });
}

get fun `test executable cancel config proposal is rejected`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 2, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.AlreadyExecutable,
    });
}

get fun `test expired cancel config proposal is rejected`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, true);
    val newOwners = threeOwners(ownerA, ownerB, ownerC);

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + 1,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    testSetNow((blockchain.now() + 2) as uint32);

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalExpired,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Expired);
}

get fun `test stale cancel config proposal is rejected`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    val stale = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        twoOwners(ownerA, ownerB),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(stale).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val executable = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        1,
        2,
        DEFAULT_FEE_RESERVE,
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(executable).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 1);
    executeProposal(contract, ownerA, 1);

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalStale,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Stale);
}

get fun `test execute SetTreasuryConfig updates config and marks stale proposals`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    createProposal(contract, ownerA, ownerC.address, ton("0.20"));

    val oldConfig = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        twoOwners(ownerA, ownerB),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(oldConfig).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val create = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        1,
        2,
        ton("0.20"),
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(create).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 2);

    expect(contract.ownerCount()).toEqual(2);
    expect(contract.payoutThreshold()).toEqual(2);
    expect(contract.configThreshold()).toEqual(2);
    expect(contract.feeReserve()).toEqual(DEFAULT_FEE_RESERVE);
    expect(contract.configVersion()).toEqual(0);
    expect(contract.isOwner(ownerC.address)).toBeFalse();

    val res = contract.sendExecuteProposal(ownerA.address, 2, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    expect(contract.ownerCount()).toEqual(2);
    expect(contract.payoutThreshold()).toEqual(1);
    expect(contract.configThreshold()).toEqual(2);
    expect(contract.feeReserve()).toEqual(ton("0.20"));
    expect(contract.configVersion()).toEqual(1);
    expect(contract.isOwner(ownerA.address)).toBeTrue();
    expect(contract.isOwner(ownerB.address)).toBeFalse();
    expect(contract.isOwner(ownerC.address)).toBeTrue();
    expect(contract.proposal(2).status).toEqual(ProposalViewStatus.Executed);
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Stale);
    expect(contract.proposal(1).status).toEqual(ProposalViewStatus.Stale);

    val secondExecute = contract.sendExecuteProposal(
        ownerA.address,
        2,
        { value: MIN_EXECUTE_VALUE },
    );
    expect(secondExecute).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}

get fun `test removed owner cannot approve new proposals after execution`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    val createConfig = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(createConfig).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);
    executeProposal(contract, ownerA, 0);

    createProposal(contract, ownerA, ownerC.address, ton("0.20"));

    val res = contract.sendApproveProposal(ownerB.address, 1, { value: MIN_APPROVE_VALUE });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.NotOwner,
    });
}

get fun `test added owner can approve new proposals after execution`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    val createConfig = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(createConfig).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 0);
    executeProposal(contract, ownerA, 0);

    createProposal(contract, ownerA, ownerC.address, ton("0.20"));
    approveProposal(contract, ownerC, 1);

    expect(contract.proposal(1).approvalCount).toEqual(2);
    expect(contract.proposal(1).status).toEqual(ProposalViewStatus.Executable);
}

get fun `test config proposal validation rejects non owner`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerC.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerC.address,
        to: contract.address,
        exitCode: Errors.NotOwner,
    });
}

get fun `test config proposal validation rejects duplicate owners`() {
    val (contract, ownerA, ownerB, _) = setupTreasuryMutableConfig();

    var newOwners: map<address, uint8> = [];
    newOwners.set(ownerA.address, OWNER_INDEX_0);
    newOwners.set(ownerB.address, OWNER_INDEX_1);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.DuplicateOwner,
    });
}

get fun `test config proposal validation rejects duplicate owner indexes`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();

    var newOwners: map<address, uint8> = [];
    newOwners.set(ownerA.address, OWNER_INDEX_0);
    newOwners.set(ownerB.address, OWNER_INDEX_1);
    newOwners.set(ownerC.address, OWNER_INDEX_1);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.DuplicateOwner,
    });
}

get fun `test config proposal validation rejects owner index outside owner count`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();

    var newOwners: map<address, uint8> = [];
    newOwners.set(ownerA.address, OWNER_INDEX_0);
    newOwners.set(ownerB.address, OWNER_INDEX_1);
    newOwners.set(ownerC.address, 3);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidOwnerCount,
    });
}

get fun `test config proposal validation rejects owner count below minimum`() {
    val (contract, ownerA, _, _) = setupTreasuryMutableConfig();

    var newOwners: map<address, uint8> = [];
    newOwners.set(ownerA.address, OWNER_INDEX_0);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        MIN_OWNER_COUNT - 1,
        1,
        1,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidOwnerCount,
    });
}

get fun `test config proposal validation rejects owner count above maximum`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        MAX_OWNER_COUNT + 1,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidOwnerCount,
    });
}

get fun `test config proposal validation rejects zero config threshold`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        1,
        0,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test config proposal validation rejects zero proposed payout threshold`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        0,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidPayoutThreshold,
    });
}

get fun `test config proposal validation rejects payout threshold above config threshold`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        3,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test config proposal validation rejects config threshold above new owner count`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        4,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
}

get fun `test deadlock rejects config proposal where newOwnerCount is below locked current configThreshold`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, false);
    val newOwners = twoOwners(ownerA, ownerB);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
    expect(contract.isOwner(ownerC.address)).toBeTrue();
}

get fun `test deadlock rejects config proposal where newConfigThreshold is above newOwnerCount`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwners(ownerA, ownerB);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
    expect(contract.isOwner(ownerC.address)).toBeFalse();
}

get fun `test deadlock rejects owner removal that would make final configThreshold impossible`() {
    val (contract, ownerA, ownerB, ownerC, _) = setupThreeOwnerTreasury(2, 3, false);
    val newOwners = twoOwners(ownerA, ownerB);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidConfigThreshold,
    });
    expect(contract.isOwner(ownerC.address)).toBeTrue();
}

get fun `test config proposal validation rejects fee reserve below minimum`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        MIN_FEE_RESERVE - 1,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidFeeReserve,
    });
}

get fun `test config proposal validation rejects config threshold change when threshold mutable false`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val res = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        3,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ConfigThresholdLocked,
    });
}

get fun `test config proposal validation rejects invalid expiry and minimum value`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasuryMutableConfig();
    val newOwners = twoOwnersPlus(ownerA, ownerB, ownerC);

    val lowValue = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE - 1 },
    );
    expect(lowValue).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InsufficientMessageValue,
    });

    val expired = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now(),
        { value: MIN_CREATE_VALUE },
    );
    expect(expired).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidExpiry,
    });

    val tooFar = contract.sendCreateConfigProposal(
        ownerA.address,
        3,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        newOwners,
        blockchain.now() + MAX_EXPIRY_SECONDS + 100,
        { value: MIN_CREATE_VALUE },
    );
    expect(tooFar).toHaveFailedTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidExpiry,
    });
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
    expect(proposal.kind).toEqual(ProposalKind.PayoutTon);
    expect(proposal.approvalCount).toEqual(2);
    expect(proposal.requiredApprovalCount).toEqual(2);
    expect(proposal.payoutRecipient).toEqual(outsider.address);
    expect(proposal.payoutAmount).toEqual(ton("0.20"));
    expect(proposal.recipient).toEqual(proposal.payoutRecipient);
    expect(proposal.amount).toEqual(proposal.payoutAmount);
    expect(proposal.status).toEqual(ProposalViewStatus.Executable);
    expect(contract.hasApproval(0, ownerB.address)).toBeTrue();
}

get fun `test second owner approval sets second approval bit`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: MIN_APPROVE_VALUE });
    expect(res).toHaveSuccessfulTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
    });

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(2);
    expect(proposal.approvalMask).toEqual(3);
    expect(contract.hasApproval(0, ownerB.address)).toEqual(true);
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

    val proposal = contract.proposal(0);
    expect(proposal.approvalCount).toEqual(1);
    expect(proposal.approvalMask).toEqual(1);
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

get fun `test create proposal rejects insufficient inbound value`() {
    val (contract, ownerA, _, outsider) = setupTreasury();

    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE - 1 },
    );

    expect(res).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InsufficientMessageValue,
    });
}

get fun `test approve proposal rejects insufficient inbound value`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: MIN_APPROVE_VALUE - 1 });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.InsufficientMessageValue,
    });

    expect(contract.proposal(0).approvalCount).toEqual(1);
}

get fun `test cancel proposal rejects insufficient inbound value`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE - 1 });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InsufficientMessageValue,
    });

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Pending);
}

get fun `test execute proposal rejects insufficient inbound value`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE - 1 });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InsufficientMessageValue,
    });

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Executable);
}

get fun `test create proposal rejects expiry beyond maximum`() {
    val (contract, ownerA, _, outsider) = setupTreasury();

    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        blockchain.now() + MAX_EXPIRY_SECONDS + 1,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidExpiry,
    });
}

get fun `test create proposal accepts maximum expiry exactly`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    val expiresAt = blockchain.now() + MAX_EXPIRY_SECONDS;

    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        outsider.address,
        ton("0.20"),
        expiresAt,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expect(contract.proposal(0).expiresAt).toEqual(expiresAt);
}

get fun `test create proposal rejects treasury self recipient`() {
    val (contract, ownerA, _, _) = setupTreasury();

    val res = contract.sendCreatePayoutProposal(
        ownerA.address,
        contract.address,
        ton("0.20"),
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );

    expect(res).toHaveFailedTx<CreatePayoutProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.InvalidRecipient,
    });
}

get fun `test unknown non empty body is rejected`() {
    val (contract, _, _, outsider) = setupTreasury();
    val unknownBody = beginCell().storeUint(0xFFFFFFFF, 32).endCell();

    val res = contract.sendAny(outsider.address, unknownBody, { value: ton("0.30") });
    expect(res).toHaveFailedTx({
        from: outsider.address,
        to: contract.address,
        exitCode: Errors.InvalidMessage,
    });
}

get fun `test executed proposal cannot be approved`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);
    executeProposal(contract, ownerA, 0);

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: MIN_APPROVE_VALUE });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}

get fun `test cancelled proposal cannot be approved`() {
    val (contract, ownerA, ownerB, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));
    val cancel = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE });
    expect(cancel).toHaveSuccessfulTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: MIN_APPROVE_VALUE });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}

get fun `test cancelled proposal cannot be executed`() {
    val (contract, ownerA, _, outsider) = setupTreasury();
    createProposal(contract, ownerA, outsider.address, ton("0.20"));
    val cancel = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE });
    expect(cancel).toHaveSuccessfulTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
    });

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalNotPending,
    });
}

get fun `test execute payout action phase succeeds`() {
    val (contract, ownerA, ownerB, recipient) = setupTreasury();
    createProposal(contract, ownerA, recipient.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    expectSuccessfulPayoutActionPhase(res);
    expect(res).toHaveTx({
        from: contract.address,
        to: recipient.address,
        value: ton("0.20"),
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Executed);
}

get fun `test stale proposal cannot be approved`() {
    val (contract, _, ownerB, _) = setupTreasuryWithSeededProposal(
        ProposalStatus.Pending,
        1,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
    );

    val res = contract.sendApproveProposal(ownerB.address, 0, { value: MIN_APPROVE_VALUE });
    expect(res).toHaveFailedTx<ApproveProposal>({
        from: ownerB.address,
        to: contract.address,
        exitCode: Errors.ProposalStale,
    });
    expect(contract.proposal(0).approvalCount).toEqual(1);
    expect(contract.proposal(0).approvalMask).toEqual(1);
}

get fun `test stale proposal keeps approval mask after owner set changes`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    createProposal(contract, ownerA, ownerB.address, ton("0.20"));
    expect(contract.proposal(0).approvalMask).toEqual(1);

    val createConfig = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(createConfig).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 1);
    executeProposal(contract, ownerA, 1);

    val oldProposal = contract.proposal(0);
    expect(oldProposal.status).toEqual(ProposalViewStatus.Stale);
    expect(oldProposal.approvalCount).toEqual(1);
    expect(oldProposal.approvalMask).toEqual(1);

    val approval = contract.sendApproveProposal(ownerC.address, 0, { value: MIN_APPROVE_VALUE });
    expect(approval).toHaveFailedTx<ApproveProposal>({
        from: ownerC.address,
        to: contract.address,
        exitCode: Errors.ProposalStale,
    });

    val execute = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(execute).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalStale,
    });
}

get fun `test has approval is false for stale proposal after owner index reuse`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    createProposal(contract, ownerA, ownerB.address, ton("0.20"));
    approveProposal(contract, ownerB, 0);
    expect(contract.proposal(0).approvalMask).toEqual(3);

    val createConfig = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(createConfig).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 1);
    executeProposal(contract, ownerA, 1);

    val oldProposal = contract.proposal(0);
    expect(oldProposal.status).toEqual(ProposalViewStatus.Stale);
    expect(oldProposal.approvalMask).toEqual(3);
    expect(contract.hasApproval(0, ownerB.address)).toBeFalse();
    expect(contract.hasApproval(0, ownerC.address)).toBeFalse();
}

get fun `test new proposal after config change uses new owner approval bits`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    createProposal(contract, ownerA, ownerB.address, ton("0.20"));

    val createConfig = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(createConfig).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 1);
    executeProposal(contract, ownerA, 1);

    createProposal(contract, ownerA, ownerB.address, ton("0.20"));
    approveProposal(contract, ownerC, 2);

    val newProposal = contract.proposal(2);
    expect(newProposal.configVersionAtCreation).toEqual(1);
    expect(newProposal.approvalCount).toEqual(2);
    expect(newProposal.approvalMask).toEqual(3);
    expect(contract.hasApproval(2, ownerC.address)).toBeTrue();
}

get fun `test stale proposal cannot be executed`() {
    val (contract, ownerA, _, _) = setupTreasuryWithSeededProposal(
        ProposalStatus.Pending,
        2,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
    );

    val res = contract.sendExecuteProposal(ownerA.address, 0, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveFailedTx<ExecuteProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalStale,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Stale);
}

get fun `test stale proposal cannot be cancelled`() {
    val (contract, ownerA, _, _) = setupTreasuryWithSeededProposal(
        ProposalStatus.Pending,
        1,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
    );

    val res = contract.sendCancelProposal(ownerA.address, 0, { value: MIN_CANCEL_VALUE });
    expect(res).toHaveFailedTx<CancelProposal>({
        from: ownerA.address,
        to: contract.address,
        exitCode: Errors.ProposalStale,
    });
    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Stale);
}

get fun `test stale view status has priority over expired and executable pending proposal`() {
    val (contract, _, _, _) = setupTreasuryWithSeededProposal(
        ProposalStatus.Pending,
        2,
        blockchain.now() - 1,
    );

    val proposal = contract.proposal(0);
    expect(proposal.status).toEqual(ProposalViewStatus.Stale);
    expect(proposal.approvalCount).toEqual(2);
    expect(proposal.requiredApprovalCount).toEqual(2);
}

get fun `test stale status is derived from config version mismatch`() {
    val (contract, ownerA, ownerB, ownerC) = setupTreasury();
    val replacementOwners = twoOwners(ownerA, ownerC);

    createProposal(contract, ownerA, ownerB.address, ton("0.20"));
    val oldProposalBeforeConfig = contract.proposal(0);
    expect(oldProposalBeforeConfig.configVersionAtCreation).toEqual(0);
    expect(oldProposalBeforeConfig.status).toEqual(ProposalViewStatus.Pending);

    val createConfig = contract.sendCreateConfigProposal(
        ownerA.address,
        2,
        2,
        2,
        DEFAULT_FEE_RESERVE,
        replacementOwners,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(createConfig).toHaveSuccessfulTx<CreateConfigProposal>({
        from: ownerA.address,
        to: contract.address,
    });
    approveProposal(contract, ownerB, 1);
    executeProposal(contract, ownerA, 1);

    val oldProposalAfterConfig = contract.proposal(0);
    expect(contract.configVersion()).toEqual(1);
    expect(oldProposalAfterConfig.configVersionAtCreation).toEqual(0);
    expect(oldProposalAfterConfig.currentConfigVersion).toEqual(1);
    expect(oldProposalAfterConfig.status).toEqual(ProposalViewStatus.Stale);

    createProposal(contract, ownerA, ownerB.address, ton("0.20"));
    approveProposal(contract, ownerC, 2);

    val newProposal = contract.proposal(2);
    expect(newProposal.configVersionAtCreation).toEqual(1);
    expect(newProposal.currentConfigVersion).toEqual(1);
    expect(newProposal.approvalCount).toEqual(2);
    expect(newProposal.requiredApprovalCount).toEqual(2);
    expect(newProposal.status).toEqual(ProposalViewStatus.Executable);
}

get fun `test executed proposal remains executed even if stale`() {
    val (contract, _, _, _) = setupTreasuryWithSeededProposal(
        ProposalStatus.Executed,
        2,
        blockchain.now() - 1,
    );

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Executed);
}

get fun `test cancelled proposal remains cancelled even if stale`() {
    val (contract, _, _, _) = setupTreasuryWithSeededProposal(
        ProposalStatus.Cancelled,
        1,
        blockchain.now() - 1,
    );

    expect(contract.proposal(0).status).toEqual(ProposalViewStatus.Cancelled);
}

fun setupTreasury(): (Treasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("ownerA");
    val ownerB = testTreasury("ownerB");
    val outsider = testTreasury("outsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, outsider);
}

fun setupTreasuryMutableConfig(): (Treasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("mutableOwnerA");
    val ownerB = testTreasury("mutableOwnerB");
    val outsider = testTreasury("mutableOutsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: true,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, outsider);
}

fun setupThreeOwnerTreasury(
    payoutThreshold: uint8,
    configThreshold: uint8,
    mutable: bool,
): (Treasury, TestTreasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("threeOwnerA");
    val ownerB = testTreasury("threeOwnerB");
    val ownerC = testTreasury("threeOwnerC");
    val outsider = testTreasury("threeOwnerOutsider");

    val owners = threeOwners(ownerA, ownerB, ownerC);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 3,
        payoutThreshold,
        configThreshold,
        configThresholdMutable: mutable,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, ownerC, outsider);
}

fun setupTreasuryAtProposalCap(
    mutable: bool,
): (Treasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("capOwnerA");
    val ownerB = testTreasury("capOwnerB");
    val outsider = testTreasury("capOutsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: mutable,
        configVersion: 0,
        proposalSeqno: 0,
        retainedProposalCount: MAX_RETAINED_PROPOSALS,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, outsider);
}

fun setupTreasuryWithMissingProposalBelowSeqno(): (
    Treasury,
    TestTreasury,
    TestTreasury,
    TestTreasury,
) {
    val ownerA = testTreasury("missingBelowSeqnoOwnerA");
    val ownerB = testTreasury("missingBelowSeqnoOwnerB");
    val outsider = testTreasury("missingBelowSeqnoOutsider");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 0,
        proposalSeqno: 1,
        retainedProposalCount: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, outsider);
}

fun twoOwners(ownerA: TestTreasury, ownerB: TestTreasury): map<address, uint8> {
    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);
    return owners;
}

fun threeOwners(
    ownerA: TestTreasury,
    ownerB: TestTreasury,
    ownerC: TestTreasury,
): map<address, uint8> {
    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);
    owners.set(ownerC.address, OWNER_INDEX_2);
    return owners;
}

fun twoOwnersPlus(
    ownerA: TestTreasury,
    ownerB: TestTreasury,
    ownerC: TestTreasury,
): map<address, uint8> {
    return threeOwners(ownerA, ownerB, ownerC);
}

fun setupTreasuryWithSeededProposal(
    status: ProposalStatus,
    approvalCount: uint8,
    expiresAt: uint32,
): (Treasury, TestTreasury, TestTreasury, TestTreasury) {
    val ownerA = testTreasury("seededOwnerA");
    val ownerB = testTreasury("seededOwnerB");
    val recipient = testTreasury("seededRecipient");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val proposal = Proposal {
        id: 0,
        kind: ProposalKind.PayoutTon,
        creator: ownerA.address,
        createdAt: blockchain.now() as uint32,
        expiresAt,
        configVersionAtCreation: 0,
        status,
        approvalCount,
        approvalMask: seededApprovalMask(approvalCount),
        payload: PayoutTonPayload {
            recipient: recipient.address,
            amount: ton("0.20"),
        },
    };

    var proposals: map<uint64, Cell<Proposal>> = [];
    proposals.set(0, proposal.toCell());

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 2,
        payoutThreshold: 2,
        configThreshold: 2,
        configThresholdMutable: false,
        configVersion: 1,
        proposalSeqno: 1,
        retainedProposalCount: 1,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals,
    });

    val res = contract.deploy(ownerA.address, { value: ton("1.00") });
    expect(res).toHaveSuccessfulDeploy({ to: contract.address });

    return (contract, ownerA, ownerB, recipient);
}

fun seededApprovalMask(approvalCount: uint8): uint16 {
    var mask: uint16 = 0;
    if (approvalCount >= 1) {
        mask = mask | ((1 as uint16) << OWNER_INDEX_0);
    }
    if (approvalCount >= 2) {
        mask = mask | ((1 as uint16) << OWNER_INDEX_1);
    }
    return mask;
}

fun createProposal(contract: Treasury, creator: TestTreasury, recipient: address, amount: coins) {
    val res = contract.sendCreatePayoutProposal(
        creator.address,
        recipient,
        amount,
        blockchain.now() + DEFAULT_EXPIRY_SECONDS,
        { value: MIN_CREATE_VALUE },
    );
    expect(res).toHaveSuccessfulTx<CreatePayoutProposal>({
        from: creator.address,
        to: contract.address,
    });
}

fun approveProposal(contract: Treasury, owner: TestTreasury, proposalId: uint64) {
    val res = contract.sendApproveProposal(owner.address, proposalId, { value: MIN_APPROVE_VALUE });
    expect(res).toHaveSuccessfulTx<ApproveProposal>({
        from: owner.address,
        to: contract.address,
    });
}

fun executeProposal(contract: Treasury, owner: TestTreasury, proposalId: uint64) {
    val res = contract.sendExecuteProposal(owner.address, proposalId, { value: MIN_EXECUTE_VALUE });
    expect(res).toHaveSuccessfulTx<ExecuteProposal>({
        from: owner.address,
        to: contract.address,
    });
}

fun expectSuccessfulPayoutActionPhase(res: SendResultList) {
    val rootTx = res.at(0).tx.load();
    val descr = rootTx.description.load();
    if (descr is TlbTransOrd) {
        val actionCell = descr.action.unwrapOr(null);
        assert (actionCell != null) throw 998;
        val action = actionCell!.load();
        expect(action.success).toBeTrue();
        expect(action.valid).toBeTrue();
        expect(action.resultCode).toEqual(0);
        expect(action.msgsCreated).toEqual(1);
    } else {
        throw 999;
    }
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
