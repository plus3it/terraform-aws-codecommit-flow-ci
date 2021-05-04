FROM plus3it/tardigrade-ci:0.12.2

WORKDIR /ci-harness
ENTRYPOINT ["make"]

