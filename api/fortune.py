import json
import subprocess
from fastapi import FastAPI

def get_fortune(short=True, count=256):
    categories = ["platitudes", "paradoxum", "humorists", "disclaimer", "education", "science", "wisdom", "literature", "love", "magic", "miscellaneous", "fortunes", "goedel", "people"]
    args = ["/usr/games/fortune", "-n", str(count)]
    if short:
        args.append("-s")
    args+=categories
    result = subprocess.run(args, capture_output=True, text=True)
    return {"fortune": result.stdout}

app = FastAPI()

@app.get("/")
async def root():
    return get_fortune()
