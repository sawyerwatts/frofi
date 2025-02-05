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
	go run honnef.co/go/tools/cmd/staticcheck@latest -checks=all,-ST1000,-U1000 ./...
	go run golang.org/x/vuln/cmd/govulncheck@latest ./...


# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## tidy: tidy modfiles and format .go files
.PHONY: tidy
tidy:
	go mod tidy -v
	go fmt ./...

## run: build/debug and run the binary using .env
.PHONY: run
run: build/debug
	/tmp/bin/${binary_name}

## build/debug: build the application with -race, -v, etc
.PHONY: build/debug
build/debug:
	go build -v -race -o=/tmp/bin/${binary_name} ${main_package_path}

## build/release: build the application without -race, -v, etc, for a specific OS and architecture
.PHONY: build/release
build/release:
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

## install: build and add the application's binary to ~/bin/
.PHONY: install
install: confirm audit no-dirty build/release
	mkdir -p ~/bin
	mv /tmp/bin/${binary_name} ~/bin

## uninstall: remove the application's binary from ~/bin/
.PHONY: uninstall
uninstall: confirm
	[ ! -f ~/bin/${binary_name} ] || rm ~/bin/${binary_name}

