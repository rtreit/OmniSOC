# Start from an NVIDIA CUDA base with Python already included
FROM pytorch/pytorch:2.2.0-cuda12.1-cudnn8-runtime

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install git and other dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/microsoft/OmniParser.git /app

# Modify requirements.txt to use transformers 4.45.0
RUN sed -i 's/transformers==.*$/transformers==4.45.0/g' /app/requirements.txt

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt huggingface_hub

# Download OmniParser model weights from HF
RUN mkdir -p /app/weights && \
    for folder in icon_caption icon_detect; do \
        huggingface-cli download microsoft/OmniParser-v2.0 --local-dir /app/weights \
            --repo-type model --include "$folder/*"; \
    done && \
    mv /app/weights/icon_caption /app/weights/icon_caption_florence

# Expose port for FastAPI
EXPOSE 8000

# Set environment variables
ENV PYTHONPATH=/app

# Switch to the omniparserserver directory
WORKDIR /app/omnitool/omniparserserver

# Default command: run the server with host 0.0.0.0 to be accessible outside the container
CMD ["python", "-m", "omniparserserver", "--host", "0.0.0.0"]