FROM plus3it/tardigrade-ci:0.16.1

WORKDIR /ci-harness
ENTRYPOINT ["make"]

