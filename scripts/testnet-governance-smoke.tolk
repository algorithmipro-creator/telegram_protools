import "@acton/build"
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

fun waitForObservedTx(res: SendResultList) {
    assert (res.waitForTrace(false, 60, 3000) != null) throw Errors.InvalidMessage;
}

fun main() {
    val ownerA = scripts.wallet("ownera");
    val ownerB = scripts.wallet("ownerb");
    val recipient = scripts.wallet("recipient");

    var owners: map<address, uint8> = [];
    owners.set(ownerA.address, OWNER_INDEX_0);
    owners.set(ownerB.address, OWNER_INDEX_1);

    val ownerCount: uint8 = 2;
    val payoutThreshold: uint8 = 2;
    val configThreshold: uint8 = 2;
    val nextFeeReserve = ton("0.12");
    val expiresAt = blockchain.now() + DEFAULT_EXPIRY_SECONDS;

    val stateInit = ContractState {
        code: build("Treasury"),
        data: Storage {
            ownerCount,
            payoutThreshold,
            configThreshold,
            configThresholdMutable: false,
            configVersion: 0,
            proposalSeqno: 0,
            retainedProposalCount: 0,
            feeReserve: DEFAULT_FEE_RESERVE,
            owners,
            proposals: [],
        }.toCell(),
    };
    val treasuryAddress = AutoDeployAddress { stateInit }.calculateAddress();

    println("TREASURY_ADDRESS={}", treasuryAddress);
    println("SMOKE_STEP=deploy");
    waitForObservedTx(
        net.send(
            ownerA.address,
            createMessage({
                bounce: false,
                value: ton("0.30"),
                dest: { stateInit },
            }),
        ),
    );

    val deployedOwnerCount: uint8 = net.runGetMethod(treasuryAddress, "owner_count");
    val deployedPayoutThreshold: uint8 = net.runGetMethod(treasuryAddress, "payout_threshold");
    val deployedConfigThreshold: uint8 = net.runGetMethod(treasuryAddress, "config_threshold");
    val deployedConfigVersion: uint32 = net.runGetMethod(treasuryAddress, "config_version");

    assert (deployedOwnerCount == ownerCount) throw Errors.InvalidMessage;
    assert (deployedPayoutThreshold == payoutThreshold) throw Errors.InvalidMessage;
    assert (deployedConfigThreshold == configThreshold) throw Errors.InvalidMessage;
    assert (deployedConfigVersion == 0) throw Errors.InvalidMessage;

    println("SMOKE_STEP=create_payout_proposal");
    waitForObservedTx(
        net.send(
            ownerA.address,
            createMessage({
                bounce: true,
                value: ton("0.05"),
                dest: treasuryAddress,
                body: CreatePayoutProposal {
                    recipient: recipient.address,
                    amount: ton("0.02"),
                    expiresAt,
                },
            }),
        ),
    );

    val payoutBeforeConfig: ProposalView = net.runGetMethod(treasuryAddress, "proposal", [0]);
    assert (payoutBeforeConfig.kind == ProposalKind.PayoutTon) throw Errors.InvalidMessage;
    assert (payoutBeforeConfig.status == ProposalViewStatus.Pending) throw Errors.InvalidMessage;
    assert (payoutBeforeConfig.approvalCount == 1) throw Errors.InvalidMessage;
    assert (
        payoutBeforeConfig.requiredApprovalCount == payoutThreshold
    ) throw Errors.InvalidMessage;

    println("SMOKE_STEP=create_config_proposal");
    waitForObservedTx(
        net.send(
            ownerA.address,
            createMessage({
                bounce: true,
                value: ton("0.05"),
                dest: treasuryAddress,
                body: CreateConfigProposal {
                    newOwnerCount: ownerCount,
                    newPayoutThreshold: payoutThreshold,
                    newConfigThreshold: configThreshold,
                    newFeeReserve: nextFeeReserve,
                    newOwners: owners,
                    expiresAt,
                },
            }),
        ),
    );

    val configBeforeApprove: ProposalView = net.runGetMethod(treasuryAddress, "proposal", [1]);
    assert (configBeforeApprove.kind == ProposalKind.SetTreasuryConfig) throw Errors.InvalidMessage;
    assert (configBeforeApprove.status == ProposalViewStatus.Pending) throw Errors.InvalidMessage;
    assert (configBeforeApprove.approvalCount == 1) throw Errors.InvalidMessage;
    assert (
        configBeforeApprove.requiredApprovalCount == configThreshold
    ) throw Errors.InvalidMessage;

    println("SMOKE_STEP=approve_config_proposal");
    waitForObservedTx(
        net.send(
            ownerB.address,
            createMessage({
                bounce: true,
                value: ton("0.05"),
                dest: treasuryAddress,
                body: ApproveProposal { proposalId: 1 },
            }),
        ),
    );

    val configAfterApprove: ProposalView = net.runGetMethod(treasuryAddress, "proposal", [1]);
    assert (configAfterApprove.status == ProposalViewStatus.Executable) throw Errors.InvalidMessage;
    assert (configAfterApprove.approvalCount == 2) throw Errors.InvalidMessage;

    println("SMOKE_STEP=execute_config_proposal");
    waitForObservedTx(
        net.send(
            ownerA.address,
            createMessage({
                bounce: true,
                value: ton("0.05"),
                dest: treasuryAddress,
                body: ExecuteProposal { proposalId: 1 },
            }),
        ),
    );

    val configAfterExecute: ProposalView = net.runGetMethod(treasuryAddress, "proposal", [1]);
    val payoutAfterConfig: ProposalView = net.runGetMethod(treasuryAddress, "proposal", [0]);
    val finalConfigVersion: uint32 = net.runGetMethod(treasuryAddress, "config_version");
    val finalFeeReserve: coins = net.runGetMethod(treasuryAddress, "fee_reserve");
    val finalProposalSeqno: uint64 = net.runGetMethod(treasuryAddress, "proposal_seqno");

    assert (configAfterExecute.status == ProposalViewStatus.Executed) throw Errors.InvalidMessage;
    assert (payoutAfterConfig.status == ProposalViewStatus.Stale) throw Errors.InvalidMessage;
    assert (finalConfigVersion == 1) throw Errors.InvalidMessage;
    assert (finalFeeReserve == nextFeeReserve) throw Errors.InvalidMessage;
    assert (finalProposalSeqno == 2) throw Errors.InvalidMessage;

    println("SMOKE_RESULT=PASS");
    println("PAYOUT_PROPOSAL_ID=0");
    println("PAYOUT_STATUS_AFTER_CONFIG={}", payoutAfterConfig.status);
    println("CONFIG_PROPOSAL_ID=1");
    println("CONFIG_STATUS_AFTER_EXECUTE={}", configAfterExecute.status);
    println("CONFIG_VERSION={}", finalConfigVersion);
    println("PROPOSAL_SEQNO={}", finalProposalSeqno);
    println("FEE_RESERVE={:ton}", finalFeeReserve);
}
