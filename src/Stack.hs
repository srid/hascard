module Stack (module Stack, module X) where
import Data.Maybe (fromJust)
import Data.Foldable as X (toList)
import Data.Set.Ordered (OSet, (|<))
import qualified Data.Set.Ordered as OS

type Stack a = OSet a

empty :: Stack a
empty = OS.empty

insert :: Ord a => a -> Stack a -> Stack a
insert = (|<)

removeLast :: Ord a => Stack a -> Stack a
removeLast s = OS.delete (Stack.last s) s

head :: Stack a -> a
head = (`unsafeElemAt` 0)

last :: Stack a -> a
last s = s `unsafeElemAt` (Stack.size s - 1)

tail :: Ord a => Stack a -> [a]
tail s = toList $ OS.delete (Stack.head s) s

elemAt :: Stack a -> Int -> Maybe a
elemAt = OS.elemAt

unsafeElemAt :: Stack a -> Int -> a
unsafeElemAt s = fromJust . OS.elemAt s

fromList :: Ord a => [a] -> Stack a
fromList = OS.fromList

-- toList :: Ord a => Stack a -> [a]
-- toList = toList

size :: Stack a -> Int
size = OS.size