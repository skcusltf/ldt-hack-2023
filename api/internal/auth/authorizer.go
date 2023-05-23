package auth

import (
	"context"
	"crypto/ecdsa"
	"fmt"

	"github.com/go-jose/go-jose/v3"
	"github.com/go-jose/go-jose/v3/jwt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	bearerScheme  = "Bearer"
	encrypterType = "JWT"
)

// Authorizer authorizes gRPC requests based on JWTs in the Authorization header.
type Authorizer struct {
	key       *ecdsa.PrivateKey
	signer    jose.Signer
	encrypter jose.Encrypter
}

// NewAuthorizer creates a new authorizer which encrypts, signs and validates tokens using an ecdsa private key.
func NewAuthorizer(key *ecdsa.PrivateKey) (*Authorizer, error) {
	signer, err := jose.NewSigner(jose.SigningKey{Algorithm: jose.ES256, Key: key}, nil)
	if err != nil {
		return nil, fmt.Errorf("creating signer: %w", err)
	}

	encrypter, err := jose.NewEncrypter(
		jose.A256GCM,
		jose.Recipient{
			Algorithm: jose.ECDH_ES_A256KW,
			Key:       &key.PublicKey,
		},
		(&jose.EncrypterOptions{
			Compression: jose.DEFLATE,
		}).WithContentType(encrypterType).WithType(encrypterType))
	if err != nil {
		return nil, fmt.Errorf("creating encrypter: %w", err)
	}

	return &Authorizer{key, signer, encrypter}, nil
}

// UnaryInterceptor returns a unary gRPC interceptor which authorizes requests to all endpoints except the whitelisted ones.
// The authorizer is used to validate incoming tokens, which are then decoded to the given type.
func UnaryInterceptor[T any](a *Authorizer, whitelist ...string) grpc.UnaryServerInterceptor {
	whitelistedEndpoints := make(map[string]struct{})
	for _, endpoint := range whitelist {
		whitelistedEndpoints[endpoint] = struct{}{}
	}

	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (resp interface{}, err error) {
		if _, ok := whitelistedEndpoints[info.FullMethod]; ok {
			return handler(ctx, req)
		}

		tokenString, err := auth.AuthFromMD(ctx, bearerScheme)
		if err != nil {
			return nil, status.Error(codes.Unauthenticated, "Missing token")
		}

		var claims T
		if ok := a.verifyAndParse(tokenString, &claims); !ok {
			return nil, status.Error(codes.Unauthenticated, "Invalid token")
		}

		return handler(claimsToCtx(ctx, claims), req)
	}
}

// Construct constructs a new JWT containing the specified claims.
func (a *Authorizer) Construct(claims any) (string, error) {
	token, err := jwt.SignedAndEncrypted(a.signer, a.encrypter).Claims(claims).CompactSerialize()
	if err != nil {
		return "", fmt.Errorf("constructing token: %w", err)
	}

	return token, nil
}

// verifyAndParse verifies the given JWT and reads the token claims into the given value, which should be a pointer.
func (a *Authorizer) verifyAndParse(jwtString string, dest any) bool {
	encryptedToken, err := jwt.ParseSignedAndEncrypted(jwtString)
	if err != nil {
		return false
	}

	token, err := encryptedToken.Decrypt(a.key)
	if err != nil {
		return false
	}

	if err := token.Claims(&a.key.PublicKey, dest); err != nil {
		return false
	}

	return true
}
