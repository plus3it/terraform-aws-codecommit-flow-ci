FROM plus3it/tardigrade-ci:0.9.2

WORKDIR /ci-harness
ENTRYPOINT ["make"]

