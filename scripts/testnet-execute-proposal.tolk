import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const PROPOSAL_ID: uint64 = 0

fun main() {
    val ownerA = scripts.wallet("ownera");

    val executeProposalMessage = createMessage({
        bounce: true,
        value: ton("0.05"),
        dest: TREASURY_ADDRESS,
        body: ExecuteProposal { proposalId: PROPOSAL_ID },
    });
    val res = net.send(ownerA.address, executeProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("Execute proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(TREASURY_ADDRESS, "proposal", [PROPOSAL_ID]);
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
}
