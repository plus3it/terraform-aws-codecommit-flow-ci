FROM plus3it/tardigrade-ci:0.12.4

WORKDIR /ci-harness
ENTRYPOINT ["make"]

