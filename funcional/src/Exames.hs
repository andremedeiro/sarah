module Exame where

import Text.Read (Read)
import System.IO
import System.Directory
import qualified Data.Text as T
import qualified Data.List as L
import Utils

data Exame = Exame{
    nome :: String,
    valor :: Double
} deriving (Show, Read)

newtype Exames = Exames {
   exames :: [(String, Exame)]
} deriving Show

exameToString:: Exame -> String
exameToString Exame { nome = n, valor = v } = n ++ ": R$ " ++ show v

examesToString :: [Exame] -> String
examesToString [] = []
examesToString (e:es) = if not (null es) then do "["++exameToString e ++"]\n" ++ examesToString es
    else do "[" ++ exameToString e ++ "]\n"

criarExame:: String -> Double -> Exame
criarExame nome valor = Exame{nome = nome, valor = valor}

addToTxt::Exame.Exame -> IO()
addToTxt exame = do
    appendFile "../db/exames.txt" (Exame.nome exame ++ ", " ++ show (Exame.valor exame) ++ "\n")
    return ()

getAllExames ::  IO()
getAllExames  = do
    handle <- openFile "../db/exames.txt" ReadMode  
    conteudo <- hGetContents handle
    let examesString = map T.unpack (T.splitOn (T.pack "\n") (T.pack conteudo))
    let exames = map formatExameToShow (filter (not . null) examesString)
    putStr (examesToString exames)
    hClose handle

findExamePeloNome:: String -> IO()
findExamePeloNome nome = do
  exames <- readFile "../db/exames.txt"
  let examesList = T.splitOn (T.pack "\n") (T.pack exames)
  let foundedExam = findExamePeloNomeRec nome examesList 0
  if (foundedExam /= "Exame nao encontrado.") then print (exameToString(formatExameToShow foundedExam))
  else print foundedExam

formatExameToShow:: String -> Exame
formatExameToShow exame = Exame {
  nome = T.unpack (head (T.splitOn (T.pack ", ") (T.pack exame))), valor = read (T.unpack (T.splitOn (T.pack ", ") (T.pack exame) !! 1))
  }

findExamePeloNomeRec:: String -> [T.Text] -> Int -> String
findExamePeloNomeRec nome examesList indice  
  | indice >= length examesList = "Exame nao encontrado."
  | toUpperCaseAndStrip (trimAllBlankSpaces nome) == toUpperCaseAndStrip (getNomeDoExame exame) = T.unpack exame
  | otherwise = findExamePeloNomeRec nome examesList (indice+1)
  where
    exame = examesList !! indice

getNomeDoExame:: T.Text -> String
getNomeDoExame exame = T.unpack (head (T.splitOn (T.pack ", ") exame))

removeExamePeloNome:: String -> IO()
removeExamePeloNome nome = do
    handle <- openFile "../db/exames.txt" ReadMode  
    tempdir <- getTemporaryDirectory  
    (tempName, tempHandle) <- openTempFile tempdir "temp"  
    contents <- hGetContents handle
    let listaComExames = lines contents
    let examesResultantes = filter (\x -> not (contains x (toUpperCaseAndStrip nome))) (map toUpperCaseAndStrip listaComExames)
    let examesFormatados = map (T.unpack . T.toTitle . T.pack) examesResultantes
    hPutStr tempHandle $ unlines examesFormatados  
    hClose handle  
    hClose tempHandle  
    removeFile "../db/exames.txt" 
    renameFile tempName "../db/exames.txt"

editaExamePeloNome:: IO()
editaExamePeloNome = do
    putStrLn "Informe o nome do exame a ser editado:"
    nome <- getLine
    putStrLn "Informe o novo nome desse exame"
    novoNome <- getLine
    putStrLn "Informe o novo valor desse exame"
    novoValor <- getLine
    removeExamePeloNome nome
    addExame novoNome (read novoValor)
    print "Exame editado com sucesso."

-- funcao para adicionar exames internamente
addExame:: String -> Double -> IO()
addExame nome valor = addToTxt(criarExame nome valor)

menuAddExame:: IO()
menuAddExame = do
    putStrLn "Informe o nome do exame"
    nome <- getLine
    putStrLn "Informe o valor do exame"
    valor <- getLine
    addExame nome (read valor)
    print "Exame adicionado com sucesso."
