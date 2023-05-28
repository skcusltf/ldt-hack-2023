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

// Requests

type loginRequest struct {
	Username string `form:"username" binding:"required"`
	Password string `form:"password" binding:"required"`
}

type authorityInfoRequest struct {
	File *multipart.FileHeader `form:"file" binding:"required"`
}

type createInspectorRequest struct {
	FirstName string `form:"first_name" binding:"required"`
	LastName  string `form:"last_name" binding:"required"`
	Email     string `form:"email" binding:"required"`
	Password  string `form:"password" binding:"required"`
}

// Responses

type apiError struct {
	Error string `json:"error"`
}

type authority struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}
