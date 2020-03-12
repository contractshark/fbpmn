/*
Deux process avec :
NSE -> ST -> TSE
NSE -> RT -> TSE
*/


open PWSSyntax
open PWSProp

one sig hello extends MessageKind {}
one sig m extends Message {} {
    from = proc1
    to = proc2
    content = hello
}

one sig st1 extends SendTask {}
one sig rt2 extends ReceiveTask {}
one sig se1 extends NoneStartEvent {}
one sig se2 extends NoneStartEvent {}
one sig ee1 extends NoneEndEvent {}
one sig ee2 extends NoneEndEvent {}

one sig f1 extends SequentialFlow {} {
    source = se1
    target = st1
}
one sig f2 extends SequentialFlow {} {
    source = st1
    target = ee1
}
one sig f3 extends SequentialFlow {} {
    source = se2
    target = rt2
}
one sig f4 extends SequentialFlow {} {
    source = rt2
    target = ee2
}
one sig mf extends MessageFlow {} {
    source = st1
    target = rt2
    message = m
}

one sig proc1 extends Process {} {
    contains = se1 + st1 + ee1
}

one sig proc2 extends Process {} {
    contains = se2 + rt2 + ee2
}

check {Safe} for 0 but 15 State

check {SimpleTermination} for 0 but 9 State
check {CorrectTermination} for 0 but 9 State

run {Safe} for 0 but 11 State
