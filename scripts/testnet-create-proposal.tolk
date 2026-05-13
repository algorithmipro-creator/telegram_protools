import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")

fun main() {
    val ownerA = scripts.wallet("ownera");
    val recipient = scripts.wallet("recipient");
    val expiresAt = blockchain.now() + DEFAULT_EXPIRY_SECONDS;

    val createProposalMessage = createMessage({
        bounce: true,
        value: ton("0.05"),
        dest: TREASURY_ADDRESS,
        body: CreatePayoutProposal {
            recipient: recipient.address,
            amount: ton("0.05"),
            expiresAt,
        },
    });
    val res = net.send(ownerA.address, createProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("Create proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(TREASURY_ADDRESS, "proposal", [0]);
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("RECIPIENT_ADDRESS={}", recipient.address);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
    println("PAYOUT_AMOUNT={:ton}", proposal.amount);
}
