FROM plus3it/tardigrade-ci:0.14.1

WORKDIR /ci-harness
ENTRYPOINT ["make"]

