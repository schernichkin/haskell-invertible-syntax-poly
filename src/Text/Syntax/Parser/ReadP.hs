{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances, UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

-- |
-- Module      : Text.Syntax.Poly.Parser.ReadP
-- Copyright   : 2012 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- This module includes 'Syntax' instance implementation for 'ReadP'.
module Text.Syntax.Parser.ReadP (runAsReadP) where

import Data.List (find)

import Text.Syntax.Parser.Instances ()
import Text.Syntax.Poly.Class
  (TryAlternative, Syntax(token))
import Text.Syntax.Poly.Type (RunAsParser, ErrorString, errorString)

import Text.ParserCombinators.ReadP (ReadP, get, readP_to_S)

-- | 'TryAlternative' instance of 'ReadP', method definitions is default.
instance TryAlternative ReadP

-- | 'Syntax' instance of 'Char' and 'ReadP'
instance Syntax Char ReadP where
  token = get

-- | Run syntax as 'ReadP'.
runAsReadP :: RunAsParser Char String a ErrorString
runAsReadP parser s =
  case find ((== []) . snd) $ readP_to_S parser s of
    Just (a, _) -> Right a
    Nothing     -> Left $ errorString "parse error"
