
echo "Enter QDRANT_URL:"
read QDRANT_URL
echo "Enter QDRANT_API_KEY:"
read QDRANT_API_KEY
aws secretsmanager put-secret-value --secret-id prod/qdrant_url --secret-string $QDRANT_URL 
aws secretsmanager put-secret-value --secret-id prod/qdrant_api_key --secret-string $QDRANT_API_KEY