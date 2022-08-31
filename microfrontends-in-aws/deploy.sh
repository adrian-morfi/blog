#! /bin/bash

BASE_PATH=$(pwd)

# Create terraform infra
cd $BASE_PATH/iac

terraform init && terraform apply -auto-approve


CONTAINER_BUCKET_NAME=$(terraform output -raw container_bucket)
HEADER_BUCKET_NAME=$(terraform output -raw header_bucket)
ALBUM_BUCKET_NAME=$(terraform output -raw album_bucket)
FOOTER_BUCKET_NAME=$(terraform output -raw footer_bucket)
DISTRIBUTION_ID=$(terraform output -raw distribution_id)

cd $BASE_PATH/micros/
for d in */ ; do
    cd $BASE_PATH/micros/$d

    # Install dependencies 
    npm install --force

    # Build the package
    npm run build


    if [ "$d" == "container/" ]; then
        aws s3 cp "dist" "s3://$CONTAINER_BUCKET_NAME" --recursive
    elif [ "$d" == "album/" ]; then
        aws s3 cp "dist" "s3://$ALBUM_BUCKET_NAME/album" --recursive
    elif [ "$d" == "footer/" ]; then
        aws s3 cp "dist" "s3://$FOOTER_BUCKET_NAME/footer" --recursive
    elif [ "$d" == "header/" ]; then
        aws s3 cp "dist" "s3://$HEADER_BUCKET_NAME/header" --recursive
    fi
    
done