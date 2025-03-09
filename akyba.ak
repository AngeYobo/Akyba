use aiken/builtin.{b_data, constr_data, integer_to_bytearray, list_data}
use aiken/collection/dict.{Dict}
use aiken/collection/list
use aiken/crypto.{ VerificationKeyHash}
use aiken/primitive/bytearray
use cardano/assets
use cardano/transaction.{
   Input, Output, OutputReference, Transaction,
}

// Define the custom Datum type
pub type Datum {
  participants: List<VerificationKeyHash>,
  // List of participants' public key hashes
  round: Int,
}

// Define the TontineRedeemer type with variants
pub type TontineRedeemer {
  Contribute
  Redeem { winner_index: Int }
}

// Function to convert VerificationKeyHash list to Data
pub fn datum_to_data(datum: Datum) -> Data {
  let participant_data = datum.participants |> list.map(b_data)

  // trace @"participant_data:"
  // trace cbor.diagnostic(participant_data)
  // Convert the round integer to a byte array (big-endian, no size limit)
  let round_data = integer_to_bytearray(True, 0, datum.round)

  // trace @"round_data:"
  // trace cbor.diagnostic(round_data)
  constr_data(0, [list_data(participant_data), b_data(round_data)])
}

// Helper function to verify if a participant is among the signatories
fn verify_signer(
  participant: VerificationKeyHash,
  signatories: List<VerificationKeyHash>,
) -> Bool {
  list.any(signatories, fn(signer) { signer == participant })
}


/// USING Short-circuit Evaluation here using two separate checks (valid_keys and unique_keys)
/// Validate that all participants have the correct length and are unique
fn validate_user_keys(participants: List<VerificationKeyHash>) -> Bool {
  if !list.is_empty(participants) {
    let result =
      list.foldl(
        participants,
        Some(dict.empty),
        fn(key_hash, acc: Option<Dict<VerificationKeyHash, Bool>>) -> Option<
          Dict<VerificationKeyHash, Bool>,
        > {
          let expected_length = 28
          let key_length = bytearray.length(key_hash)

          when acc is {
            None -> None
            // If previous entries were invalid, continue returning None
            Some(acc_dict) ->
              if key_length != expected_length || dict.has_key(
                acc_dict,
                key_hash,
              ) {
                None
              } else {
                // Return None if the key is invalid or duplicated
                Some(dict.insert(acc_dict, key_hash, True))
              }
          }
        },
      )
    result != None
  } else {
    False
  }
}

fn validate_utxo_consistency(
  own_ref: OutputReference,
  self_tx: Transaction,
) -> Bool {
  // Find the relevant inputs using the `own_ref`
  let relevant_inputs =
    list.filter(self_tx.inputs, fn(input) { input.output_reference == own_ref })

  // Calculate the total lovelace from all relevant inputs
  let total_input_lovelace =
    relevant_inputs
      |> list.foldl(
          0,
          fn(input, acc) { acc + assets.lovelace_of(input.output.value) },
        )

  //trace @"total_input_lovelace"
  //trace cbor.diagnostic(total_input_lovelace)

  // Check the output going to the winner
  when list.head(self_tx.outputs) is {
    Some(winner_output) -> {
      let winner_output_lovelace = assets.lovelace_of(winner_output.value)
      //trace @"winner_output_lovelace"
     // trace cbor.diagnostic(winner_output_lovelace)

      if total_input_lovelace == winner_output_lovelace {
        True
      } else {
        trace @"ERROR: Total lovelace mismatch between inputs and output."
        False
      }
    }
    None -> {
      trace @"ERROR: No output found in the transaction."
      False
    }
  }
}

// Validator logic with single spend purpose handling both contribute and redeem
validator tontine {
  spend(
    datum: Option<Datum>,
    redeemer: TontineRedeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    when datum is {
      Some(d) -> {
        //trace @"DATUM"
        //trace cbor.diagnostic(d)
        let valid_user_keys = validate_user_keys(d.participants)
        let valid_round = d.round >= 0

        // Check for valid user keys and round number
        if !valid_user_keys {
          trace @"ERROR: Invalid participant key detected."
          False
        } else if !valid_round {
          trace @"ERROR: Round number is invalid."
          False
        } else if !validate_utxo_consistency(own_ref, self) {
          // Reuse the UTXO consistency check function
          False
        } else {
          when redeemer is {
            Contribute -> {
             // trace @"REDEEMER"
             // trace cbor.diagnostic(redeemer)
              trace @"Contribution validated successfully."
              True
            }
            Redeem { winner_index } -> {
             // trace @"WINNER"
              //trace cbor.diagnostic(winner_index)
              let selected_winner = list.at(d.participants, winner_index)
              when selected_winner is {
                None -> {
                  trace @"ERROR: Invalid winner index."
                  False
                }
                Some(participant) -> {
                  let is_signer =
                    verify_signer(participant, self.extra_signatories)
                  if !is_signer {
                    trace @"ERROR: Missing signature of the winner."
                    False
                  } else {
                    trace @"Winner verified."
                    True
                  }
                }
              }
            }
          }
        }
      }
      None -> fail @"ERROR: Missing Datum."
    }
  }

  else(_) {
    fail @"ERROR: Invalid validator usage."
  }
}

