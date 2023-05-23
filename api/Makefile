.generate-proto:
	protoc \
		--go_opt=module=ldt-hack/api --go_out=./internal/pb \
		--go-grpc_opt=module=ldt-hack/api --go-grpc_out=./internal/pb \
		api/app/v1/app.proto

generate: .generate-proto
