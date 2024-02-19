from fastapi.testclient import TestClient

from src.app.main import app

client = TestClient(app)


def test_root_endpoint():
	response = client.get("/")
	assert response.status_code == 200
	assert "<h1>Welcome to our Question/Answering application" in response.text


def test_question_endpoint():
	response = client.post("/ask", json={"text": "What is AWS?", "temperature": 0.5})
	assert response.status_code == 200
	assert "answer" in response.json()
