FROM plus3it/tardigrade-ci:0.17.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

