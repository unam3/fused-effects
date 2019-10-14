{-# LANGUAGE DataKinds, DeriveGeneric, FlexibleInstances, FunctionalDependencies, GADTs, GeneralizedNewtypeDeriving, LambdaCase, RankNTypes, ScopedTypeVariables, StandaloneDeriving, TypeOperators, UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-identities #-}
module Pure
( module Control.Carrier.Pure
, (~=)
, genM
, genT
, a
, b
, e
, r
, s
, T(..)
, A
, B
, E
, R
, S
, Rec(..)
, forall
, Blind(..)
) where

import Control.Carrier.Pure
import Hedgehog
import Hedgehog.Function hiding (R, S)
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

(~=) :: (Eq a, Show a) => PureC a -> PureC a -> PropertyT IO ()
m1 ~= m2 = run m1 === run m2


-- | A generator for computations, given a higher-order generator for effectful operations, & a generator for results.
genM
  :: forall m a
  .  Applicative m
  => (forall a . (forall a . Gen a -> Gen (m a)) -> Gen a -> Gen (m a)) -- ^ A higher-order generator producing operations using any effects in @m@.
  -> Gen a                                                              -- ^ A generator for results.
  -> Gen (Blind (m a))                                                  -- ^ A generator producing computations, wrapped in 'Blind' for convenience.
genM with = fmap Blind . go where
  go :: forall a . Gen a -> Gen (m a)
  go a = Gen.sized $ \case
    Size i
      | i <= 1 -> fmap pure a
      | otherwise -> Gen.choice [ fmap pure a, with (Gen.scale (`div` 2) . go) a]


genT :: Gen (T a)
genT = Gen.integral (Range.linear 0 10)

newtype T a = T { unT :: Integer }
  deriving (Enum, Eq, Generic, Integral, Num, Ord, Real, Show, Vary)

instance Arg (T a)

a :: Gen (T A)
a = genT

data A

b :: Gen (T B)
b = genT

data B

e :: Gen (T E)
e = genT

data E

r :: Gen (T R)
r = genT

data R

s :: Gen (T S)
s = genT

data S


infixr 5 :.

data Rec as where
  Nil :: Rec '[]
  (:.) :: a -> Rec as -> Rec (a ': as)

forall :: Forall g f => g -> f -> Hedgehog.Property
forall g f = Hedgehog.property (forall' g f)

class Forall g f | g -> f, f -> g where
  forall' :: g -> f -> PropertyT IO ()

instance Forall (Rec '[]) (PropertyT IO ()) where
  forall' Nil = id

instance (Forall (Rec gs) b, Show a) => Forall (Rec (Gen a ': gs)) (a -> b) where
  forall' (g :. gs) f = do
    a <- Hedgehog.forAll g
    forall' gs (f a)


newtype Blind a = Blind { getBlind :: a }
  deriving (Eq, Ord)

instance Show (Blind a) where
  show _ = "_"
