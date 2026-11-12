FROM eclipse-temurin:21-jre

ARG LTEX_VERSION=18.7.0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN <<EOF
  wget --quiet https://github.com/ltex-plus/ltex-ls-plus/releases/download/${LTEX_VERSION}/ltex-ls-plus-${LTEX_VERSION}.tar.gz -O - | tar -xz
  mv /ltex-ls-plus-${LTEX_VERSION} /ltex-ls
EOF

ENTRYPOINT ["/ltex-ls/bin/ltex-cli-plus"]
