import time
import json
import logging
import os
import re
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

COOKIE_DIR = "cookies"
os.makedirs(COOKIE_DIR, exist_ok=True)

class SocialMediaScraper:
    def __init__(self, instagram_user, instagram_pass, linkedin_user, linkedin_pass):
        self.instagram_user = instagram_user
        self.instagram_pass = instagram_pass
        self.linkedin_user = linkedin_user
        self.linkedin_pass = linkedin_pass
        self.driver = None

    def __enter__(self):
        logger.info("Initializing WebDriver for new request...")
        chrome_options = Options()
        chrome_options.add_argument('--log-level=3')
        chrome_options.add_experimental_option('excludeSwitches', ['enable-logging'])
        chrome_options.add_argument("--headless")  # remove when debugging
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        
        self.driver = webdriver.Chrome(options=chrome_options)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        logger.info("Closing WebDriver session.")
        if self.driver:
            self.driver.quit()

    def _save_cookies(self, filename):
        cookies = self.driver.get_cookies()
        with open(os.path.join(COOKIE_DIR, filename), "w") as f:
            json.dump(cookies, f)

    def _load_cookies(self, filename, url):
        path = os.path.join(COOKIE_DIR, filename)
        if os.path.exists(path):
            self.driver.get(url)
            with open(path, "r") as f:
                cookies = json.load(f)
                for cookie in cookies:
                    if "sameSite" in cookie and cookie["sameSite"] == "None":
                        cookie["sameSite"] = "Strict"
                    try:
                        self.driver.add_cookie(cookie)
                    except Exception:
                        continue
            self.driver.get(url)
            logger.info(f"Loaded cookies from {filename}")
            return True
        return False

    def _save_debug_info(self, name):
        self.driver.save_screenshot(f"{name}.png")
        with open(f"{name}.html", "w", encoding="utf-8") as f:
            f.write(self.driver.page_source)

    # ---------------- INSTAGRAM ----------------
    def _login_instagram(self):
        if not self.instagram_user or not self.instagram_pass:
            raise RuntimeError("Instagram credentials missing")

        if self._load_cookies("cookies_instagram.json", "https://www.instagram.com/"):
            return

        self.driver.get("https://www.instagram.com/accounts/login/")
        logger.info("Logging into Instagram...")

        try:
            WebDriverWait(self.driver, 15).until(EC.presence_of_element_located((By.NAME, "username"))).send_keys(self.instagram_user)
            self.driver.find_element(By.NAME, "password").send_keys(self.instagram_pass)
            self.driver.find_element(By.XPATH, "//button[@type='submit']").click()

            WebDriverWait(self.driver, 20).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "svg[aria-label='Home']"))
            )
            self._save_cookies("cookies_instagram.json")
            logger.info("Instagram login successful.")
        except Exception as e:
            self._save_debug_info("instagram_login_error")
            raise RuntimeError("Instagram login failed. Check credentials or selectors.") from e

    def scrape_instagram_profile(self, username: str):
        self._login_instagram()
        url = f"https://www.instagram.com/{username}/"
        logger.info(f"Scraping Instagram profile: {url}")

        try:
            self.driver.get(url)
            WebDriverWait(self.driver, 15).until(EC.visibility_of_element_located((By.CSS_SELECTOR, "header")))

            profile_data = {
                'post_count': 0,
                'followers': 0,
                'following': 0,
                'full_name': username,
                'biography': ""
            }

            stats_elements = self.driver.find_elements(By.CSS_SELECTOR, "header li")
            for item in stats_elements:
                text = item.text.lower()
                if 'post' in text:
                    profile_data['post_count'] = self._parse_count(text.split()[0])
                elif 'follower' in text:
                    profile_data['followers'] = self._parse_count(text.split()[0])
                elif 'following' in text:
                    profile_data['following'] = self._parse_count(text.split()[0])

            try:
                profile_data['full_name'] = self.driver.find_element(By.CSS_SELECTOR, "header section h2").text
            except NoSuchElementException:
                pass

            try:
                bio_element = self.driver.find_element(By.CSS_SELECTOR, "header section div.-vDIg")
                profile_data['biography'] = bio_element.text
            except NoSuchElementException:
                pass

            return {"profile": profile_data, "scraped_at": datetime.now().isoformat()}

        except Exception as e:
            self._save_debug_info(f"instagram_scrape_error_{username}")
            raise HTTPException(status_code=500, detail=f"Instagram scrape failed: {e}")

    # ---------------- LINKEDIN ----------------
    def _login_linkedin(self):
        if not self.linkedin_user or not self.linkedin_pass:
            raise RuntimeError("LinkedIn credentials missing")

        if self._load_cookies("cookies_linkedin.json", "https://www.linkedin.com/feed/"):
            logger.info("LinkedIn cookies loaded, skipping login.")
            return

        self.driver.get("https://www.linkedin.com/login")
        logger.info("Logging into LinkedIn...")

        try:
            WebDriverWait(self.driver, 15).until(EC.presence_of_element_located((By.ID, "username"))).send_keys(self.linkedin_user)
            self.driver.find_element(By.ID, "password").send_keys(self.linkedin_pass)
            self.driver.find_element(By.XPATH, "//button[@type='submit']").click()

            # Wait for 2FA approval
            logger.info("Waiting for LinkedIn 2FA approval... check your app/email.")
            time.sleep(20)

            WebDriverWait(self.driver, 30).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "img.global-nav__me-photo"))
            )
            self._save_cookies("cookies_linkedin.json")
            logger.info("LinkedIn login successful and cookies saved.")
        except Exception as e:
            self._save_debug_info("linkedin_login_error")
            raise RuntimeError("LinkedIn login failed (2FA likely). Please log in manually once.") from e

    def scrape_linkedin_company(self, company_name: str):
        self._login_linkedin()
        base_url = f"https://www.linkedin.com/company/{company_name}/"
        logger.info(f"Scraping LinkedIn company: {base_url}")

        try:
            self.driver.get(base_url + "about/")
            WebDriverWait(self.driver, 15).until(EC.visibility_of_element_located((By.CSS_SELECTOR, "main")))

            company_data = {"name": company_name}

            try:
                company_data['name'] = self.driver.find_element(By.CSS_SELECTOR, "main h1").text
            except NoSuchElementException:
                pass

            try:
                company_data['description'] = self.driver.find_element(By.CSS_SELECTOR, "section p").text
            except NoSuchElementException:
                company_data['description'] = ""

            return {"company": company_data, "scraped_at": datetime.now().isoformat()}

        except Exception as e:
            self._save_debug_info(f"linkedin_scrape_error_{company_name}")
            raise HTTPException(status_code=500, detail=f"LinkedIn scrape failed: {e}")

    def _parse_count(self, count_str: str) -> int:
        if not count_str: return 0
        num_str = re.search(r'[\d\.]+', count_str).group(0)
        count_str = count_str.strip().replace(',', '').lower()
        try:
            num = float(num_str)
            if 'k' in count_str:
                return int(num * 1000)
            elif 'm' in count_str:
                return int(num * 1000000)
            return int(num)
        except Exception:
            return 0


@app.get("/profile/{username}")
async def get_instagram_profile(username: str):
    try:
        with SocialMediaScraper(
            instagram_user=os.getenv("INSTAGRAM_USERNAME"),
            instagram_pass=os.getenv("INSTAGRAM_PASSWORD"),
            linkedin_user=os.getenv("LINKEDIN_USERNAME"),
            linkedin_pass=os.getenv("LINKEDIN_PASSWORD")
        ) as scraper:
            return scraper.scrape_instagram_profile(username)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/linkedin/{company_name}")
async def get_linkedin_company(company_name: str):
    try:
        with SocialMediaScraper(
            instagram_user=os.getenv("INSTAGRAM_USERNAME"),
            instagram_pass=os.getenv("INSTAGRAM_PASSWORD"),
            linkedin_user=os.getenv("LINKEDIN_USERNAME"),
            linkedin_pass=os.getenv("LINKEDIN_PASSWORD")
        ) as scraper:
            return scraper.scrape_linkedin_company(company_name)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}
