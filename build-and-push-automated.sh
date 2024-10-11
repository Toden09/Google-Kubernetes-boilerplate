#!/bin/bash

# Define your AWS Account ID and Region
ACCOUNT_ID=975049982453
REGION=ca-central-1

# Get all Dockerfiles in your microservices directories
DOCKERFILES=$(find . -name "Dockerfile")

# Function to check if the image already exists in ECR
function image_exists_in_ecr() {
    IMAGE=$1
    IMAGE_TAG=$2
    aws ecr describe-images --repository-name $IMAGE --image-ids imageTag=$IMAGE_TAG > /dev/null 2>&1
}

# Loop through each Dockerfile found
for DOCKERFILE in $DOCKERFILES
do
    # Extract the directory and service name from the Dockerfile path
    SERVICE_DIR=$(dirname "$DOCKERFILE")
    SERVICE_NAME=$(basename "$SERVICE_DIR")

    echo "Processing $SERVICE_NAME..."

    # Check if the image already exists in ECR
    if image_exists_in_ecr $SERVICE_NAME "latest"; then
        echo "Image for $SERVICE_NAME already exists in ECR. Skipping..."
        continue
    fi

    # Navigate to the service directory
    cd $SERVICE_DIR

    # Build the Docker image
    docker build -t $SERVICE_NAME:latest .

    # Tag the Docker image for ECR
    docker tag $SERVICE_NAME:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$SERVICE_NAME:latest

    # Push the Docker image to ECR
    docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$SERVICE_NAME:latest

    # Navigate back to the root directory
    cd -

    echo "$SERVICE_NAME processed successfully."
done
