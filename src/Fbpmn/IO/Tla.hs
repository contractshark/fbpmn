{-# LANGUAGE QuasiQuotes #-}
module Fbpmn.IO.Tla where

import qualified Data.Text         as T
import           Fbpmn.Model
import           NeatInterpolation (text)
-- import           Data.List                      ( intercalate )
import           Data.Map.Strict   ((!?))

{-|
Write a BPMN Graph to a TLA+ file.
-}
writeToTLA :: FilePath -> BpmnGraph -> IO ()
writeToTLA p = writeFile p . encodeBpmnGraphToTla

{-|
Transform a BPMN Graph to a TLA specification.
-}
encodeBpmnGraphToTla :: BpmnGraph -> Text
encodeBpmnGraphToTla g =
  unlines
    $   [ encodeBpmnGraphHeaderToTla
        , encodeBpmnGraphProcessDeclToTla
        , encodeBpmnGraphContainRelToTla
        , encodeBpmnGraphNodeDeclToTla
        , encodeBpmnGraphFlowDeclToTla
        , encodeBpmnGraphMsgDeclToTla
        , encodeBpmnGraphCatNToTla
        , encodeBpmnGraphCatEToTla
        , encodeBpmnGraphFooterToTla
        ]
    <*> [g]

encodeBpmnGraphHeaderToTla :: BpmnGraph -> Text
encodeBpmnGraphHeaderToTla g =
  [text|---------------- MODULE $n ----------------

  EXTENDS TLC, PWSTypes

  VARIABLES nodemarks, edgemarks, net

  var == <<nodemarks, edgemarks, net>>
  |]
  where
    n = name g

encodeBpmnGraphFooterToTla :: BpmnGraph -> Text
encodeBpmnGraphFooterToTla _ = unlines
  [ ""
  , "WF == INSTANCE PWSWellFormed"
  , "ASSUME WF!WellFormedness"
  , ""
  , "INSTANCE PWSSemantics"
  , ""
  , "Spec == Init /\\ [][Next]_var /\\ WF_var(Next)"
  , ""
  , "================================================================"
  ]

-- TODO: extend with multiple processes
encodeBpmnGraphProcessDeclToTla :: BpmnGraph -> Text
encodeBpmnGraphProcessDeclToTla _ = "TopProcess == { \"" <> "Process" <> "\" }"

encodeBpmnGraphContainRelToTla :: BpmnGraph -> Text
encodeBpmnGraphContainRelToTla _ = unlines []

encodeBpmnGraphNodeDeclToTla :: BpmnGraph -> Text
encodeBpmnGraphNodeDeclToTla _ = unlines []

encodeBpmnGraphFlowDeclToTla :: BpmnGraph -> Text
encodeBpmnGraphFlowDeclToTla g = unlines
  [ encodeBpmnGraphFlowDeclToTla' "NormalSeqFlowEdge" sequenceFlows g
  , encodeBpmnGraphFlowDeclToTla' "MsgFlowEdge"       messageFlows  g
  , "Edge == NormalSeqFlowEdge \\union MsgFlowEdge"
  ]

encodeBpmnGraphFlowDeclToTla' :: Text
                              -> (BpmnGraph -> [Edge])
                              -> BpmnGraph
                              -> Text
encodeBpmnGraphFlowDeclToTla' k flowFilter g = [text|$k == {$fs}|]
 where
  fs = T.intercalate "," flowDecls
  flowDecls = flowToSeqFlowDeclaration <$> flowFilter g
  flowToSeqFlowDeclaration e =
    case
        do
          sourceNode <- sourceE g !? e
          targetNode <- targetE g !? e
          pure (sourceNode, targetNode)
      of
        Nothing      -> ""
        Just (n, m) -> let
                          n' = show n
                          m' = show m in [text|  <<$n', $m'>>|]

encodeBpmnGraphMsgDeclToTla :: BpmnGraph -> Text
encodeBpmnGraphMsgDeclToTla _ = unlines []

encodeBpmnGraphCatNToTla :: BpmnGraph -> Text
encodeBpmnGraphCatNToTla g = 
  [text|CatN ==
    $ns|]
 where
  ns = T.intercalate "@@ " (nodeToNodeCatDecl <$> nodes g)
  nodeToNodeCatDecl n = case catN g !? n of
    Nothing -> ""
    Just c  -> [text|$n' :> $c'|] 
      where
        c' = toTLA c
        n' = show n

encodeBpmnGraphCatEToTla :: BpmnGraph -> Text
encodeBpmnGraphCatEToTla _ =
  [text|CatE == [ e \in Edge |->
                    IF e \in NormalSeqFlowEdge THEN NormalSeqFlow
                    ELSE MsgFlow
                ]|]

toTLA :: NodeType -> Text
toTLA AbstractTask   = "AbstractTask"
toTLA SendTask       = "SendTask"
toTLA ReceiveTask    = "ReceiveTask"
toTLA SubProcess     = "SubProcess"
toTLA XorGateway     = "ExclusiveOr"
toTLA OrGateway      = "InclusiveOr"
toTLA AndGateway     = "Parallel"
toTLA NoneStartEvent = "StartEvent"
toTLA NoneEndEvent   = "EndEvent"
