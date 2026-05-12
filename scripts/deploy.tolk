import "@acton/build"
import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"

fun main() {
    val deployer = scripts.wallet("deployer");

    var owners: map<address, uint8> = [];
    owners.set(deployer.address, OWNER_KEY_VALUE);

    val ownerCount: uint8 = 1;
    val threshold: uint8 = 1;
    val stateInit = ContractState {
        code: build("Treasury"),
        data: Storage {
            ownerCount,
            threshold,
            proposalSeqno: 0,
            feeReserve: DEFAULT_FEE_RESERVE,
            owners,
            proposals: [],
            approvals: [],
        }.toCell(),
    };
    val address = AutoDeployAddress { stateInit }.calculateAddress();
    val deployMsg = createMessage({
        bounce: false,
        value: ton("1.00"),
        dest: { stateInit },
    });

    val res = net.send(deployer.address, deployMsg);
    if (res.waitForFirstTransaction() == null) {
        return;
    }

    println("Deployed Treasury contract to {}", address);
    println("Threshold is {} of {}", threshold, ownerCount);
}
