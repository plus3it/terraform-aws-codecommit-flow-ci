FROM plus3it/tardigrade-ci:0.11.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

