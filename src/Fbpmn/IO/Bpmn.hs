module Fbpmn.IO.Bpmn where

import           Fbpmn.Model
import           Text.XML.Light
import qualified Data.Map                      as M
                                                ( empty )
import qualified Data.ByteString.Lazy          as BS
                                                ( readFile )
import           System.IO.Error                ( IOError
                                                , catchIOError
                                                , isDoesNotExistError
                                                )

uri :: String
uri = "http://www.omg.org/spec/BPMN/20100524/MODEL"

nA :: String -> QName
nA s = QName s Nothing Nothing

nE :: String -> QName
nE s = QName s (Just uri) (Just "bpmn")

aOrElseB :: String -> String -> Element -> Maybe String
aOrElseB an1 an2 e =
  do
    let av1 = findAttr (nA an1) e
    let av2 = findAttr (nA an2) e
    fromMaybe av2 (Just av1)

aOrElseB' :: String -> String -> String -> Element -> String
aOrElseB' def an1 an2 e =
    do
      let av1 = findAttr (nA an1) e
      let av2 = findAttr (nA an2) e
      fromMaybe (fromMaybe def av2) av1

nameOrElseId :: Element -> Maybe String
nameOrElseId = aOrElseB "name" "id"

idOrNothing :: Element -> Maybe String
idOrNothing = findAttr (nA "id")

{-|
An experimental BPMN reading.

Requirements:
- collaboration has a name
- message flows have a name (used as message type)

Enhancements:
- remove duplicates in cMessageTypes
-}
decode :: [Content] -> Maybe BpmnGraph
decode cs = do
    -- all elements
    allElements <- pure $ onlyElems cs
    -- collaboration (1st one to be found)
    c <- listToMaybe $ concatMap (findChildren (nE "collaboration")) allElements
    cName <- findAttr (nA "id") c
    -- participants
    cParticipants <- pure $ findChildren (nE "participant") c
    cParticipantRefs <- sequence $ findAttr (nA "processRef") <$> cParticipants
    cParticipantNames <- sequence $ aOrElseB "name" "processRef" <$> cParticipants
    -- processes
    allProcesses <- pure $ concatMap (findChildren (nE "process")) allElements
    cProcesses <- pure $ filter (filterByReferences cParticipantRefs) allProcesses 
    -- message flows and messages
    cMessageFlows <- pure $ findChildren (nE "messageFlow") c
    cMessageFlowIds <- sequence $ idOrNothing <$> cMessageFlows
    cMessageTypes <- sequence $ nameOrElseId <$> cMessageFlows
    -- graph
    Just (mkGraph
          (toText cName)
          cParticipantNames -- TODO: completer avec tous les nodes
          cMessageFlowIds -- TODO: completer avec tous les edges
          M.empty -- TODO:
          M.empty -- TODO:
          M.empty -- TODO:
          M.empty -- TODO:
          M.empty -- TODO:
          M.empty -- TODO:
          M.empty -- TODO:
          cMessageTypes
          M.empty -- TODO:
          )
    where
      filterByReferences = undefined 

{-|
Read a BPMN Graph from a BPMN file.
-}
readFromBPMN :: FilePath -> IO (Maybe BpmnGraph)
readFromBPMN p = (decode . parseXML <$> BS.readFile p) `catchIOError` handler
 where

  handler :: IOError -> IO (Maybe BpmnGraph)
  handler e
    | isDoesNotExistError e = do
      putTextLn "file not found"
      pure Nothing
    | otherwise = do
      putTextLn "unknown error"
      pure Nothing
