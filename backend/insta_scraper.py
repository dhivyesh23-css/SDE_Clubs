from fastapi import FastAPI
from fastapi.responses import JSONResponse
import instaloader

app = FastAPI()
loader = instaloader.Instaloader()

@app.get("/posts/{username}")
def get_posts(username: str):
    try:
        profile = instaloader.Profile.from_username(loader.context, username)
        posts = []
        for post in profile.get_posts():
            posts.append({
                "caption": post.caption,
                "likes": post.likes,
                "url": post.url,
                "date": str(post.date),
            })
            if len(posts) >= 5:  # limit for speed
                break
        return JSONResponse(content=posts)
    except Exception as e:
        return {"error": str(e)}
