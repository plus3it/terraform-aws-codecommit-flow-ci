FROM plus3it/tardigrade-ci:0.10.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

