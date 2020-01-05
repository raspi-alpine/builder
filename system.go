package alpine_builder

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"github.com/GehirnInc/crypt"
	_ "github.com/GehirnInc/crypt/sha256_crypt"
)

// system configurations
var systemShadow = "/data/etc/shadow"
var systemDropbearConfig = "/data/etc/dropbear/dropbear.conf"
var systemDropbearRestart = "rc-service dropbear restart"
var systemShutdown = "poweroff"
var systemReboot = "reboot"
var systemZoneinfo = "/usr/share/zoneinfo/"
var systemLocaltimeFile = "/data/etc/localtime"

// SystemSetRootPassword update shadow file
func SystemSetRootPassword(password string) error {
	crypter := crypt.SHA256.New()

	// generate password line
	hash, err := crypter.Generate([]byte(password), nil)
	if err != nil {
		return fmt.Errorf("failed to generate hash: %w", err)
	}
	line := fmt.Sprintf("root:%s:0:0:::::\n", hash)

	// write shadow file
	return ioutil.WriteFile(systemShadow, []byte(line), os.ModePerm)
}

// SystemSSHEnabled returns true if server is enabled
func SystemSSHEnabled() (bool, error) {
	data, err := ioutil.ReadFile(systemDropbearConfig)
	if err != nil {
		return false, fmt.Errorf("failed to read ssh config: %w", err)
	}

	return !strings.Contains(string(data), "127.0.0.1:22"), nil
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

// SystemListTimeZones available on system
func SystemListTimeZones() ([]string, error) {
	// load zone info tab
	file, err := os.Open(path.Join(systemZoneinfo, "zone1970.tab"))
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// parse file
	zones := make([]string, 0)
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "#") {
			continue
		}

		lineSplit := strings.Split(line, "\t")
		if len(lineSplit) < 3 {
			continue
		}

		zones = append(zones, strings.TrimSpace(lineSplit[2]))
	}
	zones = append(zones, "Etc/UTC")

	sort.Strings(zones)
	return zones, nil
}

// SystemSetTimeZone for operating system
func SystemSetTimeZone(name string) error {
	if _, err := os.Stat(path.Join(systemZoneinfo, name)); err != nil {
		return fmt.Errorf("invalid time zone given: %s", name)
	}
	_ = os.Remove(systemLocaltimeFile)
	return os.Symlink(path.Join(systemZoneinfo, name), systemLocaltimeFile)
}

// SystemGetTimeZone currently set for operating system
func SystemGetTimeZone() (string, error) {
	link, err := os.Readlink(systemLocaltimeFile)
	if err != nil {
		return "", fmt.Errorf("failed to get local time zone")
	}
	return filepath.Rel(systemZoneinfo, link)
}
