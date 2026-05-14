from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
        return {"Hello": "World"}

@app.get("/health")
def read_item():
        return {"status": "ok"}