FROM plus3it/tardigrade-ci:0.12.3

WORKDIR /ci-harness
ENTRYPOINT ["make"]

