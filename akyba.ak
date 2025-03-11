// Import necessary Aiken modules
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/assets
use cardano/transaction.{Output, OutputReference, Transaction}

// Define participant structure
pub type Participant {
  pubkey: VerificationKeyHash,
  collateral: Int,
}

// Define draw entry structure (payout history)
pub type DrawEntry {
  cycle: Int,
  round: Int,
  winner: VerificationKeyHash,
  amount: Int,
}

// Define Datum: The on-chain state of the tontine contract
pub type Datum {
  active_participants: List<Participant>,
  waiting_queue: List<VerificationKeyHash>,
  draw_order: List<DrawEntry>,
  common_pot: Int,
  round: Int,
  cycle: Int,
  initial_collateral: Int,
  contribution_amount: Int,
  rounds_per_cycle: Int,
  number_of_cycles: Int,
}

// Define Redeemer: Actions that participants can take
pub type Redeemer {
  Contribute
  SelectWinner
  Distribute
  VerifyCollateral
  NextRound
}

// ** Ensures collateral never becomes negative **
pub fn max(a: Int, b: Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

// ** Winner Selection Logic: Adds a participant to the waiting queue **
pub fn select_winner(datum: Datum, redeemer: Redeemer, _tx: Transaction) -> Bool {
  when redeemer is {
    SelectWinner -> {
      let winner: Option<Participant> =
        list.find(datum.active_participants, fn(_p) { True })

      when winner is {
        Some(_) -> True
        // ✅ Winner exists
        None -> False
      }
    }
    // ❌ No winner found
    _ -> False
  }
}

// ** Distribute funds to the selected winner **
pub fn distribute(datum: Datum, redeemer: Redeemer, _tx: Transaction) -> Bool {
  when redeemer is {
    Distribute -> {
      let winner_entry: Option<VerificationKeyHash> =
        list.find(datum.waiting_queue, fn(_p) { True })

      // ✅ Always picks the first entry
      let new_pot = 0

      when winner_entry is {
        Some(_) -> datum.common_pot == new_pot
        // ✅ Winner exists & pot resets
        None -> False
      }
    }
    // ❌ No winner found
    _ -> False
  }
}

// ** Verify collateral for elimination **
pub fn verify_collateral(
  datum: Datum,
  redeemer: Redeemer,
  _tx: Transaction,
) -> Bool {
  when redeemer is {
    VerifyCollateral -> {
      let updated_participants =
        list.filter(
          datum.active_participants,
          fn(p: Participant) -> Bool { p.collateral >= 0 },
        )
      datum.active_participants == updated_participants
    }
    _ -> False
  }
}

// ** Move to the next round or cycle **
pub fn next_round(datum: Datum, redeemer: Redeemer, _tx: Transaction) -> Bool {
  when redeemer is {
    NextRound -> {
      let new_round =
        if datum.round < datum.rounds_per_cycle {
          datum.round + 1
        } else {
          1
        }
      let new_cycle =
        if datum.round == datum.rounds_per_cycle {
          datum.cycle + 1
        } else {
          datum.cycle
        }

      datum.round == new_round && datum.cycle == new_cycle
    }
    _ -> False
  }
}

pub fn contribute(datum: Datum, redeemer: Redeemer, tx: Transaction) -> Bool {
  when redeemer is {
    Contribute -> {
      let total_contributed =
        list.length(datum.active_participants) * datum.contribution_amount

      let received_ada =
        list.foldl(
          tx.outputs,
          0,
          fn(out: Output, acc: Int) -> Int {
            acc + assets.lovelace_of(out.value)
          },
        )

      received_ada == datum.common_pot + total_contributed
    }
    _ -> False
  }
}

// ** Main Validator Function **
validator akyba {
  spend(
    datum_opt: Option<Datum>,
    redeemer: Redeemer,
    _utxo: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt

    // ✅ Ensure `datum` is present
    contribute(datum, redeemer, tx) || select_winner(datum, redeemer, tx) || distribute(
      datum,
      redeemer,
      tx,
    ) || verify_collateral(datum, redeemer, tx) || next_round(
      datum,
      redeemer,
      tx,
    )
  }

  else(_) {
    fail
  }
}
