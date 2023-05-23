package crypto

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

// HashPassword hashes a password using bcrypt
func HashPassword(password string) ([]byte, error) {
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("generating hash using bcrypt: %w", err)
	}

	return hashed, nil
}

// ValidateHashedPassword validates the given password using its hash.
func ValidateHashedPassword(password string, hash []byte) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}
