"""Downloads the reactive-gallery paintings and records their rights (artspec.md sections 7-8).

    python tools/fetch_art.py            # fetch every work not yet cleared
    python tools/fetch_art.py --list     # show what would be fetched and from where
    python tools/fetch_art.py A12 A24    # only these ids
    python tools/fetch_art.py --force    # re-download and re-check everything

A painting only enters the game when this script has (1) read the institution's or file page's
own rights field and found public domain / CC0, and (2) saved the image next to that evidence.
Anything else is written to data/art_rights.json as "rejected" with the reason, and the game shows
the slot's neutral painting (or a sheet-covered frame) instead. Nothing here is a legal opinion;
re-read docs/art_rights_manifest.csv before release.

Sources and the field that clears a file:
  met      collectionapi.metmuseum.org  isPublicDomain == true (Met Open Access, CC0)
  nga      NGA open data published_images.csv  openaccess == 1 (NGA Open Access, CC0)
  aic      api.artic.edu  is_public_domain == true (AIC images of PD works are CC0)
  commons  commons.wikimedia.org imageinfo  License is Public domain / PD-* / CC0

Uses only the Python standard library. The museum sites are blocked from the cloud sessions, so
run this on your own computer (Fetch Art.ps1), then open Godot once so it imports the images.
"""
import argparse, csv, datetime, io, json, sys, time, urllib.parse, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/art_catalog.json'
RIGHTS = ROOT / 'data/art_rights.json'
MANIFEST = ROOT / 'docs/art_rights_manifest.csv'
CACHE = ROOT / 'tmp/art_cache'
LONGEST = 1024
AGENT = 'MiroGameArtFetcher/1.0 (game jam build; public-domain artwork credits)'
NGA_IMAGES = 'https://raw.githubusercontent.com/NationalGalleryOfArt/opendata/main/data/published_images.csv'
COMMONS_OK = ('public domain', 'pd', 'cc0', 'cc-zero', 'pd-art', 'pd-old')


def get(url, binary=False, tries=3):
    for attempt in range(tries):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': AGENT})
            with urllib.request.urlopen(request, timeout=60) as response:
                data = response.read()
                return data if binary else data.decode('utf-8')
        except Exception as error:  # network hiccups: back off and retry
            if attempt == tries - 1:
                raise
            time.sleep(2 ** attempt)


def met(work):
    data = json.loads(get(f'https://collectionapi.metmuseum.org/public/collection/v1/objects/{work["source_key"]}'))
    if not data.get('isPublicDomain'):
        return None, 'Met object is not marked isPublicDomain'
    url = data.get('primaryImageSmall') or data.get('primaryImage')
    if not url:
        return None, 'Met object has no downloadable image'
    return {'file_url': url, 'rights_label': 'Public Domain (Met Open Access, CC0)', 'evidence_url': data.get('objectURL', work['source_url'])}, ''


_nga_rows = None


def nga(work):
    global _nga_rows
    if _nga_rows is None:
        CACHE.mkdir(parents=True, exist_ok=True)
        cached = CACHE / 'nga_published_images.csv'
        if not cached.exists() or time.time() - cached.stat().st_mtime > 7 * 86400:
            cached.write_bytes(get(NGA_IMAGES, binary=True))
        _nga_rows = list(csv.DictReader(io.StringIO(cached.read_text(encoding='utf-8'))))
    rows = [row for row in _nga_rows if row.get('depictstmsobjectid') == str(work['source_key']) and row.get('viewtype') == 'primary']
    if not rows:
        return None, 'NGA open data has no primary image for this object'
    row = rows[0]
    if str(row.get('openaccess')) != '1':
        return None, 'NGA image is not open access'
    base = row['iiifurl'].rstrip('/')
    return {'file_url': f'{base}/full/!{LONGEST},{LONGEST}/0/default.jpg', 'rights_label': 'Public Domain (NGA Open Access, CC0)', 'evidence_url': work['source_url']}, ''


def aic(work):
    data = json.loads(get(f'https://api.artic.edu/api/v1/artworks/{work["source_key"]}?fields=id,title,is_public_domain,image_id'))
    item = data.get('data', {})
    if not item.get('is_public_domain'):
        return None, 'AIC artwork is not is_public_domain'
    if not item.get('image_id'):
        return None, 'AIC artwork has no image_id'
    iiif = data.get('config', {}).get('iiif_url', 'https://www.artic.edu/iiif/2')
    return {'file_url': f'{iiif}/{item["image_id"]}/full/843,/0/default.jpg', 'rights_label': 'Public Domain (AIC is_public_domain, CC0 image)', 'evidence_url': f'https://api.artic.edu/api/v1/artworks/{work["source_key"]}'}, ''


