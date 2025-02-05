# Kudos to Alex for the original version:
# https://www.alexedwards.net/blog/a-time-saving-makefile-for-your-go-projects

.DEFAULT_GOAL = test

main_package_path = .
binary_name = frofi

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

.PHONY: no-dirty
no-dirty:
	@test -z "$(shell git status --porcelain)"


# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## test: run all tests
.PHONY: test
test:
	go test -v -race -shuffle=on -parallel=8 -buildvcs ./...

## test/cover: run all tests and display coverage
.PHONY: test/cover
test/cover:
	go test -v -race -shuffle=on -parallel=8 -buildvcs -coverpkg=./... -coverprofile=/tmp/coverage.out ./...
	go tool cover -html=/tmp/coverage.out

## audit: run quality control checks
.PHONY: audit
audit: test
	go mod tidy -diff
	go mod verify
	test -z "$(shell gofmt -l .)"
	go vet ./...
	go run honnef.co/go/tools/cmd/staticcheck@v0.5.1 -checks=all,-ST1000,-U1000 ./...
	go run golang.org/x/vuln/cmd/govulncheck@v1.1.4 ./...


# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## tidy: tidy modfiles and format .go files
.PHONY: tidy
tidy:
	go mod tidy -v
	go fmt ./...

## build: build the application for a specific OS and architecture. To run, `source ./env` and use the `frofi` alias
.PHONY: build
build:
	GOOS=linux GOARCH=amd64 go build -o=/tmp/bin/${binary_name} ${main_package_path}

## build/clean: remove build artifacts
.PHONY: build/clean
build/clean:
	rm /tmp/bin/${binary_name}


# ==================================================================================== #
# OPERATIONS
# ==================================================================================== #

## push: push changes to the remote Git repository
.PHONY: push
push: confirm audit no-dirty
	git push

