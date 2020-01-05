package alpine_builder

import (
	"io/ioutil"
	"os"
	"path"
	"strings"
	"testing"

	"github.com/GehirnInc/crypt"
	_ "github.com/GehirnInc/crypt/sha256_crypt"
	"github.com/stretchr/testify/assert"
)

func init() {
	systemShadow = "test_shadow"
	systemDropbearConfig = "test_dropbear"
	systemDropbearRestart = "restart_dropbear_command"
	systemReboot = "reboot_command"
	systemShutdown = "shutdown_command"

	systemZoneinfo = "zoneinfo/"
	systemLocaltimeFile = "test_localtime"
}

func TestSystemSetRootPassword(t *testing.T) {
	ass := assert.New(t)

	ass.NoError(SystemSetRootPassword("password"))

	data, err := ioutil.ReadFile(systemShadow)
	ass.NoError(err)
	hash := strings.Split(string(data), ":")[1]

	crypter := crypt.SHA256.New()
	ass.NoError(crypter.Verify(hash, []byte("password")))

	_ = os.Remove(systemShadow)
}

func TestSystemSSHEnabled(t *testing.T) {
	ass := assert.New(t)

	_, err := SystemSSHEnabled()
	ass.EqualError(err, "failed to read ssh config: open test_dropbear: no such file or directory")

	ass.NoError(ioutil.WriteFile(systemDropbearConfig, []byte("test"), os.ModePerm))
	value, err := SystemSSHEnabled()
	ass.NoError(err)
	ass.True(value)

	ass.NoError(ioutil.WriteFile(systemDropbearConfig, []byte("DROPBEAR_OPTS=\"-p 127.0.0.1:22\""), os.ModePerm))
	value, err = SystemSSHEnabled()
	ass.NoError(err)
	ass.False(value)

	_ = os.Remove(systemDropbearConfig)
}

func TestSystemEnableSSH(t *testing.T) {
	ass := assert.New(t)

	ass.EqualError(SystemEnableSSH(), "failed to restart ssh server: exec: \"restart_dropbear_command\": executable file not found in $PATH")

	data, err := ioutil.ReadFile(systemDropbearConfig)
	ass.NoError(err)

	ass.Equal("DROPBEAR_OPTS=\"\"", string(data))

	_ = os.Remove(systemDropbearConfig)
}

func TestSystemDisableSSH(t *testing.T) {
	ass := assert.New(t)

	ass.EqualError(SystemDisableSSH(), "failed to restart ssh server: exec: \"restart_dropbear_command\": executable file not found in $PATH")

	data, err := ioutil.ReadFile(systemDropbearConfig)
	ass.NoError(err)

	ass.Equal("DROPBEAR_OPTS=\"-p 127.0.0.1:22\"", string(data))

	_ = os.Remove(systemDropbearConfig)
}

func TestSystemReboot(t *testing.T) {
	ass := assert.New(t)

	ass.EqualError(SystemReboot(),
		"failed to start system reboot: exec: \"reboot_command\": executable file not found in $PATH")
}

func TestSystemShutdown(t *testing.T) {
	ass := assert.New(t)

	ass.EqualError(SystemShutdown(),
		"failed to start system shutdown: exec: \"shutdown_command\": executable file not found in $PATH")
}

var zoneTab = `
#
#country-
#codes	coordinates	TZ	comments
AD	+4230+00131	Europe/Andorra
AE,OM	+2518+05518	Asia/Dubai
AQ	-6617+11031	Antarctica/Casey	Casey
`

func TestSystemListTimeZones(t *testing.T) {
	ass := assert.New(t)

	_, err := SystemListTimeZones()
	ass.EqualError(err, "open zoneinfo/zone1970.tab: no such file or directory")

	ass.NoError(os.MkdirAll(systemZoneinfo, os.ModePerm))
	testZoneTab := path.Join(systemZoneinfo, "zone1970.tab")
	ass.NoError(ioutil.WriteFile(testZoneTab, []byte(zoneTab), os.ModePerm))

	zones, err := SystemListTimeZones()
	ass.NoError(err)
	ass.Equal([]string{
		"Antarctica/Casey",
		"Asia/Dubai",
		"Etc/UTC",
		"Europe/Andorra",
	}, zones)

	ass.NoError(os.Remove(testZoneTab))
	ass.NoError(os.Remove(systemZoneinfo))
}

func TestSystemSetTimeZone(t *testing.T) {
	ass := assert.New(t)

	ass.NoError(os.MkdirAll(systemZoneinfo, os.ModePerm))
	testZone := path.Join(systemZoneinfo, "test")
	ass.NoError(ioutil.WriteFile(testZone, []byte(""), os.ModePerm))

	ass.EqualError(SystemSetTimeZone("test2"),
		"invalid time zone given: test2")

	ass.NoError(SystemSetTimeZone("test"))
	ass.NoError(SystemSetTimeZone("test"))

	ass.NoError(os.Remove(systemLocaltimeFile))
	ass.NoError(os.Remove(testZone))
	ass.NoError(os.Remove(systemZoneinfo))
}

func TestSystemGetTimeZone(t *testing.T) {
	ass := assert.New(t)

	ass.NoError(os.MkdirAll(systemZoneinfo, os.ModePerm))
	testZone := path.Join(systemZoneinfo, "test")
	ass.NoError(ioutil.WriteFile(testZone, []byte(""), os.ModePerm))

	_, err := SystemGetTimeZone()
	ass.EqualError(err, "failed to get local time zone")

	ass.NoError(os.Symlink(path.Join(systemZoneinfo, "test"), systemLocaltimeFile))

	zone, err := SystemGetTimeZone()
	ass.NoError(err)
	ass.Equal("test", zone)

	ass.NoError(os.Remove(systemLocaltimeFile))
	ass.NoError(os.Remove(testZone))
	ass.NoError(os.Remove(systemZoneinfo))
}
