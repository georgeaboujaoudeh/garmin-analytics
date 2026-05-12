import os
import json
from datetime import date, timedelta
from dotenv import load_dotenv
from garminconnect import Garmin
import psycopg2
from psycopg2.extras import Json

load_dotenv()

# ---- Connect to Garmin ----
client = Garmin(os.getenv("GARMIN_EMAIL"), os.getenv("GARMIN_PASSWORD"))
client.login()
print("Garmin login OK")

# ---- Connect to Postgres ----
conn = psycopg2.connect(
    host="localhost",
    port=5433,
    dbname="garmin",
    user="garmin",
    password="garmin"
)
conn.autocommit = True
cur = conn.cursor()
print("Postgres connection OK")

# ---- Create raw schema and tables ----
cur.execute("CREATE SCHEMA IF NOT EXISTS raw;")

cur.execute("""
CREATE TABLE IF NOT EXISTS raw.activities (
    activity_id BIGINT PRIMARY KEY,
    payload JSONB,
    loaded_at TIMESTAMP DEFAULT NOW()
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS raw.daily_stats (
    stat_date DATE PRIMARY KEY,
    payload JSONB,
    loaded_at TIMESTAMP DEFAULT NOW()
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS raw.sleep (
    sleep_date DATE PRIMARY KEY,
    payload JSONB,
    loaded_at TIMESTAMP DEFAULT NOW()
);
""")

print("Tables ready")

# ---- Pull activities (last 500) ----
print("Pulling activities...")
activities = client.get_activities(0, 500)
for a in activities:
    cur.execute(
        """INSERT INTO raw.activities (activity_id, payload)
           VALUES (%s, %s)
           ON CONFLICT (activity_id) DO UPDATE SET payload = EXCLUDED.payload, loaded_at = NOW();""",
        (a["activityId"], Json(a))
    )
print(f"Loaded {len(activities)} activities")

# ---- Pull daily stats + sleep for last 365 days ----
print("Pulling daily stats and sleep (this may take a few minutes)...")
today = date.today()
for i in range(365):
    d = today - timedelta(days=i)
    d_str = d.isoformat()

    try:
        stats = client.get_stats(d_str)
        if stats:
            cur.execute(
                """INSERT INTO raw.daily_stats (stat_date, payload)
                   VALUES (%s, %s)
                   ON CONFLICT (stat_date) DO UPDATE SET payload = EXCLUDED.payload, loaded_at = NOW();""",
                (d, Json(stats))
            )
    except Exception as e:
        print(f"  stats {d_str} skipped: {e}")

    try:
        sleep = client.get_sleep_data(d_str)
        if sleep and sleep.get("dailySleepDTO"):
            cur.execute(
                """INSERT INTO raw.sleep (sleep_date, payload)
                   VALUES (%s, %s)
                   ON CONFLICT (sleep_date) DO UPDATE SET payload = EXCLUDED.payload, loaded_at = NOW();""",
                (d, Json(sleep))
            )
    except Exception as e:
        print(f"  sleep {d_str} skipped: {e}")

    if i % 30 == 0:
        print(f"  ...{i} days processed")

print("Done.")
cur.close()
conn.close()