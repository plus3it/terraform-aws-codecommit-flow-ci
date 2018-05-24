TERRAFORM_VERSION ?= $(shell curl -sSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')
TERRAFORM_URL ?= https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_linux_amd64.zip

.PHONY: tf.lint
tf.lint: tf.tools
	terraform fmt -check=true

.PHONY: tf.tools
tf.tools:
	@echo "[make]: TERRAFORM_URL=$(TERRAFORM_URL)"
	curl -sSL -o terraform.zip "$(TERRAFORM_URL)"
	unzip terraform.zip && rm -f terraform.zip && chmod +x terraform
	mkdir -p "${HOME}/bin" && export PATH="${HOME}/bin:${PATH}" && mv terraform "${HOME}/bin"
	terraform --version
