#!/bin/bash
set -e

# Update this path to match your server's repository location
cd /path/to/your/blogsite

echo "Pulling latest changes..."
git pull origin main

echo "Stopping existing containers..."
docker-compose down

echo "Building and starting containers..."
docker-compose up -d --build

echo "Checking container status..."
docker-compose ps

echo "Deployment complete!"
