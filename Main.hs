{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Data.Maybe
import           Options.Applicative
import           Turtle              hiding (date)

volume = do
  m <- mut
  if m == "yes"
    then pr <$> "muted"
    else pr <$> vol

  where vol = inshell "awk '{print $5}'"
              . limit 1
              . grep (has "Volume")
              . inshell "pactl list sinks"
              $ empty
        mut = inshell "awk '{print $2}'"
              . grep (has "Mute")
              . inshell "pactl list sinks"
              $ empty
        pr = format ("Volume: " % s)

pactl cmd arg = do
  sinkId <- inshell "cut -f 1"
            . grep (has "RUNNING")
            . inshell "pactl list sinks short"
            $ empty
  inproc "pactl" [cmd, sinkId, arg] empty

setVolume = pactl "set-sink-volume"

setMute = pactl "set-sink-mute"

raiseVolume = setVolume "+5%" <|> volume

lowerVolume = setVolume "-5%" <|> volume

toggleMute = setMute "toggle" <|> volume

backlight = format ("Backlight: " % s % "%")
            . fromMaybe "0"
            . listToMaybe
            . match (prefix (plus digit))
            <$> inshell "xbacklight" empty

setBacklight arg = inproc "xbacklight" [arg] empty

increaseBacklight = setBacklight "+5%" <|> backlight

decreaseBacklight = setBacklight "-5%" <|> backlight

date = inshell "date +'%H:%M - %a %d %b %Y'" empty

battery = format ("Battery: " % s % "%")
          <$> (inshell "cut -d = -f 2"
               . grep ("POWER_SUPPLY_CAPACITY=" <> plus digit)
               $ input "/sys/class/power_supply/BAT1/uevent")

opts = subparser
       $ cmd "mute" toggleMute
       <> cmd "bat" battery
       <> cmd "date" date
       <> subcmd "vol" desc (subparser
                             $ cmd "inc" raiseVolume
                             <> cmd "dec" lowerVolume
                             <> cmd "show" volume)
       <> subcmd "bl" desc (subparser
                            $ cmd "inc" increaseBacklight
                            <> cmd "dec" decreaseBacklight
                            <> cmd "show" backlight)
  where desc = progDesc "inc | dec | show"
        cmd c a = command c (info (pure $ stdout a) idm)
        subcmd c d p = command c (info p d)


main = join $ execParser (info opts (progDesc "mute | bat | date | vol | bl"))
