import os
from dotenv import load_dotenv
from garminconnect import Garmin
import garth

load_dotenv()

TOKEN_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".garth_tokens")
os.makedirs(TOKEN_DIR, exist_ok=True)

print("Logging in to Garmin...")
client = Garmin(os.getenv("GARMIN_EMAIL"), os.getenv("GARMIN_PASSWORD"))
client.login()

# Save the garth session to our project folder
client.garth.dump(TOKEN_DIR)
print(f"Token saved to: {TOKEN_DIR}")
print("Files:", os.listdir(TOKEN_DIR))