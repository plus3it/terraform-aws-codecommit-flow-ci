FROM plus3it/tardigrade-ci:0.13.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

