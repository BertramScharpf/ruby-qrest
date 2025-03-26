--
--  gf.hs  --  Galois field
--

import Data.Bits


uncycle :: (Eq a) => [a] -> [a]
uncycle [] = []
uncycle (a:rs) = a:before a rs
  where
    before s (t:rs) = if s == t then [] else t:before s rs


gfExps :: [Int]
gfExps = uncycle $ iterate fn 1
    where
      fn x =
        let
          x' = shiftL x 1
          x'' = x' .&. 0xff
        in
          if x'' == x' then x'' else xor x'' 0x1d

gfLogs = map (\i -> lookup i $ wi 0 gfExps) [0..length gfExps]
    where
      wi _ [] = []
      wi i (x:rs) = (x,i):wi (i+1) rs


gfExp :: Int -> Int
gfExp = (gfExps !!) . (flip mod 0xff)

gfLog :: Int -> Int
gfLog n = case gfLogs !! n of
            Nothing -> error "Argument out of domain."
            Just n  -> n

gfMul x y = gfExp $ (gfLog x) + (gfLog y)

