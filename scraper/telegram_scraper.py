import asyncio
import json
import re
from datetime import datetime, timezone, timedelta
from telethon import TelegramClient
import anthropic
import firebase_admin
from firebase_admin import credentials, firestore

API_ID = 30661011
API_HASH = '5db6afb05920372ccbce80b8c34904ce'
ANTHROPIC_API_KEY = 'your-anthropic-api-key-here'

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


def extract_event_with_claude(message_text, channel_name):
    client = anthropic.Anthropic(api_key='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')
    prompt = f"""You are extracting nightclub event information from a Telegram message posted in Singapore.

Channel: {channel_name}
Message:
{message_text}

If this message is a nightclub event announcement, extract the following fields and return as JSON.
If it is NOT an event announcement (e.g. post-event thanks, random chat, ticket resale), return null.

Fields to extract:
- name: event name or night theme (string)
- venue: club or venue name (string)
- date: in YYYY-MM-DD format. Today is {datetime.now().strftime('%Y-%m-%d')}. Use context clues like "tonight", "this Friday", "03.06" to determine the date. (string)
- dj: DJ name(s) comma separated (string)
- genres: list of music genres mentioned (list of strings)
- time: doors open time e.g. "10:00 PM" (string or null)
- price: entry price if mentioned e.g. "$25" (string or null)
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


def write_event_to_firestore(db, event, source_channel):
    if not event.get('name') or not event.get('date'):
        return

    event['source'] = source_channel
    event['crowd_level'] = 'Medium'
    event['sort_order'] = 0
    event['image_url'] = ''
    event['booking_url'] = event.get('guestlist_url', '')

    doc_id = event['name'].lower().replace(' ', '-') + '-' + event['date']
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

                    events = extract_event_with_claude(message.text, channel)
                    if events:
                        for event in events:
                            write_event_to_firestore(db, event, channel)
                    else:
                        print(f"  Skipped — not an event announcement")

            except Exception as e:
                print(f"  ERROR on {channel}: {e}")


if __name__ == "__main__":
    asyncio.run(scrape_channels())