open example6 as m
open PWSSemantics
open PWSProp

check {Safe} for 0 but 10 State

check {SimpleTermination} for 0 but 10 State
check {CorrectTermination} for 0 but 10 State
check {EmptyNetTermination} for 0 but 20 State

run {Safe} for 0 but 11 State
