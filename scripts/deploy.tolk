import "@acton/io"
import "@acton/emulation/network"
import "@acton/emulation/scripts"

import "@contracts/types"
import "@wrappers/Treasury.gen"

fun main() {
    val deployer = scripts.wallet("deployer");

    var owners: map<address, uint8> = [];
    owners.set(deployer.address, OWNER_KEY_VALUE);

    val contract = Treasury.fromStorage(Storage {
        ownerCount: 1,
        threshold: 1,
        proposalSeqno: 0,
        feeReserve: DEFAULT_FEE_RESERVE,
        owners,
        proposals: [],
        approvals: [],
    });
    val res = contract.deploy(deployer.address, { value: ton("1.00") });
    if (res.waitForFirstTransaction() == null) {
        return;
    }

    println("Deployed Treasury contract to {}", contract.address);
    println("Threshold is {} of {}", contract.threshold(), contract.ownerCount());
}
