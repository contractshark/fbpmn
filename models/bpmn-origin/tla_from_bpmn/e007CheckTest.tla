---------------- MODULE e007CheckTest ----------------

EXTENDS TLC, PWSTypes

VARIABLES nodemarks, edgemarks, net

ContainRel ==
  "Process_1" :> { "Task_097548f", "Task_1eirt50", "ExclusiveGateway_0079typ", "EndEvent_0v9lt5i", "Task_1rt44mz", "ExclusiveGateway_1j1chqb", "StartEvent_1" }

Node == {
  "Process_1","Task_097548f","Task_1eirt50","ExclusiveGateway_0079typ","EndEvent_0v9lt5i","Task_1rt44mz","ExclusiveGateway_1j1chqb","StartEvent_1"
}

Edge == {
  "SequenceFlow_0uplc1a","SequenceFlow_01wc4ks","SequenceFlow_0wto9d1","SequenceFlow_0b7efwa","SequenceFlow_1fuwd1z","SequenceFlow_0uzla8o","SequenceFlow_0z2xwql"
}

Message == {  }

msgtype ==
    [ i \in {} |-> {}]

source ==
   "SequenceFlow_0uplc1a" :> "ExclusiveGateway_1j1chqb"
@@ "SequenceFlow_01wc4ks" :> "Task_097548f"
@@ "SequenceFlow_0wto9d1" :> "ExclusiveGateway_1j1chqb"
@@ "SequenceFlow_0b7efwa" :> "Task_1eirt50"
@@ "SequenceFlow_1fuwd1z" :> "ExclusiveGateway_0079typ"
@@ "SequenceFlow_0uzla8o" :> "Task_1rt44mz"
@@ "SequenceFlow_0z2xwql" :> "StartEvent_1"

target ==
   "SequenceFlow_0uplc1a" :> "Task_097548f"
@@ "SequenceFlow_01wc4ks" :> "ExclusiveGateway_0079typ"
@@ "SequenceFlow_0wto9d1" :> "Task_1eirt50"
@@ "SequenceFlow_0b7efwa" :> "ExclusiveGateway_0079typ"
@@ "SequenceFlow_1fuwd1z" :> "Task_1rt44mz"
@@ "SequenceFlow_0uzla8o" :> "EndEvent_0v9lt5i"
@@ "SequenceFlow_0z2xwql" :> "ExclusiveGateway_1j1chqb"

CatN ==
   "Process_1" :> Process
@@ "Task_097548f" :> AbstractTask
@@ "Task_1eirt50" :> AbstractTask
@@ "ExclusiveGateway_0079typ" :> ExclusiveOr
@@ "EndEvent_0v9lt5i" :> NoneEndEvent
@@ "Task_1rt44mz" :> AbstractTask
@@ "ExclusiveGateway_1j1chqb" :> Parallel
@@ "StartEvent_1" :> NoneStartEvent

CatE ==
   "SequenceFlow_0uplc1a" :> NormalSeqFlow
@@ "SequenceFlow_01wc4ks" :> NormalSeqFlow
@@ "SequenceFlow_0wto9d1" :> NormalSeqFlow
@@ "SequenceFlow_0b7efwa" :> NormalSeqFlow
@@ "SequenceFlow_1fuwd1z" :> NormalSeqFlow
@@ "SequenceFlow_0uzla8o" :> NormalSeqFlow
@@ "SequenceFlow_0z2xwql" :> NormalSeqFlow

LOCAL preEdges ==
  [ i \in {} |-> {}]
PreEdges(n,e) == preEdges[n,e]

PreNodes(n,e) == { target[ee] : ee \in preEdges[n,e] }
          \union { nn \in { source[ee] : ee \in preEdges[n,e] } : CatN[nn] \in { NoneStartEvent, MessageStartEvent } }

WF == INSTANCE PWSWellFormed
ASSUME WF!WellFormedness

INSTANCE PWSSemantics

================================================================
