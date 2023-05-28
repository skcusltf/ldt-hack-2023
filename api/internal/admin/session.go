package admin

import (
	"crypto/subtle"
	"net/http"
	"time"

	"ldt-hack/api/internal/crypto"

	"github.com/gin-gonic/gin"
	"github.com/go-jose/go-jose/v3/jwt"
)

const (
	sessionCookieName = "session"
	sessionExpiry     = time.Hour
)

func (s *Service) loginHandler(c *gin.Context) {
	var req loginRequest
	if err := c.Bind(&req); err != nil {
		return
	}

	usernameEqual := subtle.ConstantTimeCompare([]byte(req.Username), s.adminUsername) == 1
	passwordEqual := crypto.ValidateHashedPassword(req.Password, s.adminPasswordHash)
	if !usernameEqual || !passwordEqual {
		c.AbortWithStatus(http.StatusUnauthorized)
		return
	}

	token, err := s.authorizer.Construct(session{
		Username: req.Username,
		Expiry:   jwt.NewNumericDate(time.Now().Add(sessionExpiry)),
	})
	if err != nil {
		s.logger.Error("failed to construct admin token", "error", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Cookie without domain will be set for the origin by default
	c.SetCookie(sessionCookieName, token, int(sessionExpiry.Seconds()), "/admin", "", false, true)
}

// authorizeSession tries to authorize a request using the session stored in the cookies and aborts the error otherwise
func (s *Service) authorizeSession(c *gin.Context) (ok bool) {
	defer func() {
		if !ok {
			c.AbortWithStatus(http.StatusForbidden)
		}
	}()

	sessionCookie, err := c.Cookie(sessionCookieName)
	if err != nil {
		return false
	}

	var sess session
	if !s.authorizer.VerifyAndParse(sessionCookie, &sess) {
		return false
	}

	return sess.Expiry.Time().After(time.Now()) && sess.Username == string(s.adminUsername)
}
