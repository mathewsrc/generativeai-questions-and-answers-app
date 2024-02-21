
echo "Enter QDRANT_URL:"
read QDRANT_URL_AWS
echo "Enter QDRANT_API_KEY:"
read QDRANT_API_KEY_AWS
aws secretsmanager put-secret-value --secret-id prod/qdrant_url --secret-string $QDRANT_URL_AWS 
aws secretsmanager put-secret-value --secret-id prod/qdrant_api_key --secret-string $QDRANT_API_KEY_AWS