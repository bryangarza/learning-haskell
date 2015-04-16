module JoinList where
import Data.Monoid
import Sized as S

data JoinList m a = Empty
                  | Single m a
                  | Append m (JoinList m a) (JoinList m a)
                  deriving (Eq, Show)

tag :: Monoid m => JoinList m a -> m
tag Empty            = mempty
tag (Single ann _)   = ann
tag (Append ann _ _) = ann

(+++) :: Monoid m => JoinList m a -> JoinList m a -> JoinList m a
(+++) a b = Append (tag a <> tag b) a b

(!!?) :: [a] -> Int -> Maybe a
[] !!? _        = Nothing
_ !!? i | i < 0 = Nothing
(x:xs) !!? 0    = Just x
(x:xs) !!? i    = xs !!? (i-1)

jlToList :: JoinList m a -> [a]
jlToList Empty            = []
jlToList (Single _ a)     = [a]
jlToList (Append _ l1 l2) = jlToList l1 ++ jlToList l2

branchSize :: (S.Sized b, Monoid b) => JoinList b a -> Int
branchSize = S.getSize . S.size . tag

indexJ :: (S.Sized b, Monoid b) => Int -> JoinList b a -> Maybe a
indexJ _ Empty = Nothing
indexJ i (Single m d)
  | i == 0    = Just d
  | otherwise = Nothing
indexJ i (Append m jl1 jl2)
  | i < 0                     = Nothing
  | i >= S.getSize (S.size m) = Nothing
  | i < s1                    = indexJ i jl1
  | otherwise                 = indexJ (i - s1) jl2
  where s1 = branchSize jl1

dropJ :: (Sized b, Monoid b) => Int -> JoinList b a -> JoinList b a
dropJ _ Empty = Empty
dropJ i jl@(Single _ _)
  | i <= 0    = jl
  | otherwise = Empty
dropJ i jl@(Append m jl1 jl2)
  | i <= 0    = jl
  | i < s1    = dropJ i jl1 +++ jl2
  | otherwise = dropJ (i - s1) jl2
  where s1 = branchSize jl1

takeJ :: (Sized b, Monoid b) => Int -> JoinList b a -> JoinList b a
takeJ _ Empty = Empty
takeJ i jl@(Single _ _)
  | i > 0     = jl
  | otherwise = Empty
takeJ i jl@(Append m jl1 jl2)
  | i <= 0    = Empty
  | i >= s1    = jl1 +++ takeJ (i - s1) jl2
  | otherwise = takeJ i jl1
  where s1 = branchSize jl1
