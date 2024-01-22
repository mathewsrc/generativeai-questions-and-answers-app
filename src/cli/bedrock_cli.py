import boto3
import click
import json
from langchain.llms.bedrock import Bedrock
from langchain_community.vectorstores import Qdrant
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA
import os
from dotenv import load_dotenv
import sys
module_path = ".."
sys.path.append(os.path.abspath(module_path))
from global_variables import AWS_REGION, COLLECTION_NAME
from utils import (
	get_embeddings,
	get_client,
	get_prompt,
	Embedding,
	Embeddings,
	aws_embeddings,
	aws_llm,
)

load_dotenv()

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")

boto_session = boto3.Session(region_name=AWS_REGION)

# bedrock
bedrock_models = boto3.client("bedrock", region_name=AWS_REGION)
bedrock_runtime = boto3.client("bedrock-runtime", region_name=AWS_REGION)


@click.group()
def cli():
	pass


@cli.command("list-models")
@click.option("--by-provider", help="Filter by provider")
@click.option(
	"--by-output-modality",
	help="Filter by output modality",
	type=click.Choice(["TEXT", "EMBEDDING"], case_sensitive=True),
)
def list_foundation_models(by_provider=None, by_output_modality=None):
	if by_provider is not None and by_output_modality is None:
		models = bedrock_models.list_foundation_models(byProvider=by_provider)
		click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
	elif by_output_modality is not None and by_provider is None:
		models = bedrock_models.list_foundation_models(byOutputModality=by_output_modality)
		click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
	elif by_provider is not None and by_output_modality is not None:
		models = bedrock_models.list_foundation_models(
			byProvider=by_provider, byOutputModality=by_output_modality
		)
		click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))
	else:
		models = bedrock_models.list_foundation_models()
		click.echo(click.style(f"Models: {json.dumps(models, indent=4)}", fg="green"))


@cli.command("ask")
@click.option("--question", required=True, type=str, prompt=True, help="What do you like to ask?")
@click.option("--url", default=QDRANT_URL, help="Qdrant server URL")
@click.option("--api-key", default=QDRANT_API_KEY, help="Qdrant API key")
@click.option("--collection-name", default=COLLECTION_NAME, help="Qdrant collection name")
@click.option("--temperature", default=0.5, help="Randomness and creativity of the generated text")
@click.option("--top_k", default=250, help="Top k")
@click.option("--top_p", default=1, help="Top p")
@click.option("--stop_sequences", default=["Human"], help="Stop sequences")
@click.option(
	"--max_tokens_to_sample",
	default=200,
	help="Maximum number of tokens to sample from the model",
)
@click.option(
	"--model_name",
	default="anthropic.claude-v2",
	type=click.Choice(aws_llm, case_sensitive=True),
)
@click.option(
	"--embedding_model",
	default="amazon.titan-embed-text-v1",
	type=click.Choice(aws_embeddings),
	help="AWS embedding model name used to embedding the documents",
)
def question(
	question,
	url,
	api_key,
	collection_name,
	temperature,
	top_k,
	top_p,
	stop_sequences,
	max_tokens_to_sample,
	model_name,
	embedding_model,
):
	client = get_client(url, api_key)
	retriever = Qdrant(
		client=client,
		embeddings=get_embeddings(
			embedding=Embedding(embeddings=Embeddings.AWS, embedding_model=embedding_model)
		),
		collection_name=collection_name,
	).as_retriever(search_type="similarity", search_kwargs={"k": 2})

	prompt_template = get_prompt()

	prompt = PromptTemplate(template=prompt_template, input_variables=["context", "question"])

	# Bedrock Hyperparameters
	inference_modifier = {
		"max_tokens_to_sample": max_tokens_to_sample,
		"temperature": temperature,
		"top_k": top_k,
		"top_p": top_p,
		"stop_sequences": [f"\n\n{stop_sequences}"],
	}

	llm = Bedrock(model_id=model_name, client=bedrock_runtime, model_kwargs=inference_modifier)

	qa = RetrievalQA.from_chain_type(
		llm=llm,
		chain_type="stuff",
		retriever=retriever,
		return_source_documents=True,
		chain_type_kwargs={"prompt": prompt, "verbose": False},
	)

	result = qa({"query": question})
	answer = result["result"]
	click.echo(click.style(f"\nAnswer: {answer}", fg="green"))


if __name__ == "__main__":
	cli()
