FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    gcc \
    make \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install norminette
RUN pip3 install --no-cache-dir norminette

# Create a non-root user for security
RUN useradd -m -s /bin/bash runner

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /github/workspace

# Switch to non-root user
USER runner

ENTRYPOINT ["/entrypoint.sh"]
