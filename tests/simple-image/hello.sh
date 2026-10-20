#!/bin/sh

# OpenRC's "local" service sends the output of *.start scripts to /dev/null
# unless it is running verbosely, so write to the console directly to make
# the test output visible. The QEMU test in CI greps the console output for
# "hello world!".
echo "hello world!" >/dev/console

# Countdown for one minute before poweroff
i=30
while [ $i -gt 0 ]; do
  printf "\rPowering off in %2d seconds..." "$i"
  sleep 1
  i=$((i - 1))
done
echo ""
poweroff
