{-# LANGUAGE KindSignatures #-}
module Control.Effect.Abort
( -- * Abort effect
  Abort(..)
) where

data Abort (m :: * -> *) k = Abort
