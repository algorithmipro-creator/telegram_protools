import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const PROPOSAL_ID: uint64 = 0

fun main() {
    val ownerB = scripts.wallet("ownerb");

    val approveProposalMessage = createMessage({
        bounce: true,
        value: ton("0.05"),
        dest: TREASURY_ADDRESS,
        body: ApproveProposal { proposalId: PROPOSAL_ID },
    });
    val res = net.send(ownerB.address, approveProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("Approve proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(TREASURY_ADDRESS, "proposal", [PROPOSAL_ID]);
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
}
