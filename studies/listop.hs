--
--  listop.hs  --  Listen Operations
--


foldL :: (b -> a -> b) -> b -> [a] -> b
foldL _  a [] = a
foldL fn a (f:rs) = foldL fn (fn a f) rs

foldR :: (a -> b -> b) -> b -> [a] -> b
foldR _  a [] = a
foldR fn a (f:rs) = let a' = foldR fn a rs in fn f a'



replaceAt :: Integer -> a -> [a] -> [a]
replaceAt _ _ []     = []
replaceAt 0 e (f:rs) = e:rs
replaceAt i e (f:rs) = f:(replaceAt (pred i) e rs)

replaceFrom' :: Integer -> [a] -> [a] -> [a]
replaceFrom' _ _      []     = []
replaceFrom' 0 (e:qs) (f:rs) = e:replaceFrom' 0 qs rs
replaceFrom' i xs     (f:rs) = f:(replaceFrom' (pred i) xs rs)


editFrom :: Integer -> [a -> a] -> [a] -> [a]
editFrom _ _       []     = []
editFrom 0 (fn:qs) (f:rs) = (fn f):editFrom 0 qs rs
editFrom i xs      (f:rs) = f:(editFrom (pred i) xs rs)

replaceBy :: a -> a -> a
replaceBy e _ = e

-- Is this one really better?
replaceFrom :: Integer -> [a] -> [a] -> [a]
replaceFrom n as xs = editFrom n (map replaceBy as) xs


iterate' :: (a -> a) -> a -> [a]
iterate' fn a = a:iterate' fn (fn a)


square n = take n $ iterate' id $ take n $ iterate' id 0
little = [[1,2,3],[4,5,6],[7,8,9]]


test' = map (replaceFrom 2 [1,2,3]) $ square 8

test'' = replaceFrom 3 [[0,0,1,2,3,0,0,0],[0,0,1,2,3,0,0,0],[0,0,1,2,3,0,0,0]] $ square 8
test''' = editFrom 3 [replaceFrom 3 (little !! 0),replaceFrom 3 (little !! 1),replaceFrom 3 (little !! 2)] $ square 8
test = editFrom 2 (map (replaceFrom 3) little) $ square 8

