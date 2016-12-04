###########################################################################
##                                                                       ##
##                     Raspbian Jessie Setup Script                      ##
##                                                                       ##
## Creation:    17.08.2013                                               ##
## Last Update: 01.05.2016                                               ##
##                                                                       ##
## Copyright (c) 2013-2016 by Georg Kainzbauer <http://www.gtkdb.de>     ##
##                                                                       ##
## This program is free software; you can redistribute it and/or modify  ##
## it under the terms of the GNU General Public License as published by  ##
## the Free Software Foundation; either version 2 of the License, or     ##
## (at your option) any later version.                                   ##
##                                                                       ##
###########################################################################
#!/bin/bash

###########################################################################
## Change keyboard layout                                                ##
###########################################################################

if [ ! $(cat /etc/default/keyboard | egrep "^XKBLAYOUT=\"gb\"" >/dev/null) ]; then
  echo
  echo "------------------------------------------------------"
  echo "Change keyboard layout"
  echo "------------------------------------------------------"

  sed -i 's/XKBLAYOUT=\"gb\"/XKBLAYOUT=\"de\"/g' /etc/default/keyboard
  sed -i 's/XKBOPTIONS=\"\"/XKBOPTIONS=\"terminate:ctrl_alt_bksp\"/g' /etc/default/keyboard
  sed -i 's/XKBOPTIONS=\"lv3:ralt_switch\"/XKBOPTIONS=\"lv3:ralt_switch terminate:ctrl_alt_bksp\"/g' /etc/default/keyboard
  invoke-rc.d keyboard-setup start

  echo
  echo "Done"
fi

###########################################################################
## Change system locales                                                 ##
###########################################################################

if [ ! $(cat /etc/locale.gen | egrep "^# de_DE.UTF-8 UTF-8" >/dev/null) ]; then
  echo
  echo "------------------------------------------------------"
  echo "Change system locales"
  echo "------------------------------------------------------"

  sed -i 's/^# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' /etc/locale.gen
  locale-gen

  echo
  echo "Done"
fi

###########################################################################
## Change default locale                                                 ##
###########################################################################

if [ ! $(cat /etc/default/locale | egrep "^LANG=en_GB.UTF-8" >/dev/null) ]; then
  echo
  echo "------------------------------------------------------"
  echo "Change default locale"
  echo "------------------------------------------------------"

  update-locale LANG=de_DE.UTF-8

  echo
  echo "Done"
fi

###########################################################################
## Change system timezone                                                ##
###########################################################################

if [ ! $(cat /etc/timezone | egrep "^Etc/UTC" >/dev/null) ]; then
  echo
  echo "------------------------------------------------------"
  echo "Change system timezone"
  echo "------------------------------------------------------"

  sed -i 's/Etc\/UTC/Europe\/Berlin/g' /etc/timezone
  cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime

  echo
  echo "Done"
fi

###########################################################################
## Resize root partition                                                 ##
###########################################################################

ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
PART_NUM=${ROOT_PART#mmcblk0p}
PART_START=$(parted /dev/mmcblk0 -ms unit s p | egrep "^${PART_NUM}" | cut -d: -f2 | sed 's/s//g')
PART_END=$(parted /dev/mmcblk0 -ms unit s p | egrep "^${PART_NUM}" | cut -d: -f3 | sed 's/s//g')

[ "${PART_START}" ] || exit 1
[ "${PART_END}" ] || exit 1

if [ ${PART_END} -eq 8060927 -o \
     ${PART_END} -eq 2850815 -o \
     ${PART_END} -eq 7878655 -o \
     ${PART_END} -eq 2658303 \
   ]; then
  echo
  echo "------------------------------------------------------"
  echo "Resize root partition"
  echo "------------------------------------------------------"

  fdisk /dev/mmcblk0 <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF

  echo
  echo "Done"
fi

if [ ! -f /etc/init.d/resize2fs_once ]; then
  echo
  echo "------------------------------------------------------"
  echo "Create init script for filesystem resize"
  echo "------------------------------------------------------"

  cat <<\EOF > /etc/init.d/resize2fs_once
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start:     3
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/mmcblk0p2 &&
    update-rc.d resize2fs_once remove &&
    rm /etc/init.d/resize2fs_once &&
    log_end_msg \$?
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF

  chmod +x /etc/init.d/resize2fs_once
  update-rc.d resize2fs_once defaults

  echo
  echo "Done"
fi

###########################################################################
## Restart system                                                        ##
###########################################################################

echo
echo "------------------------------------------------------"
echo "Restart system"
echo "------------------------------------------------------"
shutdown -r now
