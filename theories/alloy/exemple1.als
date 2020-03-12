/*
Un process avec :
NSE -> AT -> TSE
*/


open PWSSyntax
open PWSProp

one sig m extends MessageKind {}

one sig at extends AbstractTask {}
one sig se extends NoneStartEvent {}
one sig ee extends NoneEndEvent {}

one sig f1 extends SequentialFlow {} {
    source = se
    target = at
}
one sig f2 extends SequentialFlow {} {
    source = at
    target = ee
}

one sig p1 extends Process {} {
    contains = se + at + ee
}

check {Safe} for 0 but 10 State

check {SimpleTermination} for 0 but 5 State
check {CorrectTermination} for 0 but 5 State

run {Safe} for 0 but 10 State


