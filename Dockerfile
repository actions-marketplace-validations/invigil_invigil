# The Invigil CLI as a container — for CI systems that aren't Python-friendly
# (GitLab, Jenkins, Drone). Mount the repo to grade at /repo:
#
#   docker run --rm -v "$PWD:/repo" ghcr.io/invigil/invigil score /repo
#
FROM python:3.12-slim@sha256:57cd7c3a7a273101a6485ba99423ee568157882804b1124b4dd04266317710de

LABEL org.opencontainers.image.source="https://github.com/invigil/invigil" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.description="A CI quality gate that grades a repo against a product-quality doctrine — not code style."

# git: the tier-1 secrets checks read the git index of the mounted repo;
# without it they SKIP and the grade silently loses fidelity.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

# Copy only what the wheel build needs — keeps the context change-proof
# without maintaining a .dockerignore.
COPY pyproject.toml README.md LICENSE /src/
COPY src /src/src
RUN pip install --no-cache-dir /src && rm -rf /src

# Mounted repos are owned by the host user; without this git refuses to read
# them ("detected dubious ownership") and every git-based check SKIPs.
RUN git config --system safe.directory '*'

WORKDIR /repo
ENTRYPOINT ["invigil"]
CMD ["score", "."]
