# VeluxeToken (VLX)

VeluxeToken (VLX) is the governance-ready ERC20 token powering the Veluxe ecosystem.  
It is designed with **security, transparency, and decentralization** at its core, combining OpenZeppelin v5 standards with custom role-based controls, pause logic, and rescue mechanisms.

---

## 🔹 Overview
- **Name / Symbol:** Veluxe / VLX  
- **Supply:** 100,000,000,000 VLX (100B) preminted at deployment  
- **Decimals:** 18  
- **Standards:** ERC20, ERC20Burnable, ERC20Votes, ERC20Permit  
- **Focus:** Transparent governance, fair distribution, and audit-grade security

VLX is minted in full to an **admin contract** (Timelock or multisig Safe) at genesis.  
From there, distribution flows into vesting vaults, emissions schedules, and treasury allocations, all under community oversight.

---

## ✨ Features
- **Premint to Admin Wallet:** Entire 100B supply minted at deployment to a contract-controlled treasury.
- **Immutable Cap:** Hard-coded maximum supply; no inflation beyond 100B VLX.
- **Governance-Ready:**  
  - ERC20Votes for delegation and on-chain voting.  
  - ERC20Permit for gasless approvals via signatures.  
- **Role-Based Access Control:**  
  - `DEFAULT_ADMIN_ROLE` → TimelockController (DAO governance).  
  - `MINTER_ROLE` → EmissionsDistributor (minting under schedule).  
  - `PAUSER_ROLE` → Guardian Safe (emergency pause only).  
  - `PARAMS_ROLE` → Timelock (manage rescue lists).  
  - `OPERATOR_ROLE` → Operations Proxy (rescue logic).  
- **Pause Logic:** Transfers and minting can be paused/unpaused by PAUSER_ROLE.  
- **Rescue Mechanism:** Whitelist/blacklist system for recovering ETH/ERC20 tokens mistakenly sent to the contract.  
- **Security-First:** Explicit event emission, nonces override for inheritance resolution, reentrancy guards.

---

## 🚀 Deployment Notes
1. **Compile & Deploy:**  
   - Use Solidity `^0.8.20` with OpenZeppelin v5.  
   - Deploy `VeluxeToken` with the **admin contract address** (Timelock or Safe).  
   - Constructor premints full supply to the admin wallet.

2. **Admin Contract Requirements:**  
   - Must be a contract (not an EOA).  
   - Recommended: **TimelockController** or **Gnosis Safe**.  
   - Admin receives all roles at deployment.

3. **Post-Deployment Setup:**  
   - Transfer roles to appropriate governance contracts:
     - Timelock → DEFAULT_ADMIN_ROLE, PARAMS_ROLE, OPERATOR_ROLE.  
     - Guardian Safe → PAUSER_ROLE.  
     - EmissionsDistributor → MINTER_ROLE.  
   - Seed vesting vaults and treasury allocations from the preminted supply.

---

## 🏛 Governance Model
VeluxeToken is designed for **progressive decentralization**:

- **TimelockController:**  
  - Holds all admin powers with enforced delay (48–96h).  
  - Ensures transparency and reaction time for community.

- **Governor (ERC20Votes):**  
  - Token-weighted proposals and voting.  
  - Executes decisions via Timelock.

- **Guardian Safe:**  
  - Limited to PAUSER_ROLE.  
  - Can pause/unpause transfers in emergencies.  
  - No minting or parameter control.

- **EmissionsDistributor:**  
  - Controlled by Timelock.  
  - Mints tokens gradually under schedule, respecting MAX_SUPPLY.

- **VestingVaults:**  
  - Handle team, community, and treasury allocations.  
  - Enforce cliffs and linear vesting.  
  - Claims are transparent and event-driven.

- **Operations Proxy:**  
  - Holds OPERATOR_ROLE for rescue logic.  
  - All actions routed through Timelock proposals.

---

## 📜 License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
# deluxe-token
