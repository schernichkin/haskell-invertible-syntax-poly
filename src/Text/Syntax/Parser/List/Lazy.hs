{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE CPP #-}

-- |
-- Module      : Text.Syntax.Parser.List.Lazy
-- Copyright   : 2012 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- This module includes a lazy parser implementation for "Text.Syntax.Poly".
module Text.Syntax.Parser.List.Lazy (
  -- * Syntax instance Parser type
  Parser, runParser, ErrorStack,
  -- * Poly- morphic wrapper of runParser
  runAsParser
  ) where

import Control.Applicative (Alternative(empty, (<|>)))
import Control.Monad (MonadPlus(mzero, mplus), ap, liftM)

#if __GLASGOW_HASKELL__ < 710
import Control.Applicative (Applicative(pure, (<*>)))
#endif

import Text.Syntax.Parser.Instances ()
import Text.Syntax.Poly.Instances ()
import Text.Syntax.Poly.Class
  (TryAlternative, Syntax (..))
import Text.Syntax.Parser.List.Type (RunAsParser, ErrorStack, errorString)

-- | Naive 'Parser' type. Parse @[tok]@ into @alpha@.
newtype Parser tok alpha =
  Parser {
    -- | Function to run parser
    runParser :: [tok] -> ErrorStack -> Either ErrorStack (alpha, [tok])
    }

instance Functor (Parser tok) where
  fmap = liftM

instance Applicative (Parser tok) where
  pure  = return
  (<*>) = ap

instance Monad (Parser tok) where
  return a = Parser $ \s _ -> Right (a, s)
  Parser p >>= fb = Parser (\s e -> do (a, s') <- p s e
                                       runParser (fb a) s' e)
  fail msg = Parser (\_ e -> Left $ errorString msg : e)

instance Alternative (Parser tok) where
  empty = mzero
  (<|>) = mplus

instance MonadPlus (Parser tok) where
  mzero = Parser $ const Left
  Parser p1 `mplus` p2' =
    Parser (\s e -> case p1 s e of
               Left e' -> runParser p2' s (e' ++ e)
               r1      -> r1)

instance TryAlternative (Parser tok)

instance Eq tok => Syntax tok (Parser tok) where
  token = Parser (\s e -> case s of
                     t:ts -> Right (t, ts)
                     []   -> Left $ errorString "The end of token stream." : e)

-- | Run 'Syntax' as @'Parser' tok@.
runAsParser :: Eq tok => RunAsParser tok a ErrorStack
runAsParser parser s =
  do (a, s') <- runParser parser s []
     if s' == []
       then Right a
       else Left [errorString "Not the end of token stream."]
