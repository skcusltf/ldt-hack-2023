LOCAL_K3D_CONFIG ?= $(LOCAL_DIR)/k3d.yaml
LOCAL_KUBE_CLUSTER ?= k3s-ldt
LOCAL_KUBE_CONFIG ?= $(LOCAL_DIR)/kubeconfig.yaml
LOCAL_ENV_FILE ?= $(LOCAL_DIR)/env
LOCAL_HELM_ARGS := -f $(LOCAL_DIR)/values.yaml ldt-api $(CHART_DIR)/ldt-api

.PHONY: local.cluster.up
local.cluster.up:
	k3d --config $(LOCAL_K3D_CONFIG) cluster create
	k3d kubeconfig write $(LOCAL_KUBE_CLUSTER) --output $(LOCAL_KUBE_CONFIG)
	KUBECONFIG=$(LOCAL_KUBE_CONFIG) kubectl cluster-info

	touch $(LOCAL_ENV_FILE)
	echo "export KUBECONFIG=$(LOCAL_KUBE_CONFIG)" >> $(LOCAL_ENV_FILE)

	@echo "\nCluster initialized"
	@echo "Execute 'source $(LOCAL_ENV_FILE)' to setup KUBECONFIG env variable"

.PHONY: local.cluster.down
local.cluster.down:
	k3d --config $(LOCAL_K3D_CONFIG) cluster delete
	rm -rf $(LOCAL_KUBE_CONFIG) $(LOCAL_ENV_FILE)

.PHONY: local.api.build
local.api.build:
	docker build -f $(DOCKERFILE_DIR)/Dockerfile.api -t ldt-api:$(tag) ./api

.PHONY: local.api.import
local.api.import:
	k3d image -c $(LOCAL_KUBE_CLUSTER) import ldt-api:$(tag)

.PHONY: local.api.up
local.api.up: local.api.build local.api.import
	helm install $(LOCAL_HELM_ARGS)

.PHONY: local.api.upgrade
local.api.upgrade: local.api.build local.api.import
	helm upgrade $(LOCAL_HELM_ARGS)

.PHONY: local.api.down
local.api.down:
	helm uninstall ldt-api

.PHONY: local.pg.up
local.pg.up:
	helm install -f $(LOCAL_DIR)/values.pg.yaml pg oci://registry-1.docker.io/bitnamicharts/postgresql
	kubectl create secret generic postgres-dsn --from-literal='value=postgres://ldt-api:password@pg-postgresql:5432/ldt-api?sslmode=disable'
