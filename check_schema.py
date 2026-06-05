import urllib.request
import json

url = "https://wjxdzgkxnccsvtyjzlto.supabase.co/rest/v1/"
headers = {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqeGR6Z2t4bmNjc3Z0eWp6bHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MTU3NzgsImV4cCI6MjA5NTM5MTc3OH0.uMqy_-1k3FHDVZ0U0U-dxkop13OHHz1A-Cw_KorkECM",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqeGR6Z2t4bmNjc3Z0eWp6bHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MTU3NzgsImV4cCI6MjA5NTM5MTc3OH0.uMqy_-1k3FHDVZ0U0U-dxkop13OHHz1A-Cw_KorkECM"
}

req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        spec = json.loads(response.read().decode())
        definitions = spec.get("definitions", {})
        booking_history = definitions.get("booking_history", {})
        properties = booking_history.get("properties", {})
        print("COLUMNS FOR booking_history:")
        for col, details in properties.items():
            print(f"- {col}: {details.get('type')}")
except Exception as e:
    print("Error:", e)
