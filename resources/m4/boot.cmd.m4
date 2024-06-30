# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# static config
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
setenv boot_partition_a 0x02
setenv boot_partition_b 0x03
setenv boot_limit 0x02

setenv addr_version 0x10000
setenv addr_boot_counter 0x10001
setenv addr_boot_partition 0x10002


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# check for mmc/usb
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
version
if test -e mmc 0:1 boot.scr; then
  setenv boot_partition_base "/dev/mmcblk0p"
  setenv boot_dev mmc
else
  setenv boot_partition_base "/dev/sda"
  setenv boot_dev usb
fi
echo "booting from: ${boot_dev}"


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# load persistence values
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# clear memory
mw.b 0x10000 0 0x404

# load saved boot data file /uboot/uboot.dat
fatload ${boot_dev} 0:1 0x10000 uboot.dat 0x400

# check CRC
crc32 0x10000 0x3FC 0x10400
if itest *0x103FC -ne *0x10400; then 
  echo "invalid CRC -> fallback to default values"

  # default values
  mw.b ${addr_version} 0x01
  mw.b ${addr_boot_counter} 0x00
  mw.b ${addr_boot_partition} ${boot_partition_a}
fi

setexpr.b boot_counter *${addr_boot_counter}
setexpr.b boot_partition *${addr_boot_partition}
echo "> boot counter:   ${boot_counter}"
echo "> boot partition: ${boot_partition}"

# ensure boot partition is valid
if itest.b *${addr_boot_partition} -ne ${boot_partition_a} && itest.b *${addr_boot_partition} -ne ${boot_partition_b}; then
  echo "switched to valid partition -> A"
  mw.b ${addr_boot_partition} ${boot_partition_a}
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# fallback boot
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo "Check fallback boot"
# switch boot partition if boot count exceed limit
if itest.b *${addr_boot_counter} -ge ${boot_limit}; then
  echo "!!! Boot limit exceed !!!"

  if itest.b *${addr_boot_partition} -eq ${boot_partition_a}; then
    mw.b ${addr_boot_partition} ${boot_partition_b}
  else
    mw.b ${addr_boot_partition} ${boot_partition_a}
  fi
  mw.b ${addr_boot_counter} 0

  setexpr.b boot_partition *${addr_boot_partition}
  echo "Switch active partition to ${boot_partition_base}${boot_partition}"
else
  # increase boot_count
  setexpr.b tmp *${addr_boot_counter} + 1
  mw.b ${addr_boot_counter} ${tmp}

  setexpr.b boot_partition *${addr_boot_partition}
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# store persistence values
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# overwrite version
mw.b 0x10000 0x01

# calculate crc
crc32 0x10000 0x3FC 0x103FC

# save boot data to /uboot/uboot.dat
fatwrite ${boot_dev} 0:1 0x10000 uboot.dat 0x400


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# select kernel
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo "selecting kernel"
setenv boot_kernel "/boot/vmlinuz-rpi"

ifelse(len(xOLDKERNEL), 0, `# new kernel names used',

`# only if new pi a new kernel is required
# https://www.raspberrypi.org/documentation/hardware/raspberrypi/revision-codes/README.md
setexpr board_new_pi ${board_revision} \& 0x800000
if test ${board_new_pi} > 0; then
  echo "new board"
  # get cpu id from revision
  setexpr board_cpu ${board_revision} \& 0xF000
  
  # BCM2836 (pi2)
  if itest.l ${board_cpu} -eq 0x1000; then
    setenv boot_kernel "/boot/vmlinuz-rpi2"
    echo "pi2 detected"
  # BCM2837 (pi3)
  elif itest.l ${board_cpu} -eq 0x2000; then
    setenv boot_kernel "/boot/vmlinuz-rpi4"
    echo "pi3 detected"
  # BCM2711 (pi4)
  elif itest.l ${board_cpu} -ge 0x3000; then
    setenv boot_kernel "/boot/vmlinuz-rpi4"
    echo "pi4 or greater detected"
  fi
else
  echo "old board"
fi')
echo "Load kernel ${boot_kernel}"


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# boot
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# load bootargs from pi boot loader
fdt addr ${fdt_addr} && fdt get value bootargs /chosen bootargs

# overwrite boot partition
setexpr bootargs sub " root=[^ ]+" " root=${boot_partition_base}${boot_partition}" "${bootargs}"

# load kernel and boot
ext4load ${boot_dev} 0:${boot_partition} ${kernel_addr_r} ${boot_kernel}

# 32bit does not have booti
booti ${kernel_addr_r} - ${fdt_addr}
bootz ${kernel_addr_r} - ${fdt_addr}

sleep 3
reset
