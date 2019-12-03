package alpine_builder

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"
)

// network configuration
var networkConfig = "/data/etc/network/interfaces"
var networkInterface = "eth0"

// regular expressions
var reSectionStart = regexp.MustCompile("^(iface|mapping|auto|allow-|source)")
var reIface = regexp.MustCompile("^iface (\\w+) inet (\\w+)")
var reStaticAddress = regexp.MustCompile("^(\\s*)address ([0-9.]+)")
var reStaticNetmask = regexp.MustCompile("^(\\s*)netmask ([0-9.]+)")
var reStaticGateway = regexp.MustCompile("^(\\s*)gateway ([0-9.]+)")

// NetworkInfo represents the actual network configuration
type NetworkInfo struct {
	IsStatic bool
	Address  string
	Netmask  string
	Gateway  string
}

// GetNetworkInfo from config file
func GetNetworkInfo() (*NetworkInfo, error) {
	// load config file
	file, err := os.Open(networkConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to open network config: %w", err)
	}
	defer file.Close()

	var info *NetworkInfo
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// check for section start
		if reSectionStart.MatchString(line) {
			infLine := reIface.FindStringSubmatch(line)
			if infLine != nil {
				// interface found
				if infLine[1] == networkInterface {
					info = &NetworkInfo{
						IsStatic: infLine[2] == "static",
					}
				}
			} else {
				// info set -> stop here
				if info != nil {
					break
				}
			}

		} else if info != nil {
			// interface config
			address := reStaticAddress.FindStringSubmatch(line)
			if address != nil {
				info.Address = address[2]
			}
			netmask := reStaticNetmask.FindStringSubmatch(line)
			if netmask != nil {
				info.Netmask = netmask[2]
			}
			gateway := reStaticGateway.FindStringSubmatch(line)
			if gateway != nil {
				info.Gateway = gateway[2]
			}
		}
	}
	if info != nil {
		return info, nil
	}
	return nil, errors.New("invalid network config")
}

// NetworkEnableDHCP configures the network to use DHCP client
func NetworkEnableDHCP() error {
	// load config file
	file, err := os.Open(networkConfig)
	if err != nil {
		return fmt.Errorf("failed to open network config: %w", err)
	}
	defer file.Close()

	var buffer bytes.Buffer
	var infFound bool

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// check for section start
		if reSectionStart.MatchString(line) {
			infLine := reIface.FindStringSubmatch(line)
			if infLine != nil {
				// interface found
				if infLine[1] == networkInterface {
					infFound = true
					buffer.WriteString(fmt.Sprintf("iface %s inet dhcp\n", networkInterface))
					continue
				}
			} else {
				if infFound {
					infFound = false
				}
			}
			buffer.WriteString(line + "\n")

		} else if !infFound {
			buffer.WriteString(line + "\n")
		}
	}

	// write config file
	return ioutil.WriteFile(networkConfig, buffer.Bytes(), os.ModePerm)
}

// NetworkSetStatic IP configuration
func NetworkSetStatic(address, netmask, gateway string) error {
	// load config file
	file, err := os.Open(networkConfig)
	if err != nil {
		return fmt.Errorf("failed to open network config: %w", err)
	}
	defer file.Close()

	var buffer bytes.Buffer
	var infFound bool

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// check for section start
		if reSectionStart.MatchString(line) {
			infLine := reIface.FindStringSubmatch(line)
			if infLine != nil {
				// interface found
				if infLine[1] == networkInterface {
					infFound = true
					buffer.WriteString(fmt.Sprintf("iface %s inet static\n", networkInterface))
					buffer.WriteString(fmt.Sprintf("  address %s\n", address))
					buffer.WriteString(fmt.Sprintf("  netmask %s\n", netmask))
					buffer.WriteString(fmt.Sprintf("  gateway %s\n", gateway))
					continue
				}
			} else {
				if infFound {
					infFound = false
				}
			}
			buffer.WriteString(line + "\n")

		} else if !infFound {
			buffer.WriteString(line + "\n")
		}
	}

	// write config file
	return ioutil.WriteFile(networkConfig, buffer.Bytes(), os.ModePerm)
}
