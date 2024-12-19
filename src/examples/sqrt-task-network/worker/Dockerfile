FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy worker code and ABI
COPY worker.py .
COPY abi.json .

# Environment variables will be provided at runtime
ENV WEB3_URL=https://ethereum-holesky-rpc.publicnode.com
ENV VALIDATOR_PRIVATE_KEY=""

# Add restart script
RUN echo '#!/bin/sh\n' \
    'while true; do\n' \
    '    python worker.py start \\\n' \
    '        --validator-private-key "$VALIDATOR_PRIVATE_KEY" \\\n' \
    '        --web3-url "$WEB3_URL"\n' \
    '    status=$?\n' \
    '    echo "Process exited with status $status, restarting in 5 seconds..."\n' \
    '    sleep 5\n' \
    'done\n' > /app/start.sh

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]