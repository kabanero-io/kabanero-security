# The Docker image in format repository:tag. Repository may contain a remote reference.
# Override in order to customize
IMAGE ?= imagesigning-operator:latest
REPO ?= SET_YOUR_REPOSITORY
ifneq "$(REPO)" "SET_YOUR_REPOSITORY"
	IMAGE =${REPO}/imagesigning-operator:v0.1.0
endif

# Current release (used for CSV management)

.PHONY: build deploy build-image push-image undeploy

build: generate
	GO111MODULE=on go install ./cmd/manager

build-image: generate
	operator-sdk build ${IMAGE}

push-image:
ifneq "$(IMAGE)" "imagesigning-operator:latest"
	docker push $(IMAGE)
endif

test: 
	GO111MODULE=on go test ./cmd/... ./pkg/... 

format:
	GO111MODULE=on go fmt ./cmd/... ./pkg/...

generate:
	GO111MODULE=on operator-sdk generate k8s
	GO111MODULE=on operator-sdk generate openapi

deploy: 

ifneq "$(IMAGE)" "imagesigning-operator:latest"
	cp deploy/operator.yaml deploy/operator.yaml.bak || true
	sed -i 's|REPLACE_IMAGE|$(IMAGE)|g' deploy/operator.yaml
	oc create namespace kabanero || true
	oc apply -f deploy/crds/security.kabanero.io_imagesignings_crd.yaml
	oc apply -f deploy/ -n kabanero
endif

undeploy:
	oc delete -f deploy/ -n kabanero || true
	oc delete -f deploy/crds/security.kabanero.io_imagesignings_crd.yaml
	cp deploy/operator.yaml.bak deploy/operator.yaml