def commons(work):
    query = urllib.parse.urlencode({'action': 'query', 'titles': work['source_key'], 'prop': 'imageinfo', 'iiprop': 'url|extmetadata', 'iiurlwidth': LONGEST, 'format': 'json'})
    data = json.loads(get(f'https://commons.wikimedia.org/w/api.php?{query}'))
    page = next(iter(data.get('query', {}).get('pages', {}).values()), {})
    info = (page.get('imageinfo') or [{}])[0]
    if not info:
        return None, 'Commons file not found'
    meta = info.get('extmetadata', {})
    license_name = meta.get('LicenseShortName', {}).get('value', '')
    usage = meta.get('UsageTerms', {}).get('value', '')
    label = license_name.lower()
    # A file that also offers CC BY-SA (e.g. a photographer's own licence) is not cleared here:
    # artspec.md section 8 asks for a human decision on those.
    if not any(label.startswith(ok) for ok in COMMONS_OK) or 'by-sa' in label or 'gfdl' in label:
        return None, f'Commons licence needs review: {license_name or usage or "unknown"}'
    return {'file_url': info.get('thumburl') or info['url'], 'rights_label': f'{license_name} (Wikimedia Commons file page)', 'evidence_url': info.get('descriptionurl', work['source_url'])}, ''


SOURCES = {'met': met, 'nga': nga, 'aic': aic, 'commons': commons}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('ids', nargs='*')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--force', action='store_true')
    args = parser.parse_args()
    works = json.loads(CATALOG.read_text(encoding='utf-8'))['works']
    rights = json.loads(RIGHTS.read_text(encoding='utf-8')) if RIGHTS.exists() else {'_comment': '', 'works': {}}
    rights['_comment'] = 'Written by tools/fetch_art.py. The game only shows a painting whose status is "verified" and whose file exists.'
    today = datetime.date.today().isoformat()
    for work in works:
        if args.ids and work['id'] not in args.ids:
            continue
        local = ROOT / work['asset_path'].replace('res://', '')
        known = rights['works'].get(work['id'], {})
        if args.list:
            print(f'{work["id"]}  {work["source"]:8} {work["source_key"]:60} -> {local.relative_to(ROOT)}  [{known.get("status", "not fetched")}]')
            continue
        if known.get('status') == 'verified' and local.exists() and not args.force:
            print(f'{work["id"]}  already verified')
            continue
        try:
            found, reason = SOURCES[work['source']](work)
            if found is None:
                rights['works'][work['id']] = {'status': 'rejected', 'reason': reason, 'checked': today}
                print(f'{work["id"]}  REJECTED  {reason}')
                continue
            image = get(found['file_url'], binary=True)
            if len(image) < 2000 or not (image[:3] == b'\xff\xd8\xff' or image[:8] == b'\x89PNG\r\n\x1a\n'):
                raise ValueError('download is not a JPEG/PNG image')
            local.parent.mkdir(parents=True, exist_ok=True)
            local.write_bytes(image)
            rights['works'][work['id']] = {
                'status': 'verified', 'rights_label': found['rights_label'], 'evidence_url': found['evidence_url'],
                'file_url': found['file_url'], 'local_file': str(local.relative_to(ROOT)).replace('\\', '/'),
                'checked': today, 'reviewed_by': 'tools/fetch_art.py (automatic field check)',
                'modifications': 'resized by the source server; downscaled and framed in game', 'attribution': work['attribution']}
            print(f'{work["id"]}  ok  {found["rights_label"]}  ({len(image) // 1024} KB)')
        except Exception as error:
            rights['works'][work['id']] = {'status': 'error', 'reason': str(error)[:200], 'checked': today}
            print(f'{work["id"]}  ERROR  {error}')
        time.sleep(0.5)
    if args.list:
        return
    RIGHTS.write_text(json.dumps(rights, indent=1, ensure_ascii=False) + '\n', encoding='utf-8')
    with MANIFEST.open('w', newline='', encoding='utf-8') as handle:
        writer = csv.writer(handle)
        writer.writerow(['art_id', 'original_artist', 'work_title', 'institution_or_uploader', 'source_object_url', 'exact_file_url', 'rights_label', 'rights_evidence_url', 'accessed_date', 'license_reviewed_by', 'local_master_filename', 'processed_game_filename', 'modifications', 'attribution_text', 'status'])
        for work in works:
            entry = rights['works'].get(work['id'], {})
            writer.writerow([work['id'], work['artist'], work['title'], work['institution'], work['source_url'], entry.get('file_url', ''), entry.get('rights_label', entry.get('reason', '')), entry.get('evidence_url', ''), entry.get('checked', ''), entry.get('reviewed_by', ''), '', entry.get('local_file', ''), entry.get('modifications', ''), work['attribution'], entry.get('status', 'not fetched')])
    verified = sum(1 for entry in rights['works'].values() if entry.get('status') == 'verified')
    print(f'\n{verified}/{len(works)} works verified. Wrote {RIGHTS.relative_to(ROOT)} and {MANIFEST.relative_to(ROOT)}.')
    print('Open the project in Godot once so the new images are imported.')


if __name__ == '__main__':
    main()
