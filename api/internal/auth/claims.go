package auth

import "context"

type claimsCtxKey struct{}

func claimsToCtx(ctx context.Context, claims any) context.Context {
	return context.WithValue(ctx, claimsCtxKey{}, claims)
}

// ClaimsFromCtx returns the claims stored in the context. If none are stored, a zero value of the type is returned.
func ClaimsFromCtx[T any](ctx context.Context) T {
	value := ctx.Value(claimsCtxKey{})
	claims, ok := value.(T)

	if !ok {
		var v T
		return v
	}
	return claims
}
