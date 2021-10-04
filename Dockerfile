FROM plus3it/tardigrade-ci:0.18.0

WORKDIR /ci-harness
ENTRYPOINT ["make"]

