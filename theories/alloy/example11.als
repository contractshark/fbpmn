/*
NSE -> AT(TBE -> NEE) -> NEE
*/
module example10

open PWSSyntax
open PWSSemantics

one sig hello extends Message {}

one sig se1 extends NoneStartEvent {}
one sig at1 extends AbstractTask {}
one sig tbe1date extends Date {} {
    date = 4
}
one sig tbe1 extends TimerBoundaryEvent {} {
    attachedTo = at1
    interrupting = True
    mode = tbe1date
}
one sig ee1a extends NoneEndEvent {}
one sig ee1b extends NoneEndEvent {}

one sig f1 extends NormalSequentialFlow {} {
    source = se1
    target = at1
}
one sig f2 extends NormalSequentialFlow {} {
    source = at1
    target = ee1a
}
one sig f3 extends NormalSequentialFlow {} {
    source = tbe1
    target = ee1b
}

one sig proc1 extends Process {} {
    contains = se1 + at1 + tbe1 + ee1a + ee1b
}
