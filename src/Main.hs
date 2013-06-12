{-# LANGUAGE OverloadedStrings #-}

module Main where

------------------------------------------------------------------------------
import           Control.Applicative
import           Control.Concurrent
import           Control.Concurrent.MVar
import           Data.Attoparsec.ByteString
import qualified Data.Text                  as T
import           Network.URI
import           System.Environment         (getArgs)
import           System.INotify
import           System.IO
import           System.Process             (system)
------------------------------------------------------------------------------

main = do
  file:[] <- getArgs
  offset  <- withFile file ReadMode $ (\h -> hSeek h SeekFromEnd 0 >> hTell h)
  n       <- initINotify
  m       <- newMVar offset
  desc    <- addWatch n [Modify] file (updateiptables m file)
  stop    <- getLine
  removeWatch desc
  return ()

updateiptables :: MVar Integer -> FilePath -> Event -> IO ()
updateiptables m fp (Modified _ _) = do
  off <- takeMVar m
  hdl <- openFile fp ReadMode
  hSeek hdl AbsoluteSeek off
  xs  <- hGetContents hdl
  putMVar m $ off + fromIntegral (length xs)
  processLogLine (T.pack xs)
  hClose hdl
  return ()

processLogLine xs = do
  let gid = parseGid xs
      ip  = parseSrcIp xs
  case (gid, ip) of
    (115, Just x) -> blacklist x >> return ()
    _             -> return ()

blacklist ip = system . T.unpack $ "iptables -I FORWARD -i eth0 -s " `T.append` ip `T.append` " -j REJECT"

parseSrcIp :: T.Text -> Maybe T.Text
parseSrcIp line = let ipstr = extractip . extractsrcsection . extractipsection $ line in
  case (isIPv4address . T.unpack $ ipstr) of
    True  -> Just ipstr
    False -> Nothing
  where extractipsection  = Prelude.head . Prelude.drop 1 . T.splitOn "}" . Prelude.head
                          . Prelude.drop 2 . T.splitOn (T.pack "[**]")
        extractsrcsection = Prelude.head . Prelude.take 1 . T.words
        extractip         = Prelude.head . T.split (== ':')

parseGid :: T.Text -> Int
parseGid = readInt . extractGid . Prelude.take 1 . T.words . Prelude.head . Prelude.drop 1 . T.splitOn (T.pack "[**]")
  where extractGid = T.drop 1 . Prelude.head . T.split (== ':') . Prelude.head
        readInt    = read . T.unpack

{-| Example Rule: (note that gid should be 115)

alert tcp $E any -> $H 21 (msg:"ET EXPLOIT VSFTPD Backdoor User Login Smiley"; flow:established,to_server; content:"USER "; depth:5; content:"|3a 29|"; distance:0; classtype:attempted-admin; gid:115; sid:2013188; rev:4;)

-}

-- Example "Snort Fast Log" lines
logline :: T.Text
logline = "06/12-15:55:12.377292  [**] [155:2013188:4] ET EXPLOIT VSFTPD Backdoor User Login Smiley [**] [Classification: Attempted Administrator Privilege Gain] [Priority: 1] {TCP} 192.168.1.213:53573 -> 192.168.4.2:21"

logline' :: T.Text
logline' = "06/12-17:15:05.575953  [**] [115:9999999:1] PHPSESSID Detected [**] [Classification: Web Application Attack] [Priority: 1] {TCP} 192.168.1.213:36016 -> 192.168.4.2:80"

{-| ghci tests:

> (parseGid logline, parseSrcIp logline)
(155,Just "192.168.1.213")
> (parseGid logline', parseSrcIp logline')
(115,Just "192.168.1.213")

-}
