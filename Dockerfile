FROM plus3it/tardigrade-ci:0.13.1

WORKDIR /ci-harness
ENTRYPOINT ["make"]

