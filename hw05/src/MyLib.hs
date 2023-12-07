{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE FlexibleInstances #-}

module MyLib where

import qualified Data.Map.Strict as M
import Data.Monoid (All(..), Sum(..), getSum, getAll)
import Data.Maybe (isNothing, fromJust)

-- Во всех заданиях с инстансами укажите сигнатуры функций

-- Бонус: запишите решения в стиле point free там где это возможно и __не портит читаемость__
-- (до +1 балла к стандартным 10)

-------------------------------------------------------------------------------

-- 1. Functor для (->) (0,5 балла)
-- | Arrow представляет собой обертку над функцией из a в b
--
newtype Arrow a b = Arrow (a -> b)

instance Functor (Arrow a) where
  fmap :: (b -> c) -> Arrow a b -> Arrow a c
  fmap f (Arrow g) = Arrow (f . g)
-- Напишите инстанс Functor для Arrow и покажите выполнение законов

-- Identity
-- fmap id = id
-- fmap id (Arrow g) = Arrow (id . g) = Arrow g

-- Composition
-- fmap (f . g) = fmap f . fmap g
-- fmap (f . g) (Arrow h) = Arrow ((f . g) . h)
-- fmap f (fmap g (Arrow h)) = fmap f (Arrow (g . h)) = Arrow (f . (g . h))
-------------------------------------------------------------------------------

-- 2. Студенты и Moinoid (1 балл)

-- | Тип данных "Студент"
--
data Student = Student 
    { name  :: String -- имя студента
    , grade :: Int    -- оценка студента по нашему предмету
    }
  deriving (Show, Eq)

data StudentsLog = StudentsLog
    { studentNames :: [String]  -- список имён студентов
    , worstGrade   :: Maybe Int -- наименьшая оценка по курсу
    , bestGrade    :: Maybe Int -- наибольшая оценка по курсу
    }
  deriving (Show, Eq)

-- 2.a Функция, которая по списку студентов курса рассчитывает информацию по курсу (0,5 балла)
--
calculateStudentsLog :: [Student] -> StudentsLog
calculateStudentsLog students = StudentsLog
  { studentNames = map name students
  , worstGrade   = minimumMaybe $ map grade students
  , bestGrade    = maximumMaybe $ map grade students
  }
  where
    minimumMaybe :: Ord a => [a] -> Maybe a
    minimumMaybe [] = Nothing
    minimumMaybe xs = Just $ minimum xs

    maximumMaybe :: Ord a => [a] -> Maybe a
    maximumMaybe [] = Nothing
    maximumMaybe xs = Just $ maximum xs

-- 2.b Сделайте 'StudentsLog' представителем класса типов 'Monoid' и реализуйте
--     calculateStudentsLog', которая делает то же самое, что и calculateStudentsLog
--     В реализации нужно использовать то, что 'StudentsLog' — моноид. (0,5 балла)
--
instance Semigroup StudentsLog where
  (<>) :: StudentsLog -> StudentsLog -> StudentsLog
  StudentsLog names1 worst1 best1 <> StudentsLog names2 worst2 best2 =
    StudentsLog (names1 <> names2) (minMaybe worst1 worst2) (maxMaybe best1 best2)
    where 
      minMaybe :: Ord a => Maybe a -> Maybe a -> Maybe a
      minMaybe Nothing  x        = x
      minMaybe x        Nothing  = x
      minMaybe (Just a) (Just b) = Just (min a b)

      maxMaybe :: Ord a => Maybe a -> Maybe a -> Maybe a
      maxMaybe Nothing  x        = x
      maxMaybe x        Nothing  = x
      maxMaybe (Just a) (Just b) = Just (max a b)

instance Monoid StudentsLog where
  mempty :: StudentsLog
  mempty = StudentsLog [] Nothing Nothing

calculateStudentsLog' :: [Student] -> StudentsLog
calculateStudentsLog' = foldMap singleStudentLog
  where
    singleStudentLog :: Student -> StudentsLog
    singleStudentLog student = StudentsLog [name student] (Just (grade student)) (Just (grade student))

-------------------------------------------------------------------------------

-- 3. Дерево и Foldable (1 балл)

data Tree a = Node a [Tree a] | Leaf
  deriving (Eq, Show)

-- Сделайте 'Tree' представителем класса типов 'Foldable'

instance Foldable Tree where
  foldMap :: Monoid m => (a -> m) -> Tree a -> m
  foldMap _ Leaf              = mempty
  foldMap f (Node x children) = f x <> foldMap (foldMap f) children

-------------------------------------------------------------------------------

-- 4. Яблоко и Foldable (1 балл)

data Apple = Apple
    { color  :: String -- цвет яблока
    , weight :: Float  -- вес яблока
    }
  deriving (Eq, Show)

-- С помощью функций из 'Data.Foldable' реализуйте следующие функции:

-- 4.a Проверка, что все яблоки в дереве имеют вес, который находится 
--     в заданном диапазоне весов (0,25 балла)
--
applesInRange :: Tree Apple -> (Float, Float) -> Bool
applesInRange t range = getAll $ foldMap (\apple -> All $ weight apple >= fst range && weight apple <= snd range) t

-- 4.b Находит яблоко с наибольшим весом (0,25 балла)
--
heaviestApple :: Tree Apple -> Maybe Apple
heaviestApple = foldr (\apple acc -> if isNothing acc || weight apple > weight (fromJust acc) then Just apple else acc) Nothing

-- 4.c Находит яблоко с цветом из заданного списка цветов и весом,
--     находящимся в заданном диапазоне весов (0,25 балла)
--
thisApple :: Tree Apple -> [String] -> (Float, Float) -> Maybe Apple
thisApple t colors range =
  foldr checkApple Nothing t
  where
    checkApple apple acc =
      if isNothing acc &&
          weightInRange apple range &&
          colorMatches apple colors
        then Just apple
        else acc

    weightInRange apple (lower, upper) =
      weight apple >= lower &&
      weight apple <= upper

    colorMatches apple availableColors =
      color apple `elem` availableColors
-- 4.d Считает сумму весов всех яблок в дереве (0,25 балла)
--
sumOfApples :: Tree Apple -> Float
sumOfApples t = getSum $ foldMap (Sum . weight) t

-------------------------------------------------------------------------------

-- 5. Корзинка с яблоками и Foldable (0,5 балла)

-- | Яблоки в корзинке расфасованы по цветам.
-- | Для каждого цвета яблоки упорядочены по весу
--
newtype Basket = Basket { apples :: M.Map String [Apple] }
  deriving (Eq, Show)

-- Реализуйте с помощью свёртки дерева функцию, которая соберёт 
-- по дереву яблок корзинку с яблоками.
-- В 'Data.Map.Strict' вы найдёте функции, которые помогут вам
-- инициализировать и модифицировать мапу
--      
collectBasket :: Tree Apple -> Basket
collectBasket t = Basket $ foldr collectApple M.empty t
  where
    collectApple :: Apple -> M.Map String [Apple] -> M.Map String [Apple]
    collectApple (Apple c w) =
      M.insertWith (++) c [Apple c w]

-------------------------------------------------------------------------------

-- 6. Двоичная куча и Foldable (1,5 балла)
--    https://neerc.ifmo.ru/wiki/index.php?title=Двоичная_куча
--
data BinaryHeap a 
  = BinNode 
      { val   :: a
      , left  :: BinaryHeap a
      , right :: BinaryHeap a
      } 
  | BinLeaf
  deriving (Eq, Show)

-- 6.a Реализуйте функцию siftDown, восстанавливающую свойство кучи в куче (0,5 балла)
--      
siftDown :: Ord a => BinaryHeap a -> BinaryHeap a
siftDown BinLeaf                     = BinLeaf
siftDown (BinNode v BinLeaf BinLeaf) = BinNode v BinLeaf BinLeaf
siftDown node@(BinNode x leftNode@(BinNode lx _ _) BinLeaf)
  | x < lx    = node
  | otherwise = BinNode lx (siftDown $ leftNode {val = x}) BinLeaf
siftDown node@(BinNode x BinLeaf rightNode@(BinNode rx _ _))
  | x < rx    = node
  | otherwise = BinNode rx BinLeaf (siftDown $ rightNode {val = x})
siftDown node@(BinNode x leftNode@(BinNode lx _ _) rightNode@(BinNode rx _ _))
  | x < min lx rx = node
  | lx < rx       = BinNode lx (siftDown $ leftNode {val = x}) rightNode
  | otherwise     = BinNode rx leftNode (siftDown $ rightNode {val = x})

-- 6.b Реализуйте с помощью свёртки функцию buildHeap,
--     которая за __линейное время__ конструирует на основе спиcка элементов бинарную кучу.
--     Соответствующий алогритм описан в статье на вики (ссылка выше).
--     Считайте, что изменение элемента 'Data.Array' происходит за константу (хотя это не так!)
--     (1 балл)
--       
buildHeap :: Ord a => [a] -> BinaryHeap a -- пока не корректно
buildHeap = foldr (\x heap -> siftDown (BinNode x BinLeaf BinLeaf `merge` heap)) BinLeaf
  where
    merge :: Ord a => BinaryHeap a -> BinaryHeap a -> BinaryHeap a
    merge BinLeaf heap = heap
    merge heap BinLeaf = heap
    merge h1@(BinNode v1 l1 r1) h2@(BinNode v2 l2 r2)
      | v1 <= v2  = BinNode v1 (merge r1 h2) l1
      | otherwise = BinNode v2 (merge r2 h1) l2

-------------------------------------------------------------------------------

-- 7. A list with random access (2 балла)

-- Начнем с самой простой из всех структур данных - связанного списка.
-- Как вы хорошо знаете, поиск головной части списка происходит быстро, а произвольный доступ - гораздо медленнее:
-- xs !! n для получения n-го элемента списка требуется O(n), т.е. линейное время.
-- Мы хотели бы создать более быструю спископодобную структуру данных, которая сократила бы это время до O(log n)

-- | Зададим бинарное дерево, в листьях которого хранятся элементы a
-- | Кроме того, каждый узел в этом дереве аннотируется значением типа v (tag)
--
data BinaryTree v a = BLeaf v a | BBranch v (BinaryTree v a) (BinaryTree v a)
  deriving (Show)

-- Тогда наше дерево будет выглядеть так
--      v
--    /   \
--   v     v
--  / \   / \
-- v  v  v   v
-- a  a  a  / \
--         v   v
--         a   a

-- 7.a В листьях хранятся элементы нашего списка слева направо 
--     Реализуйте получение списка элементов из дерева (0,25 балла)
--
toList :: BinaryTree v a -> [a]
toList (BLeaf _ x)     = [x]
toList (BBranch _ l r) = toList l ++ toList r

-- 7.b Реализуйте tag, возвращающую текущий тег дерева (0,25 балла)

tag :: BinaryTree v a -> v
tag (BLeaf v _)     = v
tag (BBranch v _ _) = v

-- 7.c Реализуйте head, которая извлекает самый левый элемент (0,25 балла)
--
head' :: BinaryTree v a -> a
head' (BLeaf _ x)     = x
head' (BBranch _ l _) = head' l

-- Итак, доступ к первому листу был прост, а как быть со вторым, третьим, n-ым листом?
-- Решение состоит в том, чтобы аннотировать каждое поддерево его размером.

type Size = Int

-- Тогда наше дерево будет иметь тип `BinaryTree Size a` и выглядеть так
--      5
--    /   \
--   2     3
--  / \   / \
-- 1  1  1   2
-- a  a  a  / \
--         1   1
--         a   a

-- Таким образом, мы задаем v = Size и хотим, чтобы аннотации выполняли следующие условия
-- tag (BLeaf  ..)      = 1
-- tag (BBranch .. x y) = tag x + tag y

-- Мы можем убедиться в том, что они всегда корректны, используя свои "конструкторы":
-- вместо использования BLeaf и BBranch для создания дерева
leafSize :: a -> BinaryTree Size a
leafSize = BLeaf 1

branchSize :: BinaryTree Size a -> BinaryTree Size a -> BinaryTree Size a
branchSize x y = BBranch (tag x + tag y) x y

-- 7.d Создайте дерево типа `BinaryTree Size a`, используя leafSize и branchSize (0,25 балла)
myTree :: BinaryTree Size Char
myTree = branchSize (branchSize (leafSize 'a') (leafSize 'b')) (branchSize (leafSize 'c') (branchSize (leafSize 'd') (leafSize 'e')))

-- 7.e Используя Size-аннотации, найдите n-й лист (1 балл)

getInd :: BinaryTree Size a -> Int -> a
getInd (BLeaf _ x) 1 = x
getInd (BLeaf _ _) _ = error "Leaf index out of bounds"
getInd (BBranch _ l r) n
  | n < 0 || n > tag l + tag r = error "Leaf index out of bounds"
  | n <= tag l                 = getInd l n
  | otherwise                  = getInd r (n - tag l)

-------------------------------------------------------------------------------

-- 8. A priority queue (1,5 балл)

-- Рассмотрим другую структуру данных -- очередь с приоритетом.
-- Мы представляем приоритеты в виде целых чисел и представляем их как точки во времени,
-- поэтому наименьшие из них являются более приоритетными.

type Priority = Int

-- И снова мы используем бинарное дерево. На этот раз мы представляем его как турнирное дерево,
-- так что каждое поддерево аннотируется наименьшим приоритетом, который оно содержит

-- Тогда наше дерево будет иметь тип `BinaryTree Priority a` и выглядеть так
--      2
--    /   \
--   4     2
--  / \   / \
-- 16  4  2  8
-- a   a  a / \
--         32  8
--         a   a

-- Таким образом, мы задаем v = Priority и хотим, чтобы аннотации выполняли следующие условия
-- tag (Leaf .. a)     = priority a
-- tag (Branch .. x y) = tag x `min` tag y

-- 8.a Задайте собственные конструкторы leafPrio и branchPrio (на замену BLeaf и BBranch), чтобы
--     быть уверенными в корректности аннотаций по аналогии с leafSize и branchSize (0,25 балла)
leafPrio :: Int -> a -> BinaryTree Priority a
leafPrio = BLeaf

branchPrio :: BinaryTree Priority a -> BinaryTree Priority a -> BinaryTree Priority a
branchPrio x y = BBranch (min (tag x) (tag y)) x y

-- 8.b Создайте дерево типа `BinaryTree Priority a`, используя leafPrio и branchPrio (0,25 балла)

tree :: BinaryTree Priority Char
tree = branchPrio
          (branchPrio
              (leafPrio 16 'a')
              (leafPrio 4 'b')
          )
          (branchPrio
              (leafPrio 2 'c')
              (branchPrio
                  (leafPrio 32 'd')
                  (leafPrio 8 'e')
              )
          )


-- 8.c Используя Priority-аннотации, найдите самый приоритетный элемент (1 балл)

getWinner :: BinaryTree Priority a -> a
getWinner (BLeaf _ x) = x
getWinner (BBranch _ l r)
  | tag l <= tag r = getWinner l
  | otherwise      = getWinner r

-------------------------------------------------------------------------------

-- 10. BinaryTree и Monoid (1 балла)

-- Как видим, одну и ту же древовидную структуру можно использовать для двух совершенно разных целей,
-- просто применяя разные аннотации. И распознав в аннотациях моноид, мы можем полностью унифицировать обе реализации.
-- Более того, операции getInd и getWinner -- это фактически частные случаи одной и той же функции! Какой?

-- Вспомним:
-- """
-- Таким образом, мы задаем v = Size и хотим, чтобы аннотации выполняли следующие условия
-- tag (BBranch .. x y) = tag x + tag y
-- """
-- """
-- Таким образом, мы задаем v = Priority и хотим, чтобы аннотации выполняли следующие условия
-- tag (Branch .. x y) = tag x `min` tag y
-- """

-- 10.a Обобщите эту функцию, написав инстансы `Monoid Size` и `Monoid Priority` (0,5 балла)
-- Kакую ошибку вы получили с при текущем определении Size и Priority, попытавшись создать инстансы?
-- Что нужно изменить в определении Size и Priority?

-- Ошибка: Multiple declarations of ‘Size’, Multiple declarations of ‘Priority’. Меняем имена.

newtype Size' = Size' Int deriving (Eq, Show)

instance Semigroup Size' where
  (<>) :: Size' -> Size' -> Size'
  (<>) (Size' x) (Size' y) = Size' (x + y)

instance Monoid Size' where
  mempty :: Size'
  mempty = Size' 0

newtype Priority' = Priority' Int deriving (Eq, Show)

instance Semigroup Priority' where
  (<>) :: Priority' -> Priority' -> Priority'
  (<>) (Priority' x) (Priority' y) = Priority' (x `min` y)

instance Monoid Priority' where
  mempty :: Priority'
  mempty = Priority' maxBound


-- | Теперь branchSize и branchPrio могут быть заменены на branch
--
branch :: Monoid v => BinaryTree v a -> BinaryTree v a -> BinaryTree v a
branch x y = BBranch (tag x <> tag y) x y

-- | Однако, мы не можем сделать то же с leaf. Почему?
--
-- leaf :: Monoid v => a -> BinaryTree v a
-- leaf = BLeaf mempty

-- Чтобы задать leaf унифицированным способом аналогично branch, давайте создадим класс типов Measured

class Monoid v => Measured v a where
    measure :: a -> v

-- | Написав различные инстансы этого класса для наших `BinaryTree Size a` и `BinaryTree Priority a`,
-- | мы сможем по-разному вычислять аннотацию листа по значению. Тогда
-- 
leaf :: Measured v a => a -> BinaryTree v a
leaf x = BLeaf (measure x) x

-- 10.b Напишите инстансы Measured для Size и Priority (0,5 балла)

instance Measured Size' a where
    measure :: a -> Size'
    measure _ = Size' 1

instance Measured Priority' a where
    measure :: a -> Priority'
    measure _ = Priority' maxBound

-------------------------------------------------------------------------------
