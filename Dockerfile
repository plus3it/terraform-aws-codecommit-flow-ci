FROM plus3it/tardigrade-ci:0.9.1

WORKDIR /ci-harness
ENTRYPOINT ["make"]

