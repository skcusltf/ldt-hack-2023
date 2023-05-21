ROOT_DIR ?= $(CURDIR)
DEPLOY_DIR ?= $(ROOT_DIR)/deploy
LOCAL_DIR ?= $(DEPLOY_DIR)/local
DOCKERFILE_DIR ?= $(DEPLOY_DIR)/dockerfiles
CHART_DIR ?= $(DEPLOY_DIR)/charts

# Local cluster setup
include $(LOCAL_DIR)/local.mk
