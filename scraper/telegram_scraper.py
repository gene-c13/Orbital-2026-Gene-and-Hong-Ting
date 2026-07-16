import asyncio
import json
from datetime import datetime, timezone, timedelta
from telethon import TelegramClient
from telethon.tl.types import MessageEntityTextUrl
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
- dj: DJ name(s) performing. Might follow "ft" (string or null)
- guestlist_url: URL to guestlist form, or ticket form, if present. If the message includes a "[Hidden links in this message]" section, prefer a URL from there whose label suggests tickets, guestlist, RSVP, or sign up. (string or null)

Return only valid JSON, no explanation. If not an event, return the word null."""

    message = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=500,
        messages=[{"role": "user", "content": prompt}]
    )

    # message.content can hold more than one block (e.g. a thinking block ahead of
    # the actual answer), so grab the block whose type is "text" instead of assuming
    # the answer is always at position [0]
    text_blocks = [block.text for block in message.content if block.type == "text"]
    response_text = "".join(text_blocks).strip()
    response_text = response_text.replace('```json', '').replace('```', '').strip()

    if response_text.lower() == 'null':
        return None

    try:
        parsed = json.loads(response_text) #converts json text to python dict
        if isinstance(parsed, list):
            return parsed #edge case of a JSON arrary returned 
        return [parsed] #always wrap dict(event) in a list(events)
    except json.JSONDecodeError:
        print(f"Could not parse Claude response: {response_text}")
        return None


def enrich_with_hidden_links(message):
    # Telegram lets someone hyperlink a word/phrase to a URL that never shows up in
    # the plain text (e.g. "TAP HERE" linking to a Google Form behind the scenes).
    # get_entities_text() pulls out (entity, display_text) pairs for us — it also
    # handles Telegram's UTF-16 offset counting internally, which is easy to get
    # wrong doing it by hand, so it's worth using instead of slicing the text ourselves.
    hidden_links = message.get_entities_text(MessageEntityTextUrl)
    if not hidden_links:
        return message.text

    links_section = "\n".join(f'"{label}" links to: {entity.url}' for entity, label in hidden_links)
    return f"{message.text}\n\n[Hidden links in this message]\n{links_section}"


VENUE_KEYWORDS = ['yang', 'riverhouse', 'cherry', 'marquee', 'zouk', 'canvas', 'dashi']

VENUE_MAP = {
    'riverhouse': 'yang',
}

VENUE_DISPLAY_NAMES = {
    'yang': 'Yang',
    'cherry': 'Cherry',
    'marquee': 'Marquee',
    'zouk': 'Zouk',
    'canvas': 'Canvas',
    'dashi': 'Dashi Gogo',
}

def normalise_venue(venue_str):
    if not venue_str:
        return 'unknown'
    v = venue_str.lower()
    for keyword in VENUE_KEYWORDS: 
        if keyword in v: #eg. cherry discotheque has "cherry"
            return VENUE_MAP.get(keyword, keyword) #eg. since "cherry" not in venue_map, return "cherry"
    return v


def score(data):
    #counts how many fields in a firestore doc dict have non-empty values
    return sum(1 for v in data.values() if v)


def resolve_duplicate(db, doc_id, existing_snapshot, event):
    #given an existing doc already identified as a duplicate of event, keeps
    #whichever version has more filled-in fields
    existing_data = existing_snapshot.to_dict() #converts firestore doc to python
    existing_score = score(existing_data) #count how many fields in existing doc have non empty values
    new_score = score(event) #same thing but for new event youre about to write
    if new_score > existing_score:
        db.collection('events').document(doc_id).set(event)
        print(f"  Replaced duplicate with more complete version: {event['name']} — {doc_id}")
    else:
        print(f"  Skipped (existing has more info): {event['name']} — {doc_id} already exists") #if existing doc has equal or more filled fields, skip the write (keep existing doc)


def write_event_to_firestore(db, event, source_channel):
    if not event.get('name') or not event.get('date'):
        return

    if isinstance(event.get('dj'), list):
        event['dj'] = ', '.join(event['dj']) #add a , separator between each dj in the list

    if source_channel == '@miggyt_guestlist' :
        event['venue'] = 'Dashi Gogo'

    event['source'] = source_channel
    event['crowd_level'] = 'Medium'
    event['sort_order'] = 0
    event['image_url'] = ''
    event['booking_url'] = event.get('guestlist_url', '')

    # .get(key, default) only falls back when the key is missing — Claude sometimes
    # returns "venue": null explicitly, which .get() would happily pass through as
    # None instead of catching it, so `or` is used here to fall through on that too
    venue_raw = event.get('venue') or event.get('name') or 'unknown'
    venue_norm = normalise_venue(venue_raw)
    if venue_norm == 'zouk' :
        print (f" Skipped (Zouk handled by zouk_scraper.py) : {event['name']}")
        return
    event['venue'] = VENUE_DISPLAY_NAMES.get(venue_norm,venue_raw.strip().title())
    venue = venue_norm.replace(' ', '-')
    doc_id = venue + '-' + event['date']

    #deduplication logic
    existing = db.collection('events').document(doc_id).get()
    if existing.exists:
        resolve_duplicate(db, doc_id, existing, event)
        return

    # check if this venue already has an event with the SAME NAME on an adjacent date
    # (±1 day) — prevents duplicates when a repost makes Claude extract a slightly
    # different date for the same event, without wrongly skipping a genuinely
    # different event that just happens to land at the same venue the day before/after
    event_date = datetime.strptime(event['date'], '%Y-%m-%d')
    for offset in [-1, 1]: #a for-loop over 2 item list, first iteration:date-1, second:date +1
        neighbour_date = (event_date + timedelta(days=offset)).strftime('%Y-%m-%d')
        neighbour_id = venue + '-' + neighbour_date
        neighbour = db.collection('events').document(neighbour_id).get()
        if neighbour.exists and neighbour.to_dict().get('name', '').strip().lower() == event['name'].strip().lower():
            resolve_duplicate(db, neighbour_id, neighbour, event)
            return

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
                    enriched_text = enrich_with_hidden_links(message)
                    events = extract_event_with_claude(enriched_text, channel, message_date)
                    if events:
                        for event in events:
                            write_event_to_firestore(db, event, channel)
                    else:
                        print(f"  Skipped — not an event announcement")

            except Exception as e:
                print(f"  ERROR on {channel}: {e}")


if __name__ == "__main__":
    asyncio.run(scrape_channels())