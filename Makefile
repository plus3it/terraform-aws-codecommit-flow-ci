ARCH ?= amd64
OS ?= $(shell uname -s | tr '[:upper:]' '[:lower:'])
CURL ?= curl --fail -sSL
XARGS ?= xargs -I {}
BIN_DIR ?= ${HOME}/bin

empty :=
space := $(empty) $(empty)

PATH := $(BIN_DIR):$(PATH)

MAKEFLAGS += --no-print-directory
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.SUFFIXES:

.PHONY: %/install %/lint
.PHONY: guard/%

guard/env/%:
	@ _=$(or $($*),$(error Make/environment variable '$*' not present))

guard/program/%:
	@ which $* > /dev/null || $(MAKE) $*/install

$(BIN_DIR):
	@ echo "[make]: Creating directory '$@'..."
	mkdir -p $@

# Macro to download a hashicorp archive release
# $(call download_hashicorp_release,file,app,version)
download_hashicorp_release = $(CURL) -o $(1) https://releases.hashicorp.com/$(2)/$(3)/$(2)_$(3)_$(OS)_$(ARCH).zip

terraform/install: TERRAFORM_VERSION ?= $(shell $(CURL) https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version' | sed 's/^v//')
terraform/install: | $(BIN_DIR)
	@ echo "[$@]: Installing $(@D)..."
	$(call download_hashicorp_release,$(@D).zip,$(@D),$(TERRAFORM_VERSION))
	unzip $(@D).zip && rm -f $(@D).zip && chmod +x $(@D)
	mv $(@D) "$(BIN_DIR)"
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

terraform/lint: | guard/program/terraform
	@ echo "[$@]: Linting Terraform files..."
	terraform fmt -check=true -diff=true
	@ echo "[$@]: Terraform files PASSED lint test!"
