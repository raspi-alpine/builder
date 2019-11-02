fdt addr ${fdt_addr} && fdt get value bootargs /chosen bootargs
ext4load mmc 0:2 ${kernel_addr_r} /boot/uImage
bootm ${kernel_addr_r} - ${fdt_addr}
