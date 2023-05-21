REMOTE_REPOSITORY := swr.ru-moscow-1.hc.sbercloud.ru/skcusltf-lct-23-track-2
REMOTE_HELM_ARGS := -f $(REMOTE_DIR)/values.yaml ldt-api-$(release) $(CHART_DIR)/ldt-api

.PHONY: remote.api.build
remote.api.build:
	docker build -f $(DOCKERFILE_DIR)/Dockerfile.api -t $(REMOTE_REPOSITORY)/ldt-api:$(tag) ./api
	docker push $(REMOTE_REPOSITORY)/ldt-api:$(tag)

.PHONY: remote.api.up
remote.api.up: remote.api.build
	helm install $(REMOTE_HELM_ARGS)

.PHONY: remote.api.upgrade
remote.api.upgrade:
	helm upgrade $(REMOTE_HELM_ARGS)

.PHONY: remote.api.down
remote.api.down:
	helm uninstall ldt-api
