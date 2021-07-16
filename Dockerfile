FROM plus3it/tardigrade-ci:0.15.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

