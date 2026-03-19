FROM ubuntu:22.04

# Avoid interactive prompts during apt commands
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install required packages including Python, curl, and gpg
RUN apt-get update && \
    apt-get install -y curl gpg python3 && \
    curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | tee /etc/apt/sources.list.d/playit-cloud.list && \
    apt-get update && \
    apt-get install -y playit && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up the working directory where our web files will reside
WORKDIR /app

# Copy the static website layout to the container
COPY index.html /app/index.html

# Expose port 80 for the python web server
EXPOSE 80

# Configure a /data volume for rclone persistent files
VOLUME /data

# Create a startup script that runs both the Python HTTP Server and the Playit agent
RUN echo '#!/bin/bash\n\
python3 -m http.server 80 &\n\
\n\
if [ -z "$PLAYIT_SECRET" ]; then\n\
  echo "ERROR: PLAYIT_SECRET is empty. Playit will ask for interactive setup and freeze! Stopping."\n\
  exit 1\n\
fi\n\
\n\
echo "Starting playit in headless mode with secret..."\n\
playit --secret "$PLAYIT_SECRET"\n\
' > /start.sh && chmod +x /start.sh

# Run the startup script when container starts
CMD ["/start.sh"]
