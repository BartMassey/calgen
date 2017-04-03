-- Copyright © 2013 Bart Massey
-- [This program is licensed under the "MIT License"]
-- Please see the file COPYING in the source
-- distribution of this software for license terms.

-- Generate an academic course calendar

import Control.Monad
import Data.List
import System.Console.ParseArgs
import Text.Printf

data ArgIndex = ArgM | ArgW | ArgDs | ArgYMD deriving (Ord, Eq, Show)

defaultWeeks :: Int
defaultWeeks = 10

argd :: [Arg ArgIndex]
argd = [
  Arg ArgM (Just 'm') (Just "markdown") Nothing
    "Emit Markdown instead of HTML.",
  Arg ArgW (Just 'w') (Just "weeks")
    (argDataDefaulted "weeks" ArgtypeInt defaultWeeks)
    (printf "Number of weeks in term (default %d)." defaultWeeks),
  Arg ArgDs Nothing Nothing 
    (argDataRequired "days" ArgtypeString)
    "Course meeting days separated by \"/\" (e.g. \"Mon/Wed\").",
  Arg ArgYMD Nothing Nothing 
    (argDataRequired "start-date" ArgtypeString)
    "Date of first course meeting in intl format (e.g. \"2013-01-09\")." ]
  
weekdays :: [String]
weekdays = [
  "Sun",
  "Mon",
  "Tue",
  "Wed",
  "Thu",
  "Fri",
  "Sat" ]

leap :: Int -> Bool
leap year
  | year `mod` 400 == 0 = True
  | year `mod` 100 == 0 = False
  | year `mod` 4 == 0 = True
  | otherwise = False

months :: Int -> [(String, Int)]
months year = [
  ("January", 31),
  ("February", if leap year then 29 else 28),
  ("March", 31),
  ("April", 30),
  ("May", 31),
  ("June", 30),
  ("July", 31),
  ("August", 31),
  ("September", 30),
  ("October", 31),
  ("November", 30),
  ("December", 31) ]

nameToDay :: String -> Int
nameToDay name =
  case elemIndex name weekdays of
    Just d -> d + 1
    Nothing -> error $ "unknown day name " ++ name

fields :: Eq a => a -> [a] -> [[a]]
fields _ [] = []
fields sep seed =
  foldr go [[]] seed
  where
    go x fs | x == sep = [] : fs
    go x (f : fs) = (x : f) : fs
    go _ _ = error "internal error: fields"

data DayField = DayField { 
  dfWDay :: String,
  dfWeek, dfYear, dfMonth, dfDay  :: Int } deriving Show

type DayRecord = (Int, String, (Int, Int, Int))

advanceDay :: DayRecord -> DayRecord
advanceDay (count, day, ymd) =
  let (y', m', d') = advanceYMD ymd in
  (count + 1, nextWeekday, (y', m', d'))
  where
    advanceYMD (y, m, d)
      | d + 1 > mdays && m == 12 = (y + 1, 1, 1)
      | d + 1 > mdays = (y, m + 1, 1)
      | otherwise = (y, m, d + 1)
      where
        mdays = snd (months y !! (m - 1))
    nextWeekday = weekdays !! (nameToDay day `mod` 7)

listDays :: String -> (Int, Int, Int) -> [DayField]
listDays startDayName ymd =
  unfoldr nextDay (1, startDayName, ymd)
  where
    nextDay (count, day, (y, m, d)) =
      let next = advanceDay (count, day, (y, m, d)) in
      let week = ((count - 1) `div` 7) + 1 in
      Just (DayField day week y m d, next)


buildDay :: String -> (Int, Int, Int) -> Int -> String -> DayField
buildDay startDayName ymd week dayName =
  let days = listDays startDayName ymd in
  case find today days of
    Just df -> df
    Nothing -> error "internal error: today does not exist"
  where
    today df = dfWeek df == week && dfWDay df == dayName

main :: IO ()
main = do
  argv <- parseArgsIO ArgsComplete argd
  let md = gotArg argv ArgM
  let dayNames = 
        case fields '/' $ getRequiredArg argv ArgDs of
          n@(_ : _) -> n
          _ -> error "empty days list"
  let dateStr = getRequiredArg argv ArgYMD
  let date = 
        case map read $ fields '-' dateStr  of
          [y, m, d] -> (y, m, d)
          _ -> error $ "unknown date " ++ dateStr
  let nweeks = getRequiredArg argv ArgW
  when (not md) (putStrLn "<table>\n<tr><th>W</th><th>Date</th><th>Topic</th></tr>")
  putStr $ unlines $ concatMap (buildDays md date dayNames) [1..nweeks]
  when (not md) (putStrLn "</table>")
  where
    buildDays md date dayNames week =
      map (formatDay md . buildDay (head dayNames) date week) dayNames
      where
        yearName df =
          fst $ months (dfYear df) !! (dfMonth df - 1)
        formatDay False df =
          printf "<tr><td align=\"right\">%d</td><td align=\"right\">%d %s</td><td>TBA</td></tr>"
            (dfWeek df) (dfDay df) (yearName df)
        formatDay True df =
          let w = if dfWDay df == head dayNames 
                  then printf "### *Week %d:*\n" (dfWeek df)
                  else "" in
          printf "%s  * **%s %d %s:** *TBA*"
            w (dfWDay df) (dfDay df) (yearName df)
