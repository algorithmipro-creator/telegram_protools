import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const BASELINE_PROPOSAL_ID: uint64 = 1
const BASELINE_PAYOUT_AMOUNT: coins = ton("0.02")
const BASELINE_MESSAGE_VALUE: coins = ton("0.05")

fun main() {
    val ownerA = scripts.wallet("ownera");
    val recipient = scripts.wallet("recipient");
    val expiresAt = blockchain.now() + DEFAULT_EXPIRY_SECONDS;

    val proposalSeqno: uint64 = net.runGetMethod(TREASURY_ADDRESS, "proposal_seqno");
    if (proposalSeqno != BASELINE_PROPOSAL_ID) {
        println("GAS_BASELINE_ACTION=create");
        println(
            "GAS_BASELINE_ERROR=Expected proposal_seqno {} before create, got {}",
            BASELINE_PROPOSAL_ID,
            proposalSeqno,
        );
        return;
    }

    val createProposalMessage = createMessage({
        bounce: true,
        value: BASELINE_MESSAGE_VALUE,
        dest: TREASURY_ADDRESS,
        body: CreatePayoutProposal {
            recipient: recipient.address,
            amount: BASELINE_PAYOUT_AMOUNT,
            expiresAt,
        },
    });
    val res = net.send(ownerA.address, createProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("GAS_BASELINE_ACTION=create");
        println("GAS_BASELINE_ERROR=Create proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(
        TREASURY_ADDRESS,
        "proposal",
        [BASELINE_PROPOSAL_ID],
    );
    println("GAS_BASELINE_ACTION=create");
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("OWNER_ADDRESS={}", ownerA.address);
    println("RECIPIENT_ADDRESS={}", recipient.address);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
    println("PAYOUT_AMOUNT={:ton}", proposal.amount);
    println("MESSAGE_VALUE={:ton}", BASELINE_MESSAGE_VALUE);
}
