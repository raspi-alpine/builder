package alpine_builder

import (
	"io/ioutil"
	"os"
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
	ass.False(value)

	ass.NoError(ioutil.WriteFile(systemDropbearConfig, []byte("DROPBEAR_OPTS=\"-p 127.0.0.1:22\""), os.ModePerm))
	value, err = SystemSSHEnabled()
	ass.NoError(err)
	ass.True(value)

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
