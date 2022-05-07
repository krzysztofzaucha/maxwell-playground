package internal

import (
	"encoding/json"
	"github.com/pkg/errors"
	"os"
	"path/filepath"
)

// LoadConfig configuration loader.
func LoadConfig(configPath string) (*Config, error) {
	config := new(Config)

	if _, err := os.Stat(configPath); err != nil {
		return nil, errors.Wrapf(ErrPkg, "config file %s not found: %s", configPath, err)
	}

	file, err := os.Open(filepath.Clean(configPath))
	if err != nil {
		return nil, errors.Wrapf(ErrPkg, "unable to read %s file: %s", configPath, err)
	}

	err = json.NewDecoder(file).Decode(&config)
	if err != nil {
		return nil, errors.Wrapf(ErrPkg, "unable to parse %s file: %s", configPath, err)
	}

	return config, nil
}
