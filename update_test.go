package alpine_builder

import (
	"bytes"
	"compress/gzip"
	"crypto/rand"
	"encoding/binary"
	"io"
	"io/ioutil"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func init() {
	ubootFile = "test_uboot"
	mountCommand = "true"
	rootPartitionA = "test_rootA"
	rootPartitionB = "test_rootB"
}

func TestLoadUbootDat(t *testing.T) {
	ass := assert.New(t)

	defer func() {
		_ = os.Remove(ubootFile)
	}()

	// file missing
	data, err := loadUbootDat()
	ass.EqualError(err, "failed to open file: open test_uboot: no such file or directory")
	ass.Equal([]byte{1, 0, 2}, data[:3])

	// file with invalid data
	ass.NoError(ioutil.WriteFile(ubootFile, []byte{}, os.ModePerm))

	data, err = loadUbootDat()
	ass.EqualError(err, "invalid dat file -> fallback to defaults")
	ass.Equal([]byte{1, 0, 2}, data[:3])

	// file with invalid CRC
	testData := make([]byte, 1024)
	testData[0] = 1
	testData[1] = 2
	testData[2] = 2

	ass.NoError(ioutil.WriteFile(ubootFile, testData, os.ModePerm))
	data, err = loadUbootDat()
	ass.EqualError(err, "invalid crc -> fallback to defaults")
	ass.Equal([]byte{1, 0, 2}, data[:3])

	// file with valid CRC
	binary.LittleEndian.PutUint32(testData[1020:], 0x982E8B7A)

	ass.NoError(ioutil.WriteFile(ubootFile, testData, os.ModePerm))
	data, err = loadUbootDat()
	ass.NoError(err)
	ass.Equal(testData, data)
}

func TestSaveUbootDat(t *testing.T) {
	ass := assert.New(t)

	defer func() {
		_ = os.Remove(ubootFile)
	}()

	testData := make([]byte, 1024)
	testData[0] = 1
	testData[1] = 2
	testData[2] = 2
	ass.NoError(saveUbootDat(testData))

	binary.LittleEndian.PutUint32(testData[1020:], 0x982E8B7A)

	data, err := ioutil.ReadFile(ubootFile)
	ass.NoError(err)
	ass.Equal(testData, data)
}

func TestUBootResetCounter(t *testing.T) {
	ass := assert.New(t)

	defer func() {
		_ = os.Remove(ubootFile)
	}()

	// write test file
	testData := make([]byte, 1024)
	testData[0] = 1
	testData[1] = 2
	testData[2] = 2
	binary.LittleEndian.PutUint32(testData[1020:], 0x982E8B7A)
	ass.NoError(ioutil.WriteFile(ubootFile, testData, os.ModePerm))

	ass.NoError(UBootResetCounter())

	data, err := ioutil.ReadFile(ubootFile)
	ass.NoError(err)
	ass.Zero(data[1])
}

func TestUBootActive(t *testing.T) {
	ass := assert.New(t)

	defer func() {
		_ = os.Remove(ubootFile)
	}()

	// write test file
	testData := make([]byte, 1024)
	testData[0] = 1
	testData[1] = 2
	testData[2] = 2
	binary.LittleEndian.PutUint32(testData[1020:], 0x982E8B7A)
	ass.NoError(ioutil.WriteFile(ubootFile, testData, os.ModePerm))

	ass.Equal(uint8(2), UBootActive())
}

func TestUBootSetActive(t *testing.T) {
	ass := assert.New(t)

	defer func() {
		_ = os.Remove(ubootFile)
	}()

	// write test file
	testData := make([]byte, 1024)
	testData[0] = 1
	testData[1] = 2
	testData[2] = 2
	binary.LittleEndian.PutUint32(testData[1020:], 0x982E8B7A)
	ass.NoError(ioutil.WriteFile(ubootFile, testData, os.ModePerm))

	ass.NoError(UBootSetActive(1))

	data, err := ioutil.ReadFile(ubootFile)
	ass.NoError(err)
	ass.Equal(uint8(3), data[2])
}

func TestUpdateSystem(t *testing.T) {
	ass := assert.New(t)

	defer func() {
		_ = os.Remove("test_image.gz")
		_ = os.Remove(ubootFile)
		_ = os.Remove(rootPartitionA)
		_ = os.Remove(rootPartitionB)
	}()

	// test uboot file
	testData := make([]byte, 1024)
	testData[0] = 1
	testData[1] = 2
	testData[2] = 2
	binary.LittleEndian.PutUint32(testData[1020:], 0x982E8B7A)
	ass.NoError(ioutil.WriteFile(ubootFile, testData, os.ModePerm))

	// generate test image content
	size := int64(1024 * 1024 * 5)
	testImgData := make([]byte, size)
	buffer := bytes.NewBuffer(testImgData)
	_, err := io.CopyN(buffer, rand.Reader, size)
	ass.NoError(err)

	// write compressed image file
	file, err := os.Create("test_image.gz")
	ass.NoError(err)
	gzipWriter := gzip.NewWriter(file)
	_, err = gzipWriter.Write(testImgData)
	ass.NoError(err)
	ass.NoError(gzipWriter.Close())
	ass.NoError(file.Close())

	ass.NoError(ioutil.WriteFile(rootPartitionB, nil, os.ModePerm))
	ass.NoError(UpdateSystem("test_image.gz"))

	// check if image was written
	data, err := ioutil.ReadFile(rootPartitionB)
	ass.NoError(err)
	ass.Equal(testImgData, data)

	// check if uboot dat was updated
	data, err = ioutil.ReadFile(ubootFile)
	ass.NoError(err)
	ass.Equal(uint8(3), data[2])
}
