FROM plus3it/tardigrade-ci:0.0.18

WORKDIR /ci-harness
ENTRYPOINT ["make"]

