FROM plus3it/tardigrade-ci:0.7.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

