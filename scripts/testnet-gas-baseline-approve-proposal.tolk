import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

const TREASURY_ADDRESS: address = address("kQAEswTqc4bDarhACzMsgMhOXOgYcYHaXLLnwwOnMepqhSnA")
const BASELINE_PROPOSAL_ID: uint64 = 1
const BASELINE_MESSAGE_VALUE: coins = ton("0.05")

fun main() {
    val ownerB = scripts.wallet("ownerb");

    val approveProposalMessage = createMessage({
        bounce: true,
        value: BASELINE_MESSAGE_VALUE,
        dest: TREASURY_ADDRESS,
        body: ApproveProposal { proposalId: BASELINE_PROPOSAL_ID },
    });
    val res = net.send(ownerB.address, approveProposalMessage);
    if (res.waitForFirstTransaction() == null) {
        println("GAS_BASELINE_ACTION=approve");
        println("GAS_BASELINE_ERROR=Approve proposal transaction was not observed");
        return;
    }

    val proposal: ProposalView = net.runGetMethod(TREASURY_ADDRESS, "proposal", [BASELINE_PROPOSAL_ID]);
    println("GAS_BASELINE_ACTION=approve");
    println("TREASURY_ADDRESS={}", TREASURY_ADDRESS);
    println("OWNER_ADDRESS={}", ownerB.address);
    println("PROPOSAL_ID={}", proposal.id);
    println("PROPOSAL_STATUS={}", proposal.status);
    println("APPROVAL_COUNT={}", proposal.approvalCount);
    println("MESSAGE_VALUE={:ton}", BASELINE_MESSAGE_VALUE);
}
