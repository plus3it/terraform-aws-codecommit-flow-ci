FROM plus3it/tardigrade-ci:0.8.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

