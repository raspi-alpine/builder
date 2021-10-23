image sdcard.img {
  hdimage {
  }
  partition boot {
    partition-type = 0xC
    bootable = "true"
    image = "boot.vfat"
  }
  partition rootfs_a {
    partition-type = 0x83
    image = "rootfs.ext4"
    size = xSIZE_ROOT
  }
  partition rootfs_b {
    partition-type = 0x83
    image = "rootfs.ext4"
    size = xSIZE_ROOT
  }
  partition datafs {
    partition-type = 0x83
    image = "datafs.ext4"
  }
}