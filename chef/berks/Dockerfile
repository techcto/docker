FROM chef/chefworkstation:latest

LABEL org.opencontainers.image.title="techcto/berks"
LABEL org.opencontainers.image.description="Public Berkshelf build image with AWS CLI v2"
LABEL org.opencontainers.image.vendor="TechCTO"

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl unzip; \
    rm -rf /var/lib/apt/lists/*; \
    case "$(uname -m)" in \
        x86_64) aws_arch="x86_64" ;; \
        aarch64) aws_arch="aarch64" ;; \
        *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o /tmp/awscliv2.zip; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/aws /tmp/awscliv2.zip; \
    berks --version; \
    aws --version

WORKDIR /workspace

CMD ["/bin/bash"]
