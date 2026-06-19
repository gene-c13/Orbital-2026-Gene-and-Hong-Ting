import re
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import anthropic
import json
import firebase_admin
from firebase_admin import credentials, firestore

ANTHROPIC_API_KEY = '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'

def extract_dj_with_claude(description):
    # use claude to extract just the DJ name(s) from the description text
    client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)
    prompt = f"""Extract the DJ or artist name(s) from this nightclub event description.

Description: {description}

Return only a JSON object with one field:
- dj: DJ or artist name(s) only, comma separated (string). If no DJ is mentioned, return "".

Example: {{"dj": "Ghetto, Krisha"}}

Return only valid JSON, no explanation."""

    message = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=100,
        messages=[{"role": "user", "content": prompt}]
    )

    response_text = message.content[0].text.strip()
    response_text = response_text.replace('```json', '').replace('```', '').strip()

    try:
        parsed = json.loads(response_text)
        return parsed.get("dj", "")
    except:
        return ""



def get_driver():
    options = webdriver.ChromeOptions()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=options
    )
    return driver
#driver is the selenium controlled chrome browser. 


def get_event_links(driver):
    driver.get("https://zoukgroup.com/singapore/events/") #driver is an object, thus it has .get method
    time.sleep(5)

    soup = BeautifulSoup(driver.page_source, "html.parser")

    all_links = soup.find_all("a")
    print(f"Total <a> tags found: {len(all_links)}")
    for link in all_links[:15]:
        print(link.get("href"))

    event_links = soup.find_all("a", href=re.compile(r"/event/"))
    print(f"\nEvent links found: {len(event_links)}")
    for link in event_links[:5]:
        print("href:", link.get("href"))
        print("text:", link.get_text(separator=" ", strip=True))
        print("---")

    events = []
    seen = set()

    for link in event_links:
        href = link.get("href")
        text = link.get_text(separator=" ", strip=True)

        if not text or len(text) < 3:
            continue
        if href.startswith("/"):
            href = "https://zoukgroup.com" + href
        if href in seen:
            continue

        seen.add(href)

        venue_slug = href.split("/")[4]
        venue_map = {
            "capital": "Capital",
            "zouk": "Zouk Mainroom",
            "phuture": "Phuture",
        }
        venue = venue_map.get(venue_slug, venue_slug.title())

        events.append({
            "url": href,
            "venue": venue,
        })

    return events


def scrape_event_detail(driver, event_url):
    driver.get(event_url)
    time.sleep(8)

    soup = BeautifulSoup(driver.page_source, "html.parser")

    title_tag = soup.find("title")
    name = title_tag.text.split(" | ")[0].strip() if title_tag else "Unknown"

    date_match = re.search(r"EVE(\d+)", event_url)
    if date_match:
        raw_date = date_match.group(1)[-8:]
        date = f"{raw_date[:4]}-{raw_date[4:6]}-{raw_date[6:]}"
    else:
        date = ""

    desc_tag = soup.find("meta", {"name": "description"})
    description = desc_tag.get("content", "").strip() if desc_tag else ""
    print(f"  Description: {description}")

    dj = extract_dj_with_claude(description)

    img_tag = soup.find("meta", {"name": "twitter:image"})
    image_url = img_tag.get("content", "") if img_tag else ""

    price_tags = soup.find_all("span", class_="uwsprice")
    prices = []
    for tag in price_tags:
        text = tag.get_text(strip=True)
        match = re.search(r'\d+\.?\d*', text)
        if match:
            prices.append(float(match.group()))
    price = f"${int(min(prices))}" if prices else ""

    return {
        "name": name,
        "date": date,
        "description": description,
        "image_url": image_url,
        "dj":dj,
        "price": price,
    }


def scrape_all_events():
    print("Starting browser...")
    driver = get_driver()

    try:
        print("Fetching event list...")
        events = get_event_links(driver)
        print(f"\nFinal event count: {len(events)}")

        results = []

        for i, event in enumerate(events):
            print(f"Scraping {i+1}/{len(events)}: {event['url']}")
            detail = scrape_event_detail(driver, event["url"])

            full_event = {
                "name": detail["name"],
                "venue": event["venue"],
                "date": detail["date"],
                "description": detail["description"],
                "image_url": detail["image_url"],
                "booking_url": event["url"],
                "dj": detail["dj"],
                "time": "10:00 PM",
                "price": detail["price"],
                "crowd_level": "Medium",
                "genres": [],
                "has_guestlist": False,
                "sort_order": i,
            }

            results.append(full_event)

    finally:
        driver.quit()

    return results


def write_to_firestore(events):
    cred = credentials.Certificate("scraper/serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    for event in events:
        doc_id = event["name"].lower().replace(" ", "-") + "-" + event["date"]
        db.collection("events").document(doc_id).set(event)
        print(f"Written: {event['name']} on {event['date']}")


if __name__ == "__main__":
    events = scrape_all_events()
    for e in events:
        print(e)
    write_to_firestore(events)