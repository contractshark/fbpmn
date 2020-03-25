open example10 as m
open PWSProp
open PWSSemantics
open PWSWellformed

check {Safe} for 0 but 10 State

check {SimpleTermination} for 0 but 8 State
check {CorrectTermination} for 0 but 8 State

run {Safe} for 0 but 5 Int, 16 State

/* All end event nodes are reachable. */
run { some s: State | s.nodemarks[ee1a] = 1  } for 0 but 5 State
run { some s: State | s.nodemarks[ee1b] = 1 } for 0 but 7 State

check WellFormed for 1
