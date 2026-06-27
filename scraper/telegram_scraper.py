import asyncio
import json
from datetime import datetime, timezone, timedelta
from telethon import TelegramClient
import anthropic
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
import os

load_dotenv()

API_ID = os.getenv('TELEGRAM_API_ID')
API_HASH = os.getenv('TELEGRAM_API_HASH')
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY')

CHANNELS = [
    '@makecherrygr8again',
    '@nusclubbing',
    '@miggyt_guestlist',
    '@yangclubsg',
    '@ntuclubbing',
    '@djhanzo',
    '@marqueesgofficial'
]

DAYS_TO_LOOK_BACK = 7


def init_firestore():
    if not firebase_admin._apps:
        cred = credentials.Certificate('scraper/serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
    return firestore.client()


def extract_event_with_claude(message_text, channel_name, message_date):
    client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)
    prompt = f"""You are extracting nightclub event information from a Telegram message posted in Singapore.

Channel: {channel_name}
Message:
{message_text}

If this message is a nightclub event announcement, extract the following fields and return as JSON.
If it is NOT an event announcement (e.g. post-event thanks, random chat, ticket resale), return null.

Fields to extract:
- name: event name or night theme (string)
- venue: club or venue name (string)
- date: in YYYY-MM-DD format. This message was sent on {message_date}. Dates in messages are in DD.MM or DD.MM.YYYY format (e.g. "10.06" means June 10, not October 6). Use context clues like "tonight", "this Friday", "03.06" to determine the date. If no explicit date is mentioned, assume the event is on the same day the message was sent. (string)
- genres: list of music genres mentioned (list of strings)
- time: doors open time e.g. "10:00 PM" (string or null)
- price: entry/ticket price only, ignore bottle or sofa package prices (string or null)"
- has_guestlist: true if guestlist is mentioned (boolean)
- guestlist_url: URL to guestlist form if present (string or null)

Return only valid JSON, no explanation. If not an event, return the word null."""

    message = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=500,
        messages=[{"role": "user", "content": prompt}]
    )

    response_text = message.content[0].text.strip()
    response_text = response_text.replace('```json', '').replace('```', '').strip()

    if response_text.lower() == 'null':
        return None

    try:
        parsed = json.loads(response_text)
        if isinstance(parsed, list):
            return parsed
        return [parsed]
    except json.JSONDecodeError:
        print(f"Could not parse Claude response: {response_text}")
        return None


VENUE_KEYWORDS = ['yang', 'riverhouse', 'cherry', 'marquee', 'zouk', 'canvas', 'dashi']

VENUE_MAP = {
    'riverhouse': 'yang',
}

def normalise_venue(venue_str):
    if not venue_str:
        return 'unknown'
    v = venue_str.lower()
    for keyword in VENUE_KEYWORDS:
        if keyword in v:
            return VENUE_MAP.get(keyword, keyword)
    return v


def write_event_to_firestore(db, event, source_channel):
    if not event.get('name') or not event.get('date'):
        return

    if isinstance(event.get('dj'), list):
        event['dj'] = ', '.join(event['dj'])

    if source_channel == '@miggyt_guestlist' :
        event['venue'] = 'Dashi Gogo'

    event['source'] = source_channel
    event['crowd_level'] = 'Medium'
    event['sort_order'] = 0
    event['image_url'] = ''
    event['booking_url'] = event.get('guestlist_url', '')

    venue_raw = event.get('venue', event.get('name', 'unknown'))
    venue = normalise_venue(venue_raw).replace(' ', '-')
    doc_id = venue + '-' + event['date']

    existing = db.collection('events').document(doc_id).get()
    if existing.exists:
        existing_data = existing.to_dict() #converts firestore doc to python
        existing_score = sum(1 for v in existing_data.values() if v) #count how many fields in existing doc have non empty values
        new_score = sum(1 for v in event.values() if v) #same thing but for new event youre about to write
        if existing_score > new_score:
            print(f"  Skipped (existing has more info): {event['name']}")
            return  #if existing doc has equal or more filled fields, skip the write (keep existing doc) and exit fxn

    db.collection('events').document(doc_id).set(event)
    print(f"Written: {event['name']} on {event['date']} from {source_channel}")
   


async def scrape_channels():
    db = init_firestore()
    cutoff = datetime.now(timezone.utc) - timedelta(days=DAYS_TO_LOOK_BACK)

    async with TelegramClient('scraper/after_hours', API_ID, API_HASH) as client:
        for channel in CHANNELS:
            print(f"\nScraping {channel}...")

            try:
                messages = await client.get_messages(channel, limit=30)

                for message in messages:
                    if not message.text:
                        continue
                    if message.date < cutoff:
                        continue
                    if len(message.text.strip()) < 20:
                        continue

                    print(f"  Processing: {message.text[:60]}...")

                    message_date = message.date.astimezone(timezone(timedelta(hours=8))).strftime('%Y-%m-%d')
                    events = extract_event_with_claude(message.text, channel, message_date)
                    if events:
                        for event in events:
                            write_event_to_firestore(db, event, channel)
                    else:
                        print(f"  Skipped — not an event announcement")

            except Exception as e:
                print(f"  ERROR on {channel}: {e}")


if __name__ == "__main__":
    asyncio.run(scrape_channels())