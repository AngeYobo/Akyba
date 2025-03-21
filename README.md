# Akyba: Reinventing Community Savings on the Cardano Blockchain

## Abstract
Akyba reinvents the traditional tontine by integrating smart contracts, DeFi, and NFTs on the Cardano blockchain. With CIP-68 NFTs, Merkle Patricia Forests (MPF), and state tokens (STT), Akyba ensures transparent, trustless, and yield-generating community savings. It is designed to eliminate trust issues, fraud, and stagnation in traditional tontines by replacing manual operations with fully automated, secure, and auditable smart contract logic.

---

## The Problem with Traditional Tontines
Tontines are collective savings systems where members contribute to a common pool. However, they suffer from:

- **Trust Dependency**: Managed by a central organizer, vulnerable to mismanagement or fraud.
- **Lack of Transparency**: Participants cannot trace contributions or payouts.
- **No Growth**: Contributions are only redistributed, offering no yield.

Despite these limitations, the community aspect of tontines remains valuable. The challenge is to modernize this structure while preserving its core benefits.

---

## Akyba: Formal Specification and Verification
### Formal Verification and Mathematical Soundness
##### Motivation
---
To ensure the security, fairness, and correctness of the Akyba tontine system, we have formally specified
its behaviors using Temporal Logic of Actions (TLA+), a formal specification language developed by
Leslie Lamport for reasoning about distributed systems.
---
## TLA+ Specification Overview
### The Akyba TLA+ model captures:
• Active participants and their balances (Collateral)
• A queue of candidates awaiting selection (FileAttente)
• A shared savings pool (Total_Pool_Funds)
• A distribution log (OrdreTirage) capturing winner, amount, and cycle
• Cycle management through Tour and Cycle
• Contribution decisions represented by a sequence of booleans (Choix)
### Key Invariants and Properties
We validated the following invariants to ensure protocol resilience:
Fairness: Every participant receives the community fund at least once per cycle:
∀p ∈ Participants, ∃i ∈ DOMAIN(OrdreTirage) : OrdreTirage[i]3 = p
###Non-Negative Collateral: No participant’s balance (Collateral) can fall below zero:
∀p ∈ Participants : Collateral[p] ≥ 0
Liveness: The system always makes progress:
∃t ∈ {Contribuer, Selectionner, Attribuer, VerifierCollateral, PasserAuTourSuivant}
### Model Checking Results
Using the Apalache model checker, the system was verified to:
• Respect fairness constraints for all participants
• Guarantee that no participant’s balance drops below zero
• Ensure continuous operation (liveness) for at least 20 transitions
• Validate state transitions with a computation depth of 20 in under 7 minutes
2

This formal specification confirms that the Akyba protocol:
• Prevents fraudulent manipulations
• Ensures fair distribution across all participants
• Maintains system correctness under all expected behaviors
Strengthen confidence in Akyba implementation and show the advantage of formally verified decentralized
protocols.
3


## The Akyba Architecture

### ✅ Smart Contracts
- Developed in **Aiken**, enabling high performance and deterministic outcomes.
- Manage pool creation, participant contributions, winner selection, and fund distribution.

### ✅ Merkle Patricia Forestry (MPF)
- Off-chain authenticated key/value trie structure.
- Used to efficiently validate participant membership on-chain with **compact proofs**.

![image](https://github.com/user-attachments/assets/f4cf796d-2abf-4c77-b554-e2e3262a2579)


### ✅ CIP-68 NFTs
- Issued to every participant on joining a tontine.
- Metadata tracks:
  - Contribution details
  - Participation round
  - Status (active, withdrawn, winner)
- Enables composability and upgrades with reference scripts.

### ✅ State Tokens (STT)
- Unique token representing the state of a tontine instance.
- Used to track round progression and verify validator UTxOs.
- Ensures continuity and avoids double claims or race conditions.

### ✅ Off-Chain Engine
- Written in TypeScript using **Lucid Evolution** and **MPF SDK**.
- Responsibilities:
  - Generating Merkle proofs
  - Updating NFT metadata
  - Constructing and signing transactions
  - Interacting with the CIP-68 registry

---

## How Akyba Works

### -> Contribution Phase
- Participants lock ADA into the tontine contract.
- CIP-68 NFT and Merkle proof are generated.
- On-chain validator checks proof against MPF root.

### 📈 Investment Phase
- DAO selects staking, lending, or yield farming strategies.
- Funds generate interest throughout the round.

### 🎁 Distribution Phase
- At cycle completion or round intervals, a winner is selected (e.g., randomly or by rotation).
- Validator verifies eligibility, and funds are unlocked.
- CIP-68 metadata and STT reflect updated state.

### ⚖️ Conflict Resolution
- Any disputes are handled via on-chain DAO voting.
- DAO rules ensure transparency and fairness in conflict resolution.

---

## Supported Tontine Models

### Accumulation Tontine (ASCA)
- Funds pooled and invested. Yield + principal redistributed at end.

### Rotative Tontine (ROSCA)
- Periodic fund disbursements per round.
- Pool remains partially staked during the cycle.
##### Akyba Rosca type Overview
![image](https://github.com/user-attachments/assets/86fe6e23-7924-4372-8fd2-821f5d911e4d)



### Variable Contribution
- Members can contribute different amounts.
- Rewards proportional to total contributed.

### Solidarity Tontine
- Portion allocated for member emergencies.

### Auction-Based Tontine
- Early access granted to highest bidder.
- Boosts pool yield and fund allocation efficiency.

---

## DAO-Driven Governance
Participants control pool evolution through the Akyba DAO.

### Governance Tokens
- Distributed to participants based on contribution volume.
- Used to vote on proposals, e.g.:
  - Rule changes
  - Investment strategy
  - Round delays
  - Emergency withdrawals

### Voting Mechanism
- All proposals and voting logic is executed via Plutus V3 smart contracts.

---

## Why Cardano?
- **Low Fees**: Ideal for small contributions and frequent transactions.
- **Security**: UTXO-based model offers high auditability.
- **CIP Standards**: CIP-68, CIP-25, and reference scripts unlock powerful NFT interactions.
- **Community Alignment**: Cardano’s mission aligns with financial inclusion goals.

---

## Conclusion
Akyba blends the tradition of community savings with modern blockchain innovation. With decentralized trust, passive income, and programmable NFT tracking, Akyba makes tontines transparent, scalable, and financially rewarding. Join the revolution to transform community savings into a tool for empowerment, resilience, and long-term wealth.

> Reinvent your future. Reinvent savings. Join Akyba.

