
.PHONY: release
release:
	./scripts/build.sh

clean:
	rm -rf ./bin ./_tmp
	find **/*.generated.yaml -print0 | xargs -0 rm -f || true
	find **/*.coverprofile -print0 | xargs -0 rm -f || true

IMG_NAME ?= aws/aws-k8s-tester
TAG ?= latest

ACCOUNT_ID ?= $(aws sts get-caller-identity --query Account --output text)
REGION ?= us-west-2

docker:
	aws s3 cp --region us-west-2 s3://aws-k8s-tester-public/clusterloader2-linux-amd64 ./_tmp/clusterloader2
	cp -rf ${HOME}/go/src/k8s.io/perf-tests/clusterloader2/testing/load ./_tmp/clusterloader2-testing-load
	docker build --network host -t $(IMG_NAME):$(TAG) --build-arg RELEASE_VERSION=$(TAG) .
	docker tag $(IMG_NAME):$(TAG) $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(IMG_NAME):$(TAG)
	docker run --rm -it $(IMG_NAME):$(TAG) aws --version

# e.g.
# make docker-push ACCOUNT_ID=${YOUR_ACCOUNT_ID} TAG=latest
docker-push: docker
	eval $$(aws ecr get-login --registry-ids $(ACCOUNT_ID) --no-include-email --region $(REGION))
	docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(IMG_NAME):$(TAG);

