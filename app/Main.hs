{-# LANGUAGE OverloadedStrings #-}

module Main where

  import           Control.Exception
  import           Control.Monad
  import qualified Data.List          as DL
  import qualified Data.Text          as T
  import qualified Data.Text.IO       as TIO
  import qualified System.Directory   as SD
  import qualified System.Environment as SE
  import qualified System.Process     as SP

  cabalExt :: String
  cabalExt = ".cabal"

  commandsSimpleMode :: [String]
  commandsSimpleMode = []

  commandsRebuildMode :: [String]
  commandsRebuildMode = ["stack clean", "stack build"]

  stackExec :: String
  stackExec = "stack exec"

  main :: IO ()
  main = do
    cbm <- getCabalFilename
    flip (maybe (error "Have no .cabal files found.")) cbm $ \cabal -> do
      mode <- getCommandsMode
      execs <- getExecutables . T.lines <$> TIO.readFile cabal
      if null execs
        then error "Have no executables found."
        else exe mode $ T.unpack (head execs)

  getCommandsMode :: IO [String]
  getCommandsMode = do
    args <- SE.getArgs
    if "-r" `elem` args
      then return commandsRebuildMode
      else return commandsSimpleMode

  exe :: [String] -> String -> IO ()
  exe _ [] = error "Empty executable name."
  exe cmds exename = do
    let
      cmd :: String
      cmd = stackExec ++ " " ++ exename
    r <- exe' cmds
    when r $ run' cmd
    where
      exe' :: [String] -> IO Bool
      exe' (a:as) = do
        r <- runFail a
        if r
          then exe' as
          else return r
      exe' _ = return True

      run' :: String -> IO ()
      run' cmd = void (try (SP.callCommand cmd) :: IO (Either SomeException ()))

      runFail :: String -> IO Bool
      runFail cmd = catch (SP.callCommand cmd >> return True) handlerFail

      handlerFail :: SomeException -> IO Bool
      handlerFail _ = return False

  getExecutables :: [T.Text] -> [T.Text]
  getExecutables [] = []
  getExecutables (l:ls)
    | T.null l = getExecutables ls
    | otherwise =
      let
        lc :: T.Text
        lc = T.strip . T.toLower $ l
      in
        if "executable" `T.isPrefixOf` lc
          then last (T.words lc) : getExecutables ls
          else getExecutables ls

  getCabalFilename :: IO (Maybe FilePath)
  getCabalFilename = do
    files <- SD.getCurrentDirectory >>= SD.getDirectoryContents
    return $ DL.find (cabalExt `DL.isSuffixOf`) files
