module Network.TLS.Crypto.DH
    (
    -- * DH types
      DHParams
    , DHPublic
    , DHPrivate

    -- * DH methods
    , dhPublic
    , dhPrivate
    , dhParams
    , dhParamsGetP
    , dhParamsGetG
    , dhGenerateKeyPair
    , dhGetShared
    , dhUnwrap
    , dhUnwrapPublic
    ) where

import qualified Crypto.PubKey.DH as DH
import           Crypto.Number.Basic (numBits)
import qualified Data.ByteArray as B
import           Network.TLS.RNG

type DHPublic   = DH.PublicNumber
type DHPrivate  = DH.PrivateNumber
type DHParams   = DH.Params
type DHKey      = DH.SharedKey

dhPublic :: Integer -> DHPublic
dhPublic = DH.PublicNumber

dhPrivate :: Integer -> DHPrivate
dhPrivate = DH.PrivateNumber

dhParams :: Integer -> Integer -> DHParams
dhParams p g = DH.Params p g (numBits p)

dhGenerateKeyPair :: MonadRandom r => DHParams -> r (DHPrivate, DHPublic)
dhGenerateKeyPair params = do
    priv <- DH.generatePrivate params
    let pub        = DH.generatePublic params priv
    return (priv, pub)

dhGetShared :: DHParams -> DHPrivate -> DHPublic -> DHKey
dhGetShared params priv pub =
    stripLeadingZeros (DH.getShared params priv pub)
  where
    -- strips leading zeros from the result of DH.getShared, as required
    -- for DH(E) premaster secret in SSL/TLS before version 1.3.
    stripLeadingZeros (DH.SharedKey sb) = DH.SharedKey (snd $ B.span (== 0) sb)

dhUnwrap :: DHParams -> DHPublic -> [Integer]
dhUnwrap (DH.Params p g _) (DH.PublicNumber y) = [p,g,y]

dhParamsGetP :: DHParams -> Integer
dhParamsGetP (DH.Params p _ _) = p

dhParamsGetG :: DHParams -> Integer
dhParamsGetG (DH.Params _ g _) = g

dhUnwrapPublic :: DHPublic -> Integer
dhUnwrapPublic (DH.PublicNumber y) = y
