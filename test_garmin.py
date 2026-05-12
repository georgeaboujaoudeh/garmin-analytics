import os
from dotenv import load_dotenv
from garminconnect import Garmin

load_dotenv()

client = Garmin(os.getenv("GARMIN_EMAIL"), os.getenv("GARMIN_PASSWORD"))
client.login()

# Pull last 5 activities
activities = client.get_activities(0, 5)
for a in activities:
    print(f"{a['startTimeLocal']} | {a['activityType']['typeKey']} | {a.get('distance', 0)/1000:.2f} km")