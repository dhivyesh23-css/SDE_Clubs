# backend/main.py

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware # <-- ADD THIS IMPORT
import instaloader
import logging

# --- Configuration ---
INSTAGRAM_USERNAME = "c.dhivyesh" # Make sure this is your username

app = FastAPI()

# --- ADD THIS ENTIRE BLOCK FOR CORS ---
origins = [
    "http://localhost",
    "http://localhost:8080",
    # The port Flutter web runs on can vary, so we can use a wildcard or add specific ports
    "http://localhost:60551", # Example port, check your terminal for the actual one
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allows all origins for simplicity in development
    allow_credentials=True,
    allow_methods=["*"], # Allows all methods
    allow_headers=["*"], # Allows all headers
)
# --- END OF CORS BLOCK ---


loader = instaloader.Instaloader()

try:
    loader.load_session_from_file(INSTAGRAM_USERNAME)
    logging.info("Session loaded successfully.")
except FileNotFoundError:
    logging.error(f"Session file for {INSTAGRAM_USERNAME} not found.")

@app.get("/profile/{username}")
def get_profile_data(username: str):
    try:
        profile = instaloader.Profile.from_username(loader.context, username)
        profile_data = {
            "followers": profile.followers,
            "following": profile.followees,
            "post_count": profile.mediacount,
            "full_name": profile.full_name,
            "biography": profile.biography,
            "profile_pic_url": profile.profile_pic_url
        }
        recent_posts = []
        for post in profile.get_posts():
            recent_posts.append({
                "likes": post.likes,
                "date_utc": str(post.date_utc),
            })
            if len(recent_posts) >= 5:
                break
        response_data = {
            "profile": profile_data,
            "recent_posts": recent_posts
        }
        return JSONResponse(content=response_data)
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": f"An error occurred: {str(e)}"})