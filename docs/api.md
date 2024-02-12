Rest API with ECS and FastAPI

This project application is a REST API written with FastAPI library. The API is conteinarized using Docker 
and served in the cloud with AWS ECS.

ECS

Different of Lambda the ECS service is a Plataform as a Service where we can run containers.
As ECS does not have the Enviroment as the Lambda Function we have to use another solution to
store sensitive information. AWS providers the Secrets Manager service to securely store sensitive 
information such as API keys and passwords. We 