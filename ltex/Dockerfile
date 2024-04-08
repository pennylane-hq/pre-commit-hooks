FROM openjdk:11.0.16-jre

ARG LTEX_VERSION=16.0.0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN <<EOF
  wget --quiet https://github.com/valentjn/ltex-ls/releases/download/${LTEX_VERSION}/ltex-ls-${LTEX_VERSION}.tar.gz -O - | tar -xz
  mv /ltex-ls-${LTEX_VERSION} /ltex-ls
EOF

ENTRYPOINT ["/ltex-ls/bin/ltex-cli"]
