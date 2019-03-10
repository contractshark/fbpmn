module Fbpmn.Model where

import           Data.Aeson                     ( FromJSON
                                                , ToJSON
                                                )
-- import           Data.Monoid                    ( All(..) )
-- import           Data.Maybe                     ( isNothing )
-- import           GHC.Generics
import qualified Data.Set                      as S
                                                ( fromList )
import qualified Data.Map.Strict               as M
                                                ( empty )
import           Data.Map.Strict                ( Map
                                                , (!?)
                                                , keys
                                                , assocs
                                                )
import           Fbpmn.Helper                   ( filter' )

--
-- Node types
--
data NodeType = AbstractTask
              | SendTask
              | ReceiveTask
              | ThrowMessageIntermediateEvent
              | CatchMessageIntermediateEvent
              | SubProcess
              | XorGateway
              | OrGateway
              | AndGateway
              | EventBasedGateway
              | NoneStartEvent
              | MessageStartEvent
              | NoneEndEvent
              | TerminateEndEvent
              | MessageEndEvent
              | Process -- for top-level processes
  deriving (Eq, Show, Generic)
instance ToJSON NodeType
instance FromJSON NodeType

isTask :: NodeType -> Bool
isTask n = n `elem` [AbstractTask, SendTask, ReceiveTask]

isTaskN :: BpmnGraph -> Node -> Maybe Bool
isTaskN g = isInGraph g catN isTask

isInGraph :: (Ord a)
          => BpmnGraph
          -> (BpmnGraph -> Map a b)
          -> (b -> Bool)
          -> a
          -> Maybe Bool
isInGraph g f p x = p <$> f g !? x

--
-- Edge types
--
data EdgeType = NormalSequenceFlow
              | ConditionalSequenceFlow
              | DefaultSequenceFlow
              | MessageFlow
  deriving (Eq, Show, Generic)
instance ToJSON EdgeType
instance FromJSON EdgeType

sequenceFlow :: [EdgeType]
sequenceFlow =
  [NormalSequenceFlow, ConditionalSequenceFlow, DefaultSequenceFlow]

--
-- Messages
--
type Message = String

--
-- Processes
--
type Process = Int

--
-- XML Ids
--
type Id = String

--
-- Names
--
type Name = String

--
-- Nodes
--
type Node = Id

--
-- Edges
--
type Edge = Id

--
-- BPMN Graph
--
data BpmnGraph = BpmnGraph { name     :: Text -- name of the model
                           , nodes    :: [Node] -- nodes (including sub-processes and top-level processes)
                           , edges    :: [Edge] -- edges
                           , catN     :: Map Node NodeType -- gives the category of a node
                           , catE     :: Map Edge EdgeType -- gives the category of an edge
                           , sourceE  :: Map Edge Node -- gives the source of an edge
                           , targetE  :: Map Edge Node -- gives the target of an edge
                           , nameN    :: Map Node Name -- gives the name of a node
                           , containN :: Map Node [Node] -- gives the nodes directly contained in a node n (n must be a subprocess or a process)
                           , containE :: Map Node [Edge] -- gives the edges (not the messageFlows) directly contained in a node n (n must be a subprocess of a process)
                           , messages :: [Message] -- gives all messages types
                           , messageE :: Map Edge Message -- message types associated to message flows
}
  deriving (Eq, Show, Generic)
instance ToJSON BpmnGraph
instance FromJSON BpmnGraph

instance Semigroup BpmnGraph
  where
      (BpmnGraph n ns es cn ce se te nn rn re m me)
        <> (BpmnGraph n' ns' es' cn' ce' se' te' nn' rn' re' m' me')
        =
        BpmnGraph
          (n <> n')
          (ns <> ns')
          (es <> es')
          (cn <> cn')
          (ce <> ce')
          (se <> se')
          (te <> te')
          (nn <> nn')
          (rn <> rn')
          (re <> re')
          (m <> m')
          (me <> me')

instance Monoid BpmnGraph
  where
    mempty =
      BpmnGraph
        ""
        [] [] M.empty M.empty
        M.empty M.empty
        M.empty
        M.empty M.empty
        [] M.empty

mkGraph :: Text
        -> [Node]
        -> [Edge]
        -> Map Node NodeType
        -> Map Node EdgeType
        -> Map Edge Node
        -> Map Edge Node
        -> Map Node Name
        -> Map Node [Node]
        -> Map Node [Edge]
        -> [Message]
        -> Map Edge Message
        -> BpmnGraph
mkGraph n ns es catN catE sourceE targetE nameN containN containE messages messageE
  = let graph = BpmnGraph n
                          ns
                          es
                          catN
                          catE
                          sourceE
                          targetE
                          nameN
                          containN
                          containE
                          messages
                          messageE
    in  graph

--
-- NODES
-- nodes g        : all nodes
-- nodesT g t     : all nodes of a given type
-- nodesTs g ts   : all nodes of given types
-- EDGES
-- edges g        : all edges
-- edgesT g t     : all edges of a given type
-- edgesTs g ts   : all edges of given types
-- inN g n        : input edges of node n
-- inNT g n t     : input edges of node n, that are of a given type
-- inNTs g n ts   : input edges of node n, that are of given types 
-- outN g n       : output edges of node n
-- outNT g n t    : output edges of node n, that are of a given type
-- outNTs g n ts  : output edges of node n, that are of given types 
--

--
-- all nodes of a given type
--
nodesT :: BpmnGraph -> NodeType -> [Node]
nodesT g t = filter' (nodes g) (catN g) (== Just t)

--
-- all nodes of given types
--
nodesTs :: BpmnGraph -> [NodeType] -> [Node]
nodesTs g ts = concat $ nodesT g <$> ts

--
-- all edges of a given type
--
edgesT :: BpmnGraph -> EdgeType -> [Edge]
edgesT g t = filter' (edges g) (catE g) (== Just t)

--
-- all edges of given types
--
edgesTs :: BpmnGraph -> [EdgeType] -> [Edge]
edgesTs g ts = concat $ edgesT g <$> ts

--
-- in
--
inN :: BpmnGraph -> Node -> [Edge]
inN g n = [ e | e <- edges g, target !? e == Just n ] where target = targetE g

--
-- in for one type
--
inNT :: BpmnGraph -> Node -> EdgeType -> [Edge]
inNT g n t = filter' (inN g n) (catE g) (== Just t)

--
-- in for several types
--
inNTs :: BpmnGraph -> Node -> [EdgeType] -> [Edge]
inNTs g n ts = concat $ inNT g n <$> ts

--
-- out
--
outN :: BpmnGraph -> Node -> [Edge]
outN g n = [ e | e <- edges g, source !? e == Just n ]
  where source = sourceE g

--
-- out for one type
--
outNT :: BpmnGraph -> Node -> EdgeType -> [Edge]
outNT g n t = filter' (outN g n) (catE g) (== Just t)

--
-- out for several types
--
outNTs :: BpmnGraph -> Node -> [EdgeType] -> [Edge]
outNTs g n ts = concat $ outNT g n <$> ts

--
-- checks
--
isValidGraph :: BpmnGraph -> Bool
isValidGraph g =
  and
    $   [ allNodesHave catN -- \forall n \in N . n \in dom(catN)
        , allEdgesHave catE -- \forall e \in E . e \in dom(catE) 
        , allEdgesHave sourceE -- \forall e \in E . e \in dom(sourceE) TODO: check that sourceE(e) \in N
        , allEdgesHave targetE -- \forall e \in E . e \in dom(targetE) TODO: check that targetE(e) \in N
        , allValidMessageFlow -- \forall m in E^{MessageFlow} . e \in dom(sourceE) /\ e \in dom(targetE)
                              --                             /\ sourceE(e) \in N^{ST,TMIE,MEE}
                              --                             /\ target(e) \in N^{RT,CMIE,MSE}
                              --                             /\ e \in dom(messageE)
                              --                             /\ messageE(e) \in messages
        , allValidSubProcess -- \forall n \in N^{SubProcess} \union N^{Process} . n \in dom(containN) \wedge n \in dom(containE)
        , allValidContainers -- \forall n \in dom(containN) \union dom(containE) . n \in N^{SubProcess} \union N^{Process}
        ]
    <*> [g]

isValidContainer :: BpmnGraph -> Node -> Bool
isValidContainer g n = n `elem` nodesTs g [SubProcess, Process]

allValidContainers :: BpmnGraph -> Bool
allValidContainers g = getAll $ foldMap (All . isValidContainer g) ns
 where
  ns    = keysN ++ keysE
  keysN = keys $ containN g
  keysE = keys $ containE g

isValidSubProcess :: BpmnGraph -> Node -> Bool
isValidSubProcess g n = n `elem` dom_containN && n `elem` dom_containE
 where
  dom_containN = keys $ containN g
  dom_containE = keys $ containE g

allValidSubProcess :: BpmnGraph -> Bool
allValidSubProcess g = getAll $ foldMap (All . isValidSubProcess g) ns
  where ns = nodesTs g [SubProcess, Process]

isValidMessage :: BpmnGraph -> Message -> Bool
isValidMessage _ _ = True

isValidMessageFlow :: BpmnGraph -> Edge -> Bool
isValidMessageFlow g mf =
  case
      do
        source <- sourceE g !? mf
        target <- targetE g !? mf
        cats   <- catN g !? source
        catt   <- catN g !? target
        msg    <- messageE g !? mf
        pure (cats, catt, msg)
    of
      Nothing -> False
      Just (cs, ct, m)
        -> (  cs
           == SendTask
           || cs
           == ThrowMessageIntermediateEvent
           || cs
           == MessageEndEvent
           )
          && (  ct
             == ReceiveTask
             || ct
             == CatchMessageIntermediateEvent
             || ct
             == MessageStartEvent
             )
          && (isValidMessage g m)

allValidMessageFlow :: BpmnGraph -> Bool
allValidMessageFlow g =
  getAll $ foldMap (All . isValidMessageFlow g) $ edgesT g MessageFlow

allNodesHave :: (BpmnGraph -> Map Node b) -> BpmnGraph -> Bool
allNodesHave = allDefF nodes

allEdgesHave :: (BpmnGraph -> Map Edge b) -> BpmnGraph -> Bool
allEdgesHave = allDefF edges

allDefF :: (Ord a, Foldable t, Functor t)
        => (BpmnGraph -> t a)
        -> (BpmnGraph -> Map a b)
        -> BpmnGraph
        -> Bool
allDefF h f g = allDef (h g) f g

allDef :: (Ord a, Foldable t, Functor t)
       => t a
       -> (BpmnGraph -> Map a b)
       -> BpmnGraph
       -> Bool
allDef xs f g = not $ any isNothing $ (m !?) <$> xs where m = f g

{-|
Fixpoint (based on sets).
Stops upon set equality, i.e. will stop if @f [1,2] = [2,1]@
-}
fixpoint :: (Ord a) => ([a] -> [a]) -> [a] -> [a]
fixpoint f xs | S.fromList xs == S.fromList xs' = xs
              | otherwise                       = fixpoint f xs'
  where xs' = (toList . S.fromList) $ f xs

predecessorEdges :: BpmnGraph -> Edge -> [Edge]
predecessorEdges g e = case sourceE g !? e of
  Nothing     -> []
  Just source -> fst <$> filter ((== source) . snd) (assocs $ targetE g)

predecessorEdgesSuchThat :: BpmnGraph -> (Edge -> Bool) -> Edge -> [Edge]
predecessorEdgesSuchThat g p e = filter p $ predecessorEdges g e

preE :: BpmnGraph -> Node -> Edge -> [Edge]
preE g n e = fixpoint step $ predecessorEdgesSuchThat g p e
 where
  p x = case (catE g !? x, targetE g !? x) of
    (_      , Nothing) -> False   -- if we cannot find the target for the predecessor we fail
                                  -- (impossible due to the way we compute the predecessor edges)
    (Nothing, _      ) -> False
    (Just c, Just n') ->
      n
        /= n'             -- else we want that it is not n
        && c
        /= MessageFlow -- end that the edge is a Message Flow
  step es = es <> foldMap (predecessorEdgesSuchThat g p) es
