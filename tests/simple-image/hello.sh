#!/bin/sh

echo "hello world!"
# Countdown for one minute before poweroff
i=30
while [ $i -gt 0 ]; do
  printf "\rPowering off in %2d seconds..." "$i"
  sleep 1
  i=$((i - 1))
done
echo ""
poweroff
