{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, RankNTypes, UndecidableInstances #-}
module Control.Effect.Internal
( Eff(..)
, runEff
, interpret
) where

import Control.Applicative (Alternative(..))
import Control.Effect.Handler
import Control.Effect.Fail.Internal
import Control.Effect.Lift.Internal
import Control.Effect.NonDet.Internal
import Control.Effect.Sum
import Control.Monad (liftM, ap)
import Control.Monad.Fail
import Control.Monad.IO.Class
import Prelude hiding (fail)

newtype Eff carrier a = Eff { unEff :: forall x . (a -> carrier x) -> carrier x }

runEff :: (a -> f x) -> Eff f a -> f x
runEff = flip unEff
{-# INLINE runEff #-}

interpret :: Carrier sig carrier => Eff carrier a -> carrier a
interpret = runEff gen
{-# INLINE interpret #-}

instance Functor (Eff carrier) where
  fmap = liftM

instance Applicative (Eff carrier) where
  pure a = Eff ($ a)

  (<*>) = ap

instance (Subset NonDet sig, Carrier sig carrier) => Alternative (Eff carrier) where
  empty = send Empty
  l <|> r = send (Choose (\ c -> if c then l else r))

instance Monad (Eff carrier) where
  return = pure

  Eff m >>= f = Eff (\ k -> m (runEff k . f))

instance (Subset Fail sig, Carrier sig carrier) => MonadFail (Eff carrier) where
  fail = send . Fail

instance (Subset (Lift IO) sig, Carrier sig carrier) => MonadIO (Eff carrier) where
  liftIO = send . Lift . fmap pure


instance Carrier sig carrier => Carrier sig (Eff carrier) where
  gen = pure
  alg op = Eff (\ k -> alg (hfmap (runEff gen) (fmap' (runEff k) op)))

instance (Carrier sig carrier, Effect sig) => Effectful sig (Eff carrier)
