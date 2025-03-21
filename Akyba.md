#**Akyba: A Formal Tontine Model**

## **1. Introduction**
Tontine is a financial mechanism where a group of participants contribute a fixed amount at regular intervals, and the pooled funds are distributed to members based on a defined set of rules. 

This document presents a **TLA+ specification** of the **Akyba** tontine model, ensuring formal verification and correctness.

This model is particularly useful for implementing **decentralized community savings** on the **blockchain**, guaranteeing transparency and fairness.

## **2. System Variables and Constants**

| **Variable / Constant**   | **Type** | **Description** |
|--------------------------|---------|----------------|
| `ParticipantsActifs`     | Set(Str) | Active participants who have not been eliminated. |
| `Cautions`              | Str → Int | A mapping of each participant to their remaining caution balance. |
| `FileAttente`           | Seq(<<Str, Int>>) | A queue that tracks participants waiting to receive the pot. |
| `PotCommun`             | Int | The total amount of ADA pooled together in the current cycle. |
| `OrdreTirage`          | Seq(<<Int, Int, Str, Int>>) | The history of winners, their cycles, and rewards. |
| `Tour`                  | Int | The current round of contributions within a cycle. |
| `Cycle`                 | Int | The current cycle of the tontine. |
| `Choix`                 | Seq(Bool) | A predefined sequence of decisions for whether participants contribute. |
| `NombreCycles`          | Int | The total number of cycles before the tontine ends. |
| `Participants`          | Set(Str) | The full set of all initial participants. |
| `MontantContribution`   | Int | The fixed contribution amount per participant per round. |

## **3. Mathematical Rules and Formulas**

### **3.1 Initial Conditions**
- **Caution Guarantee Fund**:
  \[
  CautionInitiale = 3 \times MontantContribution
  \]
  Each participant starts with a caution balance of three times their per-round contribution.

- **Total Rounds per Cycle**:
  \[
  NombreToursParCycle = 6
  \]
  This specifies that a cycle consists of 6 rounds.

### **3.2 Contribution Function**
#### **Mathematical Model**
The total contribution per round:
\[
PotCommun' = PotCommun + |ParticipantsActifs| \times MontantContribution
\]

Each participant’s caution update rule:
\[
Cautions'[p] =
\begin{cases}
  Cautions[p] - MontantContribution, & \text{if Choix}[Tour] \text{ and } Cautions[p] \geq MontantContribution \\
  Cautions[p], & \text{otherwise}
\end{cases}
\]
- If the participant chooses to contribute and has enough funds, the balance decreases.
- If the participant does not contribute, the caution remains unchanged.

### **3.3 Eliminating Participants**
#### **Mathematical Model**
Participant elimination condition:
\[
ParticipantsActifs' = \{ p \in ParticipantsActifs \ | \ Cautions[p] \geq 0 \}
\]
- If a participant’s caution becomes negative, they are removed from `ParticipantsActifs`.

Caution cannot be negative:
\[
Cautions'[p] = \max(0, Cautions[p])
\]
- Even if caution goes below 0, we force it back to zero.

### **3.4 Selecting the Next Recipient**
#### **Mathematical Model**
\[
FileAttente' = FileAttente + (p, Tour) \text{ where } p \in ParticipantsActifs
\]
- A randomly selected participant is appended to the waiting list.

### **3.5 Prize Distribution**
If the participant has been waiting for 3 rounds, they receive the pot:
\[
OrdreTirage' = OrdreTirage + (Cycle, Tour, p, PotCommun)
\]
- The prize is recorded.
- The `PotCommun` is reset to `0`.

### **3.6 Advancing to the Next Round**
#### **Mathematical Model**
If the current round is not the last in the cycle:
\[
Tour' = Tour + 1
\]
If the current round is the last, move to the next cycle:
\[
Cycle' = Cycle + 1
\]

### **3.7 Ensuring Fairness**
\[
\forall p \in Participants, \exists i : OrdreTirage[i][3] = p
\]
- This guarantees that every participant wins at least once.

## **4. Blockchain Smart Contract Alignment**
This formal model aligns well with **Plutus** and **Aiken**, as it ensures:
- **Decentralized enforcement** of tontine rules.
- **Guaranteed fairness and non-negative balances.**
- **Efficient implementation of smart contracts.**

## **5. Benefits for Regulatory Compliance**
- Helps **prove fairness** and **fund security.**
- Useful for **audits and DeFi smart contract security analysis.**
- Can be **translated into Solidity, Plutus, or Aiken** logic.

## **6. Next Steps**
To enhance this research:
1. **Generate a visualization** of how cycles, rounds, and eliminations work.
2. **Simulate test cases** using Apalache and provide more performance benchmarks.
3. **Optimize smart contract execution** for minimal gas costs and execution time.

---
This document serves as a foundation for **trustless tontine contracts** on the blockchain. Future iterations will integrate these formulas into **real-world implementations using Cardano, Ethereum, and Solana.**

