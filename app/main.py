from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, HttpUrl
from app.storage import save_url, get_url

# router
app = FastAPI()

class ShortenRequest(BaseModel):
    url:HttpUrl

class ShortenResponse(BaseModel):
    code: str
    short_url: str

# post endpoint: takes user's input and stores shortened one
@app.post("/shorten", response_model=ShortenResponse)
def shorten(request: ShortenRequest):
    code = save_url(str(request.url))
    return ShortenResponse(code=code, short_url=f"/{code}")

# get endpoint: looks up in storage for original url and redirects user
@app.get("/{code}")
def redirect(code: str):
    long_url = get_url(code)
    if not long_url:
        raise HTTPException(status_code=404, detail="code not found")
    return RedirectResponse(url=long_url, status_code=301)
