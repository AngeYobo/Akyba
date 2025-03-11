---------------------------- MODULE Akyba ----------------------------
EXTENDS Integers, Sequences, FiniteSets, Apalache

(* -- Type Annotations for Apalache -- *)
VARIABLES
  \* @type: Set(Str);
  ParticipantsActifs,
  \* @type: Str -> Int;
  Cautions,
  \* @type: Seq(<<Str, Int>>);
  FileAttente,
  \* @type: Int;
  PotCommun,
  \* @type: Seq(<<Int, Int, Str, Int>>);
  OrdreTirage,
  \* @type: Int;
  Tour,
  \* @type: Int;
  Cycle,
  \* @type: Seq(Bool);
  Choix

CONSTANTS
  \* @type: Int;
  NombreCycles,
  \* @type: Set(Str);
  Participants,
  \* @type: Int;
  MontantContribution

(* ✅ Define `Str` explicitly *)
Str == {"Alice", "Bob", "Charlie", "Dave"}

MAX(a, b) == IF a > b THEN a ELSE b

(* ✅ Non-recursive SetToSeq definition *)
SetToSeq(S) ==
    CHOOSE seq \in [1..Cardinality(S) -> S] :
        /\ \A i, j \in 1..Cardinality(S) : i # j => seq[i] # seq[j]
        /\ \A x \in S : \E i \in 1..Cardinality(S) : seq[i] = x

(* ✅ Initial Setup Constants *)
CautionInitiale == 3 * MontantContribution
NombreToursParCycle == 6

(* ✅ Constant Initialization (`CInit`) for Apalache *)
CInit ==
    /\ NombreCycles = 1000
    /\ Participants = {"Alice", "Bob", "Charlie", "Dave"}
    /\ MontantContribution = 100000

(* ✅ Properly formatted `Init` *)
Init ==
    /\ ParticipantsActifs = Participants
    /\ Cautions = [p \in Participants |-> CautionInitiale]
    /\ FileAttente = <<>>
    /\ PotCommun = 0
    /\ OrdreTirage = <<>>
    /\ Tour = 1
    /\ Cycle = 1
    /\ Choix = <<TRUE, FALSE, TRUE, FALSE, TRUE>>

(* ✅ Contribution des participants *)
Contribuer ==
    /\ PotCommun' = PotCommun + Cardinality(ParticipantsActifs) * MontantContribution
    /\ Cautions' = [p \in ParticipantsActifs |->
                      IF Choix[Tour] THEN
                          IF Cautions[p] >= MontantContribution THEN
                              Cautions[p] - MontantContribution
                          ELSE
                              Cautions[p]  (* No deduction if insufficient funds *)
                      ELSE
                          Cautions[p]
                   ]
    /\ UNCHANGED <<FileAttente, OrdreTirage, Tour, Cycle, Choix, ParticipantsActifs>>

(* ✅ Simplified Selectionner *)
Selectionner ==
    /\ ParticipantsActifs /= {}
    /\ FileAttente' = Append(FileAttente, <<CHOOSE p \in ParticipantsActifs : TRUE, Tour>>)
    /\ UNCHANGED <<ParticipantsActifs, PotCommun, Cautions, OrdreTirage, Tour, Cycle, Choix>>

(* ✅ Fixing nested `LET` expressions in `Attribuer` *)
Attribuer ==
    /\ Len(FileAttente) > 0
    /\ LET head == Head(FileAttente)
       p == head[1]
       tourSelection == head[2]
       IN
           IF tourSelection + 3 <= Tour THEN
               /\ OrdreTirage' = Append(OrdreTirage, <<Cycle, Tour, p, PotCommun>>)
               /\ FileAttente' = Tail(FileAttente)
               /\ PotCommun' = 0
               /\ UNCHANGED <<ParticipantsActifs, Cautions, Tour, Cycle, Choix>>
           ELSE
               /\ UNCHANGED <<OrdreTirage, FileAttente, PotCommun, ParticipantsActifs, Cautions, Tour, Cycle, Choix>>

VerifierCautions ==
    /\ ParticipantsActifs' = { p \in ParticipantsActifs : Cautions[p] >= 0 }
    /\ Cautions' = [p \in Participants |-> MAX(0, Cautions[p])]
    /\ UNCHANGED <<FileAttente, PotCommun, OrdreTirage, Cycle, Choix, Tour>>

(* ✅ Passer au tour suivant *)
PasserAuTourSuivant ==
    /\ Tour' = IF Tour < NombreToursParCycle THEN Tour + 1 ELSE 1
    /\ Cycle' = IF Tour = NombreToursParCycle THEN Cycle + 1 ELSE Cycle
    /\ UNCHANGED <<ParticipantsActifs, Cautions, FileAttente, PotCommun, OrdreTirage, Choix>>

(* ✅ Fairness as an Invariant *)
\* Fairness : Tous les participants reçoivent le pot au moins une fois par cycle
Fairness == \A p \in Participants : \E i \in DOMAIN OrdreTirage : OrdreTirage[i][3] = p

LiveInvariant ==
    \E t \in {Contribuer, Selectionner, Attribuer, VerifierCautions, PasserAuTourSuivant} : t



(* ✅ Ensure caution does not go negative *)
CautionNonNegative ==
    \A p \in Participants:
        IF p \in DOMAIN Cautions THEN Cautions[p] >= 0 ELSE TRUE

(* ✅ Updated `Next` transitions *)
Next ==
    \/ Contribuer
    \/ Selectionner
    \/ Attribuer
    \/ VerifierCautions
    \/ PasserAuTourSuivant


(* ✅ Updated `Spec` with `CInit` for Apalache *)
Spec ==
    CInit /\ Init /\ [][Next]_<<ParticipantsActifs, Cautions, FileAttente, PotCommun, OrdreTirage, Tour, Cycle, Choix>>
    /\ Fairness
    /\ CautionNonNegative

=============================================================================
