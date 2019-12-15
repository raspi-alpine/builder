package alpine_builder

import (
	"compress/gzip"
	"encoding/binary"
	"errors"
	"fmt"
	"hash/crc32"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
)

var mountCommand = "mount"
var ubootFile = "/uboot/uboot.dat"
var ubootRemountRW = []string{"-o", "remount,rw", "/uboot"}
var ubootRemountRO = []string{"-o", "remount,ro", "/uboot"}

var rootPartitionA = "/dev/mmcblk0p2"
var rootPartitionB = "/dev/mmcblk0p3"

// loadUbootDat file to byte array
func loadUbootDat() ([]byte, error) {
	defaultData := make([]byte, 1024)
	defaultData[0] = 1 // file version
	defaultData[1] = 0 // boot counter
	defaultData[2] = 2 // boot partition  A=2, B=3

	data, err := ioutil.ReadFile(ubootFile)
	if err != nil {
		return defaultData, fmt.Errorf("failed to open file: %w", err)
	}

	// invalid dat file?
	if len(data) < 1024 {
		return defaultData, errors.New("invalid dat file -> fallback to defaults")
	}

	crc := binary.LittleEndian.Uint32(data[1020:])
	bla := crc32.ChecksumIEEE(data[:1020])
	if crc != bla {
		return defaultData, errors.New("invalid crc -> fallback to defaults")
	}

	return data, nil
}

// saveUbootDat from byte array
func saveUbootDat(data []byte) error {
	// update crc
	binary.LittleEndian.PutUint32(data[1020:],
		crc32.ChecksumIEEE(data[:1020]))

	// remount boot partition - writable
	cmd := exec.Command(mountCommand, ubootRemountRW...)
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to remount RW: %w", err)
	}

	// update uboot dat file
	err = ioutil.WriteFile(ubootFile, data[:1024], os.ModePerm)
	if err != nil {
		return fmt.Errorf("failed write uboot dat: %w", err)
	}

	// remount boot partition - readonly
	cmd = exec.Command(mountCommand, ubootRemountRO...)
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to remount RO: %w", err)
	}
	return nil
}

// UBootResetCounter to 0
func UBootResetCounter() error {
	data, _ := loadUbootDat()
	data[1] = 0
	return saveUbootDat(data)
}

// UBootActive returns the active partition. A=2, B=3
func UBootActive() uint8 {
	data, _ := loadUbootDat()
	return data[2]
}

// UBootSetActive sets the active partition. A=2, B=3
func UBootSetActive(active uint8) error {
	data, _ := loadUbootDat()
	if active == 2 {
		data[2] = 2
	} else {
		data[2] = 3
	}
	return saveUbootDat(data)
}

// UpdateSystem with the given image
func UpdateSystem(image string) error {
	data, _ := loadUbootDat()
	rootPart := rootPartitionA
	if data[2] == 2 {
		rootPart = rootPartitionB
	}

	// open image file
	inFile, err := os.Open(image)
	if err != nil {
		log.Fatal(err)
	}
	defer inFile.Close()

	// decompress image
	inDecompress, err := gzip.NewReader(inFile)
	if err != nil {
		log.Fatal(err)
	}
	defer inDecompress.Close()

	// open root partition
	out, err := os.OpenFile(rootPart,
		os.O_WRONLY|os.O_TRUNC|os.O_SYNC, os.ModePerm)
	if err != nil {
		log.Fatal(err)
	}
	defer out.Close()

	// write update
	_, err = io.Copy(out, inDecompress)
	if err != nil {
		log.Fatal(err)
	}

	// switch active partition
	if data[2] == 2 {
		return UBootSetActive(3)
	} else {
		return UBootSetActive(2)
	}
}
