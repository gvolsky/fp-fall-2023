module Main where

-- REPL (1,5 балла)

-- Реализуйте скрипт, который при запуске в бесконечном цикле считывает с консоли пользователський ввод.
-- Каждая введённая строка должна дублироваться в stdout (терминал) и в файл с названием text_copy_<N>.log,
-- где N — номер файла с логом. Нумерация N начинается с 0.

-- Если колчиество записанных строк в файл text_copy_<N>.log достигло 1000,
-- то должен создаваться файл text_copy_<N+1>.log.
-- Запись последующих строк должна производиться в него, а хэндл файла text_copy_<N>.log должен быть закрыт.

import System.IO
import Control.Monad

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    createLog 0

createLog :: Int -> IO ()
createLog logNumber = do
    let logFileName = "text_copy_" ++ show logNumber ++ ".log"
    writeFile logFileName ""

    let loop = do 
          putStr "> "
          input <- getLine
          putStrLn input
          appendFile logFileName (input ++ "\n")
          linesCount <- countLines logFileName
          if linesCount >= 1000
              then createLog (logNumber + 1)
              else loop
    loop

countLines :: FilePath -> IO Int
countLines file = length . lines <$> readFile file
