FROM plus3it/tardigrade-ci:0.17.1

WORKDIR /ci-harness
ENTRYPOINT ["make"]

