{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections     #-}

module MegaParser where

import Control.Applicative
import Data.Char
import Data.Monoid
import Data.Text (strip, unpack, Text, pack)
import Data.Void
import Text.Megaparsec (Parsec)
import qualified Text.Megaparsec as M
import qualified Text.Megaparsec.Char as M

import Types

type MParser = Parsec Void Text

parseFeatureFromFile :: FilePath -> IO Feature
parseFeatureFromFile inputFile = do
  fileContents <- lines <$> readFile inputFile
  let nonEmptyLines = filter (not . isEmpty) fileContents
  let trimmedLines = map trim nonEmptyLines
  let finalString = pack $ unlines trimmedLines
  case M.runParser featureParser inputFile finalString of
    Left s -> error (show s)
    Right feature -> return feature

featureParser :: MParser Feature
featureParser = do
  M.string "Feature: "
  title <- consumeLine
  (description, maybeBackground, scenarios) <- parseRestOfFeature
  return $ Feature title description maybeBackground scenarios

parseRestOfFeature :: MParser ([String], Maybe Scenario, [Scenario])
parseRestOfFeature = parseRestOfFeatureTail []
  where
    parseRestOfFeatureTail prevDesc = do
      (fullDesc, maybeBG, scenarios) <- M.choice [noDescriptionLine prevDesc, descriptionLine prevDesc]
      return (fullDesc, maybeBG, scenarios)

    noDescriptionLine prevDesc = do
      maybeBackground <- optional backgroundParser
      scenarios <- some scenarioParser
      return (prevDesc, maybeBackground, scenarios)

    descriptionLine prevDesc = do
      nextLine <- consumeLine
      parseRestOfFeatureTail (prevDesc ++ [nextLine])

backgroundParser :: MParser Scenario
backgroundParser = do
  M.string "Background:"
  consumeLine
  statements <- many (parseStatement <* M.char '\n')
  examples <- (exampleTableParser <|> return (ExampleTable [] []))
  return $ Scenario "Background" statements examples

scenarioParser :: MParser Scenario
scenarioParser = do
  M.string "Scenario: "
  title <- consumeLine
  statements <- many (parseStatement <* M.char '\n')
  examples <- (exampleTableParser <|> return (ExampleTable [] []))
  return $ Scenario title statements examples

parseStatement :: MParser Statement
parseStatement =
  parseStatementLine "Given" <|>
  parseStatementLine "When" <|>
  parseStatementLine "Then" <|>
  parseStatementLine "And"

parseStatementLine :: Text -> MParser Statement
parseStatementLine signal = do
  M.string signal
  M.char ' '
  pairs <- many $ M.try ((,) <$> nonBrackets <*> insideBrackets)
  finalString <- nonBrackets
  let (fullString, keys) = buildStatement pairs finalString
  return $ Statement fullString keys
  where
    buildStatement :: [(String, String)] -> String -> (String, [String])
    buildStatement [] last = (last, [])
    buildStatement ((str, key) : rest) rem =
      let (str', keys) = buildStatement rest rem
      in (str <> "<" <> key <> ">" <> str', key : keys)

nonBrackets :: MParser String
nonBrackets = many (M.satisfy (\c -> c /= '\n' && c /= '<'))

insideBrackets :: MParser String
insideBrackets = do
  M.char '<'
  key <- many M.letterChar
  M.char '>'
  return key

exampleTableParser :: MParser ExampleTable
exampleTableParser = do
  M.string "Examples:"
  consumeLine
  keys <- exampleColumnTitleLineParser
  valueLists <- many exampleLineParser
  return $ ExampleTable keys (map (zip keys) valueLists)

exampleColumnTitleLineParser :: MParser [String]
exampleColumnTitleLineParser = do
  M.char '|'
  cells <- many cellParser
  M.char '\n'
  return cells
  where
    cellParser = do
      many (M.satisfy nonNewlineSpace)
      val <- many M.letterChar
      many (M.satisfy (not . barOrNewline))
      M.char '|'
      return val

exampleLineParser :: MParser [Value]
exampleLineParser = do
  M.char '|'
  cells <- many cellParser
  M.char '\n'
  return cells
  where
    cellParser :: MParser Value
    cellParser = do
      many (M.satisfy nonNewlineSpace)
      val <- valueParser
      many (M.satisfy (not . barOrNewline))
      M.char '|'
      return val

valueParser :: MParser Value
valueParser =
  nullParser <|>
  boolParser <|>
  numberParser <|>
  stringParser

nullParser :: MParser Value
nullParser = M.string' "null" >> return ValueNull

boolParser :: MParser Value
boolParser = (trueParser >> return (ValueBool True)) <|> (falseParser >> return (ValueBool False))
  where
    trueParser = M.string' "true"
    falseParser = M.string' "false"

numberParser :: MParser Value
numberParser = (ValueNumber . read) <$>
  (negativeParser <|> decimalParser <|> integerParser)
  where
    integerParser :: MParser String
    integerParser = M.try (some M.digitChar)

    decimalParser :: MParser String
    decimalParser = M.try $ do
      front <- many M.digitChar
      M.char '.'
      back <- some M.digitChar
      return $ front ++ ('.' : back)

    negativeParser :: MParser String
    negativeParser = M.try $ do
      M.char '-'
      num <- decimalParser <|> integerParser
      return $ '-' : num

stringParser :: MParser Value
stringParser = (ValueString . trim) <$>
  many (M.satisfy (not . barOrNewline))

isEmpty :: String -> Bool
isEmpty = all isSpace

trim :: String -> String
trim input = reverse flippedTrimmed
  where
    trimStart = dropWhile isSpace input
    flipped = reverse trimStart
    flippedTrimmed = dropWhile isSpace flipped

barOrNewline :: Char -> Bool
barOrNewline c = c == '|' || c == '\n'

nonNewlineSpace :: Char -> Bool
nonNewlineSpace c = isSpace c && c /= '\n'

consumeLine :: MParser String
consumeLine = do
  str <- many (M.satisfy (/= '\n'))
  M.char '\n'
  return str
