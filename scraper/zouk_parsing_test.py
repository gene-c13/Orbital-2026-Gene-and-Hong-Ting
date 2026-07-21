# Unit tests for the pure-parsing halves of zouk_scraper.py:
# parse_event_links(), extract_date_from_url() and parse_event_page().
# These take a saved HTML string / URL directly - no live browser, no
# Claude API call - so they run fast and don't need Selenium to launch.
#
# Run:  cd scraper && pytest zouk_parsing_test.py

from zouk_scraper import parse_event_links, extract_date_from_url, parse_event_page


LIST_PAGE_HTML = """
<html><body>
<a href="/singapore/capital/event/EVE20260720001/neon-nights">Neon Nights</a>
<a href="/singapore/zouk/event/EVE20260721002/techno-thursday">Techno Thursday</a>
<a href="/singapore/riverside/event/EVE20260722003/some-night">Some Night</a>
<a href="/singapore/about-us">About Us</a>
<a href="/singapore/capital/event/EVE20260720001/neon-nights">Neon Nights</a>
<a href="/singapore/capital/event/EVE20260723004/aa">Aa</a>
</body></html>
"""


def test_parses_venue_and_url_from_each_event_link():
    events = parse_event_links(LIST_PAGE_HTML)
    urls = [e["url"] for e in events]
    assert "https://zoukgroup.com/singapore/capital/event/EVE20260720001/neon-nights" in urls


def test_maps_known_venue_slugs_to_display_names():
    events = parse_event_links(LIST_PAGE_HTML)
    by_url = {e["url"]: e["venue"] for e in events}
    assert by_url["https://zoukgroup.com/singapore/capital/event/EVE20260720001/neon-nights"] == "Capital"
    assert by_url["https://zoukgroup.com/singapore/zouk/event/EVE20260721002/techno-thursday"] == "Zouk Mainroom"


def test_falls_back_to_a_title_cased_slug_for_an_unmapped_venue():
    events = parse_event_links(LIST_PAGE_HTML)
    by_url = {e["url"]: e["venue"] for e in events}
    assert by_url["https://zoukgroup.com/singapore/riverside/event/EVE20260722003/some-night"] == "Riverside"


def test_ignores_links_that_are_not_event_pages():
    events = parse_event_links(LIST_PAGE_HTML)
    urls = [e["url"] for e in events]
    assert not any("about-us" in u for u in urls)


def test_skips_duplicate_links_to_the_same_event():
    events = parse_event_links(LIST_PAGE_HTML)
    urls = [e["url"] for e in events]
    assert urls.count("https://zoukgroup.com/singapore/capital/event/EVE20260720001/neon-nights") == 1


def test_skips_links_whose_text_is_too_short_to_be_a_real_title():
    events = parse_event_links(LIST_PAGE_HTML)
    urls = [e["url"] for e in events]
    assert not any("EVE20260723004" in u for u in urls)


def test_extracts_the_date_from_a_standard_event_url():
    url = "https://zoukgroup.com/singapore/capital/event/EVE20260720/neon-nights"
    assert extract_date_from_url(url) == "2026-07-20"


def test_uses_only_the_last_8_digits_when_extra_digits_come_first():
    url = "https://zoukgroup.com/x/EVE99920260720abc"
    assert extract_date_from_url(url) == "2026-07-20"


def test_returns_an_empty_string_when_the_url_has_no_event_id():
    url = "https://zoukgroup.com/singapore/capital/event/some-event"
    assert extract_date_from_url(url) == ""


DETAIL_PAGE_HTML = """
<html><head>
<title>Neon Nights | Zouk Group</title>
<meta name="description" content="A night of house and techno with special guests.">
<meta name="twitter:image" content="https://zoukgroup.com/img/neon.jpg">
</head><body>
<span class="uwsprice">$25.00</span>
<span class="uwsprice">$35.00</span>
</body></html>
"""


def test_parses_every_field_from_a_full_detail_page():
    url = "https://zoukgroup.com/singapore/capital/event/EVE20260720/neon-nights"
    detail = parse_event_page(DETAIL_PAGE_HTML, url)

    assert detail["name"] == "Neon Nights"
    assert detail["date"] == "2026-07-20"
    assert detail["description"] == "A night of house and techno with special guests."
    assert detail["image_url"] == "https://zoukgroup.com/img/neon.jpg"
    assert detail["price"] == "$25"  # the lower of the two prices shown


def test_handles_a_page_missing_every_optional_tag_without_crashing():
    empty_html = "<html><body><p>Nothing useful here</p></body></html>"
    detail = parse_event_page(empty_html, "https://zoukgroup.com/singapore/capital/event/no-id-here")

    assert detail["name"] == "Unknown"
    assert detail["date"] == ""
    assert detail["description"] == ""
    assert detail["image_url"] == ""
    assert detail["price"] == ""
