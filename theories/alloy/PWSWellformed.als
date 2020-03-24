module PWSWellformed

open PWSSyntax

/* Well-formed conditions */

pred MessageDifferentProcesses {
    all m : MessageFlow | !(m.source.processOf = m.target.processOf)
}

/* to be continued */

assert WellFormed {
    MessageDifferentProcesses
    //...
}
