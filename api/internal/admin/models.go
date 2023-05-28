package admin

import (
	"mime/multipart"

	"github.com/go-jose/go-jose/v3/jwt"
)

// session is the struct which is incoded in the admin's session
type session struct {
	Username string           `json:"username"`
	Expiry   *jwt.NumericDate `json:"exp"`
}

type loginRequest struct {
	Username string `form:"username" binding:"required"`
	Password string `form:"password" binding:"required"`
}

type authorityInfoRequest struct {
	File *multipart.FileHeader `form:"file" binding:"required"`
}
