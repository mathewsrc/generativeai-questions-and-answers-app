# create a hello world fastapi

from fastapi import FastAPI
from pydantic import BaseModel


class Item(BaseModel):
    name: str
  
app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World 222"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)



    