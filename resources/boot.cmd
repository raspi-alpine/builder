# static config
setenv boot_partition_a 2
setenv boot_partition_b 3
setenv boot_limit 2
setenv boot_partition_base "/dev/mmcblk0p"


# set default values if env not set
if printenv boot_count; then 
else 
  setenv boot_count 1
fi

if printenv boot_partition; then 
  # check if valid partition a or b
  if test ${boot_partition} -ne ${boot_partition_a} && test ${boot_partition} -ne ${boot_partition_b}; then
    setenv boot_partition ${boot_partition_a}
  fi
else 
  setenv boot_partition ${boot_partition_a}
fi


# switch boot partition if boot count exceed limit
if test ${boot_count} -ge ${boot_limit}; then
  echo "!!! Boot limit exceed !!!"

  if test ${boot_partition} -eq ${boot_partition_a}; then
    setenv boot_partition ${boot_partition_b}
  else
    setenv boot_partition ${boot_partition_a}
  fi
  setenv boot_count 0

  echo "Switch active partition to ${boot_partition_base}${boot_partition}"
fi

# increase boot_count
setexpr boot_count ${boot_count} + 1

# store settings
saveenv

# load bootargs from pi boot loader
fdt addr ${fdt_addr} && fdt get value bootargs /chosen bootargs

# overwrite boot partition
setexpr bootargs sub " root=[^ ]+" " root=${boot_partition_base}${boot_partition}" "${bootargs}"

# load kernel and boot
ext4load mmc 0:${boot_partition} ${kernel_addr_r} /boot/uImage
bootm ${kernel_addr_r} - ${fdt_addr}

reset