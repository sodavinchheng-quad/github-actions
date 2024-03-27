.PHONY: local
local:
	chmod +x ./deploy.sh;
	./deploy.sh local -p ./build/_local_

.PHONY: dev
dev:
	chmod +x ./deploy.sh;
	./deploy.sh development;

.PHONY: prd
prd:
	chmod +x ./deploy.sh;
	./deploy.sh production;

.PHONY: test
test:
	yarn test;