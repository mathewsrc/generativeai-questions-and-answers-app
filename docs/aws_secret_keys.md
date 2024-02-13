# Creating Secret Keys for GitHub Actions 

1. Go to GitHub -> this project cloned -> Settings -> Secrets and variables -> actions -> `New repository secret`

![image](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/assets/94936606/1c4fe6cc-1f71-4476-b7c9-23e2e24b3670)

Figure 1. GitHub secrets required

2. You need to create the following secrete keys: `AWS_ACCESS_KEY_ID`, `AWS_ACCOUNT_ID`, `AWS_SECRET_ACCESS_KEY`,
`QDRANT_API_KEY`, `QDRANT_URL`


![image](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/assets/94936606/1ee1ede6-0cad-4fa4-acdf-2e8c6758ee58)

Figure 2. Creating a new secret

3. Click `Add secret`
4. Congratulations! Now you can deploy this application to AWS ECS
