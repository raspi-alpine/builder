package alpine_builder

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func init() {
	networkConfig = "test_interfaces"
}

func TestGetNetworkInfo(t *testing.T) {
	ass := assert.New(t)

	// file does not exist
	_, err := GetNetworkInfo()
	ass.EqualError(err, "failed to open network config: open test_interfaces: no such file or directory")

	// invalid config file
	ass.NoError(ioutil.WriteFile(networkConfig, []byte(""), os.ModePerm))
	_, err = GetNetworkInfo()
	ass.EqualError(err, "invalid network config")

	// dynamic config
	ass.NoError(ioutil.WriteFile(networkConfig, []byte(`auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp`), os.ModePerm))
	info, err := GetNetworkInfo()
	ass.NoError(err)
	ass.False(info.IsStatic)

	// static config
	ass.NoError(ioutil.WriteFile(networkConfig, []byte(`auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 1.2.3.4
  netmask 255.255.255.0
  gateway 4.3.2.1`), os.ModePerm))
	info, err = GetNetworkInfo()
	ass.NoError(err)
	ass.True(info.IsStatic)
	ass.Equal("1.2.3.4", info.Address)
	ass.Equal("255.255.255.0", info.Netmask)
	ass.Equal("4.3.2.1", info.Gateway)

	_ = os.Remove(networkConfig)
}

func TestNetworkEnableDHCP(t *testing.T) {
	ass := assert.New(t)

	// file does not exist
	_, err := GetNetworkInfo()
	ass.EqualError(err, "failed to open network config: open test_interfaces: no such file or directory")

	ass.NoError(ioutil.WriteFile(networkConfig, []byte(`auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 1.2.3.4
  netmask 255.255.255.0
  gateway 4.3.2.1`), os.ModePerm))

	ass.NoError(NetworkEnableDHCP())

	data, err := ioutil.ReadFile(networkConfig)
	ass.NoError(err)

	ass.Equal(`auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
`, string(data))

	_ = os.Remove(networkConfig)
}

func TestNetworkSetStatic(t *testing.T) {
	ass := assert.New(t)

	// file does not exist
	_, err := GetNetworkInfo()
	ass.EqualError(err, "failed to open network config: open test_interfaces: no such file or directory")

	ass.NoError(ioutil.WriteFile(networkConfig, []byte(`auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp`), os.ModePerm))

	ass.NoError(NetworkSetStatic("1.2.3.4", "255.255.255.0", "4.3.2.1"))

	data, err := ioutil.ReadFile(networkConfig)
	ass.NoError(err)

	ass.Equal(`auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 1.2.3.4
  netmask 255.255.255.0
  gateway 4.3.2.1
`, string(data))

	_ = os.Remove(networkConfig)
}
