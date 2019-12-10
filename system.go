package alpine_builder

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	"github.com/GehirnInc/crypt"
	_ "github.com/GehirnInc/crypt/sha256_crypt"
)

// system configurations
var systemShadow = "/data/etc/shadow"
var systemDropbearConfig = "/data/etc/dropbear/dropbear.conf"
var systemDropbearRestart = "rc-service dropbear start"
var systemShutdown = "poweroff"
var systemReboot = "reboot"

// SystemSetRootPassword update shadow file
func SystemSetRootPassword(password string) error {
	crypter := crypt.SHA256.New()

	// generate password line
	hash, err := crypter.Generate([]byte(password), nil)
	if err != nil {
		return fmt.Errorf("failed to generate hash: %w", err)
	}
	line := fmt.Sprintf("root:%s:0:0:::::", hash)

	// write shadow file
	return ioutil.WriteFile(systemShadow, []byte(line), os.ModePerm)
}

// SystemSSHEnabled returns true if server is enabled
func SystemSSHEnabled() (bool, error) {
	data, err := ioutil.ReadFile(systemDropbearConfig)
	if err != nil {
		return false, fmt.Errorf("failed to read ssh config: %w", err)
	}

	return strings.Contains(string(data), "127.0.0.1:22"), nil
}

// SystemEnableSSH server
func SystemEnableSSH() error {
	err := ioutil.WriteFile(systemDropbearConfig, []byte("DROPBEAR_OPTS=\"\""), os.ModePerm)
	if err != nil {
		return fmt.Errorf("failed to write ssh config: %w", err)
	}

	cmdSplit := strings.Split(systemDropbearRestart, " ")
	cmd := exec.Command(cmdSplit[0], cmdSplit[1:]...)
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to restart ssh server: %w", err)
	}
	return nil
}

// SystemDisableSSH server
func SystemDisableSSH() error {
	err := ioutil.WriteFile(systemDropbearConfig, []byte("DROPBEAR_OPTS=\"-p 127.0.0.1:22\""), os.ModePerm)
	if err != nil {
		return fmt.Errorf("failed to write ssh config: %w", err)
	}

	cmdSplit := strings.Split(systemDropbearRestart, " ")
	cmd := exec.Command(cmdSplit[0], cmdSplit[1:]...)
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to restart ssh server: %w", err)
	}
	return nil
}

// SystemShutdown start shutdown of system
func SystemShutdown() error {
	cmd := exec.Command(systemShutdown)
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to start system shutdown: %w", err)
	}
	return nil
}

// SystemReboot start reboot of system
func SystemReboot() error {
	cmd := exec.Command(systemReboot)
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to start system reboot: %w", err)
	}
	return nil
}
