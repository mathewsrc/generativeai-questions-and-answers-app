import os
import click
from transformers import pipeline, AutoTokenizer, AutoModelForCausalLM
from dotenv import load_dotenv
import sys

module_path = ".."
sys.path.append(os.path.abspath(module_path))
from global_variables import COLLECTION_NAME
from langchain_community.vectorstores.qdrant import Qdrant
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA
from langchain_community.llms.huggingface_pipeline import HuggingFacePipeline
from utils import (
	get_client,
	get_embeddings,
	get_prompt,
	huggingface_embeddings,
	huggingface_llm,
)

load_dotenv()

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")


@click.command("ask")
@click.option("--question", required=True, type=str, prompt=True, help="What do you like to ask?")
@click.option("--url", default=QDRANT_URL, help="Qdrant server URL")
@click.option("--api-key", default=QDRANT_API_KEY, help="Qdrant API key")
@click.option("--collection_name", default=COLLECTION_NAME, help="Qdrant collection name")
@click.option(
	"--model-name",
	default="TinyLlama/TinyLlama-1.1B-Chat-v1.0",
	type=click.Choice(huggingface_llm),
	help="HuggingFace Text-Generation model name",
)
@click.option(
	"--embedding-model",
	default="sentence-transformers/all-MiniLM-L6-v2",
	type=click.Choice(huggingface_embeddings),
	help="HuggingFace embedding model name used to embedding the documents",
)
def ask(question, url, api_key, collection_name, model_name, embedding_model):
	try:
		# Ask for confirmation
		confirmation = click.confirm(
			"""
                                     This will donwload the model locally.
                                     Do you want to continue?
                                     """
		)

		if confirmation:
			tokenizer = AutoTokenizer.from_pretrained(model_name)
			model = AutoModelForCausalLM.from_pretrained(model_name)
			pipe = pipeline(
				"text-generation",
				model=model,
				tokenizer=tokenizer,
				token=os.environ.get("HUGGINGFACE_TOKEN"),
			)

			llm = HuggingFacePipeline(
				pipeline=pipe, model_kwargs={"temperature": 0.4, "max_length": 500}
			)

			client = get_client(url, api_key)

			retriever = Qdrant(
				client=client,
				embeddings=get_embeddings(model_name=embedding_model),
				collection_name=collection_name,
			).as_retriever(search_type="similarity", search_kwargs={"k": 2})

			prompt_template = get_prompt()
			prompt = PromptTemplate.from_template(prompt_template)

			chain = RetrievalQA.from_chain_type(
				llm=llm,
				chain_type="stuff",
				retriever=retriever,
				return_source_documents=True,
				chain_type_kwargs={"prompt": prompt, "verbose": False},
			)
			result = chain.invoke({"query": question})
			click.echo(click.style(f"\nAnswer: {result['result']}", fg="green"))
		else:
			click.echo(click.style("Exiting...", fg="red"))
			return
	except Exception as e:
		click.echo(click.style(f"Error: {e}", fg="red"))
		return
