module Main where

import UI
import Control.Exception (displayException, try)
import Control.Monad (void, when)
import Data.Functor (($>))
import Data.Version (showVersion)
import Paths_hascard (version)
import Parser
import Options.Applicative
import System.Process (runCommand)

data Opts = Opts
  { optFile    :: Maybe String
  , optVersion :: Bool
  }

main :: IO ()
main = do
  useEscapeCode <- getUseEscapeCode
  when useEscapeCode $ void (runCommand "echo -n \\\\e[5 q")
  
  options <- execParser optsWithHelp
  if optVersion options
    then putStrLn (showVersion version)
    else run $ optFile options

opts :: Parser Opts
opts = Opts
  <$> optional (argument str (metavar "FILE" <> help "File containing flashcards"))
  <*> switch (long "version" <> short 'v' <> help "Show version number")

optsWithHelp :: ParserInfo Opts
optsWithHelp = info (opts <**> helper) $
              fullDesc <> progDesc "Run the normal application without argument, or run it directly on a deck of flashcards by providing a file."
              <> header "Hascard - a TUI for reviewing notes"

run :: Maybe String -> IO ()
run Nothing = runBrickFlashcards
run (Just file) = do
  valOrExc <- try (readFile file) :: IO (Either IOError String)
  case valOrExc of
    Left exc -> putStr (displayException exc)
    Right val -> case parseCards val of
      Left parseError -> print parseError
      Right result -> runCardsUI result $> ()