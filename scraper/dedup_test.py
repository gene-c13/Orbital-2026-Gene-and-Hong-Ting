# Unit tests for score() and resolve_duplicate() in telegram_scraper.py -
# the logic that decides which of two conflicting event records to keep
# when the same event gets scraped twice.
#
# resolve_duplicate() normally talks to a real Firestore client and a real
# document snapshot. Here we hand it fake stand-ins (MagicMock, from
# Python's standard library) instead - it doesn't know the difference, it
# just calls .to_dict(), .collection(), .document() and .set() the same
# way it would on the real thing, and we check which calls happened.
#
# Run:  cd scraper && pytest dedup_test.py

from unittest.mock import MagicMock
from telegram_scraper import score, resolve_duplicate


def test_score_counts_only_non_empty_fields():
    # dj='' , price=None and genres=[] are all "empty" and don't count
    assert score({'name': 'Neon Nights', 'dj': '', 'price': None, 'genres': []}) == 1


def test_score_of_a_fully_filled_record():
    assert score({'name': 'Neon Nights', 'dj': 'DJ Test', 'price': '$20'}) == 3


def test_score_of_an_empty_record_is_zero():
    assert score({}) == 0


def test_new_event_replaces_existing_when_it_has_more_info():
    db = MagicMock()
    existing_snapshot = MagicMock()
    existing_snapshot.to_dict.return_value = {'name': 'Neon Nights'}  # score 1
    new_event = {'name': 'Neon Nights', 'dj': 'DJ Test', 'price': '$20'}  # score 3

    resolve_duplicate(db, 'zouk-2026-07-20', existing_snapshot, new_event)

    db.collection.assert_called_with('events')
    db.collection.return_value.document.assert_called_with('zouk-2026-07-20')
    db.collection.return_value.document.return_value.set.assert_called_with(new_event)


def test_existing_event_is_kept_when_the_new_one_has_less_info():
    db = MagicMock()
    existing_snapshot = MagicMock()
    existing_snapshot.to_dict.return_value = {
        'name': 'Neon Nights', 'dj': 'DJ Test', 'price': '$20',
    }  # score 3
    new_event = {'name': 'Neon Nights'}  # score 1

    resolve_duplicate(db, 'zouk-2026-07-20', existing_snapshot, new_event)

    db.collection.return_value.document.return_value.set.assert_not_called()


def test_a_tie_keeps_the_existing_event_rather_than_overwriting():
    db = MagicMock()
    existing_snapshot = MagicMock()
    existing_snapshot.to_dict.return_value = {'name': 'Neon Nights', 'dj': 'DJ Test'}  # score 2
    new_event = {'name': 'Neon Nights', 'price': '$20'}  # score 2

    resolve_duplicate(db, 'zouk-2026-07-20', existing_snapshot, new_event)

    db.collection.return_value.document.return_value.set.assert_not_called()
