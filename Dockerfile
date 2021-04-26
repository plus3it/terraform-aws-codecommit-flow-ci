FROM plus3it/tardigrade-ci:0.12.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

