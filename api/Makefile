.generate-proto:
	protoc \
		--go_opt=module=ldt-hack/api --go_out=./internal/pb \
		--go-grpc_opt=module=ldt-hack/api --go-grpc_out=./internal/pb \
		api/auth/v1/auth.proto

generate: .generate-proto
