#!/bin/sh
# Copyright © 2013 Bart Massey
# [This program is licensed under the "MIT License"]
# Please see the file COPYING in the source
# distribution of this software for license terms.
MODE=html
case $1 in
-m) MODE=mdwn ; shift ;;
esac
eval `echo $1 | \
      (IFS=/ read WDAY1 WDAY2; echo "WDAY1=$WDAY1;WDAY2=$WDAY2")`
YEAR=$2
NMONTH=$3
DAY=$4
WEEK=1
MTG=1
while true
do
  case $NMONTH in
  1) MONTH="Jan" ; MDAYS=31 ;;
  2) MONTH="Feb" ; MDAYS=28; [ `expr $YEAR % 4` -eq 0 ] && MDAYS=29 ;;
  3) MONTH="Mar" ; MDAYS=31 ;;
  4) MONTH="Apr" ; MDAYS=30 ;;
  5) MONTH="May" ; MDAYS=31 ;;
  6) MONTH="June" ; MDAYS=30 ;;
  7) MONTH="July" ; MDAYS=31 ;;
  8) MONTH="Aug" ; MDAYS=31 ;;
  9) MONTH="Sep" ; MDAYS=30 ;;
  10) MONTH="Oct" ; MDAYS=31 ;;
  11) MONTH="Nov" ; MDAYS=30 ;;
  12) MONTH="Dec" ; MDAYS=31 ;;
  esac
  case $MTG in
  1) WDAY=$WDAY1 ;;
  2) WDAY=$WDAY2 ;;
  esac
  case $MODE in
  html)
    echo "<tr><td align=\"right\">$WEEK</td><td align=\"right\">$DAY $MONTH</td><td></td></tr>"
    ;;
  mdwn)
    case $MTG in
      1) echo "### *Week $WEEK: *" ;;
    esac
    echo "  * **$WDAY $DAY $MONTH:** **"
    ;;
  esac
  case $MTG in
  1) DAY=`expr $DAY + 2`; MTG=2 ;;
  2) DAY=`expr $DAY + 5`; MTG=1 ; WEEK=`expr $WEEK + 1` ;;
  esac
  [ $WEEK -eq 11 ] && break
  if [ $DAY -gt $MDAYS ]
  then
    DAY=`expr $DAY - $MDAYS`
    NMONTH=`expr $NMONTH + 1`
    [ $NMONTH -gt 12 ] && NMONTH=1
  fi
done
