{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE CPP #-}

-- |
-- Module      : Text.Syntax.Parser.List.Compose
-- Copyright   : 2012 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- This module includes a naive parser implementation for "Text.Syntax.Poly".
-- Composed parser functions are not cached and composed every time by needed.
module Text.Syntax.Parser.List.Compose (
  -- * Syntax instance Parser type
  Parser, runParser, Result,
  -- * Poly- morphic wrapper of runParser
  runAsParser
  ) where

import Control.Applicative (Alternative(empty, (<|>)))
import Control.Monad (MonadPlus(mzero, mplus), ap, liftM)

#if __GLASGOW_HASKELL__ < 710
import Control.Applicative (Applicative(pure, (<*>)))
#endif

import Text.Syntax.Parser.Instances ()
import Text.Syntax.Poly.Class
  (TryAlternative, Syntax (token))
import Text.Syntax.Parser.List.Type (RunAsParser, ErrorString, errorString)

-- | Result type of 'Parser'
data Result a tok = Good !a ![tok] | Bad

maybeOfResult :: Result a tok -> Maybe a
maybeOfResult =  d  where
  d (Good a [])    = Just a
  d (Good _ (_:_)) = Nothing
  d Bad            = Nothing

-- | Constructive 'Parser' type. Parse @[tok]@ into @alpha@.
data Parser tok alpha =
  forall beta . Parser tok beta :>>= (beta -> Parser tok alpha) |
  Parser tok alpha              :<|> Parser tok alpha           |
  Prim ([tok] -> Result alpha tok)

-- | Function to run parser
runParser :: Parser tok alpha -> [tok] -> Result alpha tok
runParser p0 s0 = let z = d p0 s0 in z `seq` z  where
  d (Prim p)     s = p s
  d (pa :>>= fb) s =
    case runParser pa s of
      Good a s' -> runParser (fb a) s'
      Bad       -> Bad
  d (p1 :<|> p2) s =
    case runParser p1 s of
      Bad           -> runParser p2 s
      r1@(Good _ _) -> r1

instance Functor (Parser tok) where
  fmap = liftM

instance Applicative (Parser tok) where
  pure  = return
  (<*>) = ap

instance Monad (Parser tok) where
  return = Prim . Good
  (>>=)  = (:>>=)
  fail = const mzero

instance Alternative (Parser tok) where
  empty = mzero
  (<|>) = mplus

instance MonadPlus (Parser tok) where
  mzero = Prim $ const Bad
  mplus = (:<|>)

instance TryAlternative (Parser tok)

instance Eq tok => Syntax tok (Parser tok) where
  token = Prim (\s -> case s of
                   t:ts -> Good t ts
                   []   -> Bad)

-- | Run 'Syntax' as @'Parser' tok@.
runAsParser :: Eq tok => RunAsParser tok a ErrorString
runAsParser parser = maybe (Left . errorString $ "parse error") Right
                     . maybeOfResult . runParser parser
