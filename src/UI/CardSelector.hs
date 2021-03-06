{-# LANGUAGE TemplateHaskell #-}
module UI.CardSelector (runCardSelectorUI, getRecents, getRecentsFile, addRecent) where

import Brick
import Brick.Widgets.Border
import Brick.Widgets.Border.Style
import Brick.Widgets.Center
import Control.Exception (displayException, try)
import Control.Monad.IO.Class
import Lens.Micro.Platform
import Parser
import Stack (Stack)
import System.Environment (lookupEnv)
import System.FilePath ((</>), takeBaseName)
import UI.BrickHelpers
import UI.FileBrowser (runFileBrowserUI)
import UI.Cards (runCardsUI)
import qualified Brick.Widgets.List as L
import qualified Data.Vector as Vec
import qualified Graphics.Vty as V
import qualified Stack as S
import qualified System.Directory as D
import qualified System.IO.Strict as IOS (readFile)

type Event = ()
type Name = ()
data State = State
  { _list       :: L.List Name String
  , _exception  :: Maybe String
  , _recents    :: Stack FilePath
  }

makeLenses ''State

app :: App State Event Name
app = App 
  { appDraw = drawUI
  , appChooseCursor = neverShowCursor
  , appHandleEvent = handleEvent
  , appStartEvent = return
  , appAttrMap = const theMap
  }

drawUI :: State -> [Widget Name]
drawUI s = 
  [ drawMenu s <=> drawException s ]

title :: Widget Name
title = withAttr titleAttr $ hCenteredStrWrap "Select a deck of flashcards"

drawMenu :: State -> Widget Name
drawMenu s = 
  joinBorders $
  center $ 
  withBorderStyle unicodeRounded $
  border $
  hLimitPercent 60 $
  title <=>
  hBorder <=>
  hCenter (drawList s)

drawList :: State -> Widget Name
drawList s = vLimit 6  $
             L.renderListWithIndex (drawListElement l) True l
              where l = s ^. list

drawListElement :: L.List Name String -> Int -> Bool -> String -> Widget Name
drawListElement l i selected = hCenteredStrWrapWithAttr (wAttr1 . wAttr2)
  where wAttr1 = if selected then withDefAttr selectedAttr else id
        wAttr2 = if i == length l - 1 then withAttr lastElementAttr else id

drawException :: State -> Widget Name
drawException s = case s ^. exception of
  Nothing -> emptyWidget
  Just exc  -> withAttr exceptionAttr $ strWrap exc

titleAttr :: AttrName
titleAttr = attrName "title"

selectedAttr :: AttrName
selectedAttr = attrName "selected"

lastElementAttr :: AttrName
lastElementAttr = attrName "last element"

exceptionAttr :: AttrName
exceptionAttr = attrName "exception"

theMap :: AttrMap
theMap = attrMap V.defAttr
    [ (L.listAttr, V.defAttr)
    , (selectedAttr, fg V.white `V.withStyle` V.underline)
    , (titleAttr, fg V.yellow)
    , (lastElementAttr, fg V.blue)
    , (exceptionAttr, fg V.red) ]

handleEvent :: State -> BrickEvent Name Event -> EventM Name (Next State)
handleEvent s@State{_list=l} (VtyEvent e) =
    case e of
        V.EvKey (V.KChar 'c') [V.MCtrl]  -> halt s
        V.EvKey V.KEsc [] -> halt s

        _ -> do l' <- L.handleListEventVi L.handleListEvent e l
                let s' = (s & list .~ l') in
                  case e of
                    V.EvKey V.KEnter [] ->
                      case L.listSelectedElement l' of
                        Nothing -> continue s'
                        Just (_, "Select file from system") -> suspendAndResume $ runFileBrowser s'
                        Just (i, _) -> do
                            let fp = (s' ^. recents) `S.unsafeElemAt` i
                            fileOrExc <- liftIO (try (readFile fp) :: IO (Either IOError String))
                            case fileOrExc of
                              Left exc -> continue (s' & exception ?~ displayException exc)
                              Right file -> case parseCards file of
                                Left parseError -> continue (s' & exception ?~ show parseError)
                                Right result -> suspendAndResume $ do
                                  s'' <- addRecent s' fp
                                  _ <- runCardsUI result
                                  return (s'' & exception .~ Nothing)
                    _ -> continue s'

handleEvent l _ = continue l

runCardSelectorUI :: IO ()
runCardSelectorUI = do
  rs <- getRecents
  let prettyRecents = shortenFilepaths (S.toList rs)
  let options = Vec.fromList (prettyRecents ++ ["Select file from system"])
  let initialState = State (L.list () options 1) Nothing rs
  _ <- defaultMain app initialState
  return () 

getRecents :: IO (Stack FilePath)
getRecents = do
  rf <- getRecentsFile
  exists <- D.doesFileExist rf
  if exists
    then S.fromList . lines <$> IOS.readFile rf
    else return S.empty

maxRecents :: Int
maxRecents = 5

addRecent :: State -> FilePath -> IO State
addRecent s fp = do
  rs <- getRecents
  let rs'  = fp `S.insert` rs 
      rs'' =
               if S.size rs' <= maxRecents
                then rs'
                else S.removeLast rs'
  
  writeRecents rs'' *> refreshRecents s

writeRecents :: Stack FilePath -> IO ()
writeRecents stack = do
  file <- getRecentsFile
  writeFile file $ unlines (S.toList stack)

getRecentsFile :: IO FilePath
getRecentsFile = do
  maybeSnap <- lookupEnv "SNAP_USER_DATA"
  xdg <- D.getXdgDirectory D.XdgData "hascard"

  let dir = case maybeSnap of
                Just path | not (null path) -> path
                          | otherwise       -> xdg
                Nothing                     -> xdg
  D.createDirectoryIfMissing True dir

  return (dir </> "recents")

shortenFilepaths :: [FilePath] -> [FilePath]
shortenFilepaths = map takeBaseName

refreshRecents :: State -> IO State
refreshRecents s = do
  rs <- getRecents
  let prettyRecents = shortenFilepaths (S.toList rs)
      options       = Vec.fromList (prettyRecents ++ ["Select file from system"])
  return $ s & recents .~ rs
             & list    .~ L.list () options 1

runFileBrowser :: State -> IO State
runFileBrowser s = do
  result <- runFileBrowserUI
  maybe (return s) (\(cards, fp) -> addRecent s fp <* runCardsUI cards) result