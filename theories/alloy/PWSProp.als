module PWSProp

open PWSDefs
open PWSSyntax
open PWSSemantics

/* Each process (individually) reaches an end state. */
pred SimpleTermination {
    all p : Process | some s: State, n : EndEvent | n in p.contains && s.nodemarks[n] >= 1
}

/* Note the inversion all proc / some state : there is a state where all processes have correctly terminated. */
pred CorrectTermination {
    some s : State | all p : Process | some n: EndEvent {
       n in p.contains && s.nodemarks[n] >= 1
       all nn : p.^contains - n | s.nodemarks[nn] = 0
       all e : Edge | e.source = p && e.target = p => s.edgemarks[e] = 0
       }
}

/* CorrectTermination as above and the network is empty. */
pred EmptyNetTermination {
    some s : State {
        all p : Process | some n: EndEvent {
            n in p.contains && s.nodemarks[n] >= 1
            all nn : p.contains - n | s.nodemarks[nn] = 0
            all e : Edge | e.source = p && e.target = p => s.edgemarks[e] = 0
        }
        all e : MessageFlow | s.edgemarks[e] = 0
    }
}

pred Safe {
    all s: State, n : Node | s.nodemarks[n] <= 1
    all s: State, e : Edge | s.edgemarks[e] <= 1
}