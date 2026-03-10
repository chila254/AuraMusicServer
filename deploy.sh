#!/bin/bash

# Deploy script for AuraMusicServer
# This script builds and pushes the Docker image to a registry

set -e

# Configuration
IMAGE_NAME="${IMAGE_NAME:-auramusic-server}"
REGISTRY="${REGISTRY:-docker.io}"
VERSION="${VERSION:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting AuraMusicServer deployment...${NC}"

# Step 1: Build the Docker image
echo -e "${YELLOW}Step 1: Building Docker image...${NC}"
docker build -t ${IMAGE_NAME}:${VERSION} .

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Docker image built successfully${NC}"
else
  echo -e "${RED}✗ Failed to build Docker image${NC}"
  exit 1
fi

# Step 2: Tag the image for registry
echo -e "${YELLOW}Step 2: Tagging image for registry...${NC}"
docker tag ${IMAGE_NAME}:${VERSION} ${REGISTRY}/${IMAGE_NAME}:${VERSION}

# Step 3: Push to registry (optional)
if [ "$PUSH" = "true" ]; then
  echo -e "${YELLOW}Step 3: Pushing image to registry...${NC}"
  docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Image pushed successfully to ${REGISTRY}${NC}"
  else
    echo -e "${RED}✗ Failed to push image${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}Skipping registry push (set PUSH=true to enable)${NC}"
fi

# Step 4: Show how to run locally
echo -e "${GREEN}✓ Build complete!${NC}"
echo ""
echo -e "${GREEN}To run locally:${NC}"
echo "  docker run -d -p 8080:8080 -e PORT=8080 --name auramusic-server ${IMAGE_NAME}:${VERSION}"
echo ""
echo -e "${GREEN}To run on a custom port:${NC}"
echo "  docker run -d -p 9000:9000 -e PORT=9000 --name auramusic-server ${IMAGE_NAME}:${VERSION}"
echo ""
echo -e "${GREEN}View logs:${NC}"
echo "  docker logs -f auramusic-server"
