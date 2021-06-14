FROM plus3it/tardigrade-ci:0.14.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

