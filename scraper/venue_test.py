# Unit tests for normalise_venue() in telegram_scraper.py.
#
# Importing telegram_scraper pulls in its dependencies (telethon, anthropic,
# firebase-admin, python-dotenv), so run these from the scraper folder with
# that environment active:   cd scraper && pytest venue_test.py
# No network or Firebase call happens on import, so this is safe.

from telegram_scraper import normalise_venue


def test_empty_venue_returns_unknown():
    assert normalise_venue('') == 'unknown'
    assert normalise_venue(None) == 'unknown'


def test_alias_maps_to_internal_name():
    # 'riverhouse' is an alias that normalises to the internal name 'yang'
    assert normalise_venue('Riverhouse Rooftop') == 'yang'


def test_keyword_match_is_case_insensitive():
    assert normalise_venue('MARQUEE') == 'marquee'
    assert normalise_venue('Cherry Discotheque') == 'cherry'


def test_unrecognised_venue_is_returned_lowercased():
    assert normalise_venue('Some Random Bar') == 'some random bar'
