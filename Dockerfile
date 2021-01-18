FROM plus3it/tardigrade-ci:0.8.1

WORKDIR /ci-harness
ENTRYPOINT ["make"]

