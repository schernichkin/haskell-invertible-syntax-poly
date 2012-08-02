{-# LANGUAGE Rank2Types #-}

-- |
-- Module      : Text.Syntax.Poly.Type
-- Copyright   : 2012 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- Type synonyms to represent syntax which has forall type value.

module Text.Syntax.Poly.Type (
  -- * Syntax type
  SyntaxT,
  -- * Type for runParser \/ runPrinter from syntax
  RunParser, RunPrinter,
  RunParserM, RunPrinterM,
  -- * Error string type
  ErrorString, errorString
  ) where

import Text.Syntax.Poly.Class (Syntax)

-- | Syntax type synonym includes contexts.
type SyntaxT tok a = forall delta . Syntax tok delta => delta a

type RunParser     tok tks a e = SyntaxT tok a -> tks -> Either e a
type RunPrinter    tok tks a e = SyntaxT tok a -> a   -> Either e tks
type RunParserM  m tok tks a e = SyntaxT tok a -> tks -> m (Either e a)
type RunPrinterM m tok tks a e = SyntaxT tok a -> a   -> m (Either e tks)

-- | String type which is Show instance not to show but just return string
newtype ErrorString = ErrorString String

errorString :: String -> ErrorString
errorString =  ErrorString

instance Show ErrorString where
  show (ErrorString s) = s
