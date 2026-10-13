"""Build the pinned offline logo catalog. Run from the repository root.
Sources: Simple Icons 16.34.0 and Commons file metadata recorded in BrandSources.json.
No network requests occur in the iPhone app.
"""
import io, json, tarfile, urllib.request, urllib.parse, urllib.error, hashlib, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

ROOT = Path(__file__).resolve().parents[1]
VERSION = '16.34.0'
HEADERS = {'User-Agent': 'ILandDevelopment/1.0 (local app asset sourcing)'}
def download(url):
    cache = ROOT / 'build/logo-downloads' / hashlib.sha256(url.encode()).hexdigest()
    if cache.exists(): return cache.read_bytes()
    for attempt in range(5):
        try:
            data = urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=40).read()
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_bytes(data)
            return data
        except urllib.error.HTTPError as error:
            if error.code != 429 or attempt == 4: raise
            delay = max(30, int(error.headers.get('Retry-After', '30')))
            print('Source rate limit; waiting', delay, 'seconds:', url, flush=True)
            time.sleep(delay)
archive = ROOT / 'build' / 'simple-icons.tgz'
archive.parent.mkdir(exist_ok=True)
if not archive.exists():
    archive.write_bytes(download(f'https://registry.npmjs.org/simple-icons/-/simple-icons-{VERSION}.tgz'))
package = tarfile.open(fileobj=io.BytesIO(archive.read_bytes()))
metadata = {item['slug']: item for item in json.load(package.extractfile('package/data/simple-icons.json'))}
selections = {
 'Autos': 'audi bmw porsche ferrari lamborghini bugatti bentley astonmartin mclaren maserati rollsroyce tesla toyota honda acura nissan infiniti mazda subaru mitsubishi suzuki hyundai kia ford chevrolet cadillac jeep chrysler ram volkswagen volvo polestar skoda seat peugeot citroen renault dacia opel mini'.split(),
 'Mode': 'dior hermes thenorthface adidas nike puma reebok underarmour newbalance fila jordan uniqlo zara zalando'.split(),
 'Tech': 'apple samsung sony playstation bose beatsbydre sennheiser jbl razer corsair intel amd nvidia dell hp lenovo asus acer google garmin'.split(),
 'Lifestyle': 'spotify netflix youtube tiktok instagram discord figma notion ikea starbucks redbull airbnb uber'.split(),
}
commons = [
 ('rolex','Rolex','Uhren','Rolex wordmark logo.svg'),
 ('omega','Omega','Uhren','Omega Logo.svg'),
 ('seiko','Seiko','Uhren','Seiko logo.svg'),
 ('tissot','Tissot','Uhren','Tissot Logo.svg'),
 ('casio','Casio','Uhren','Casio logo.svg'),
 ('swatch','Swatch','Uhren','Swatch Logo.svg'),
 ('tagheuer','TAG Heuer','Uhren','TAG Heuer Logo.svg'),
 ('citizen','Citizen','Uhren','Citizen logo.svg'),
 ('gucci','Gucci','Mode','Gucci Logo.svg'),
 ('prada','Prada','Mode','Prada-Logo.svg'),
 ('chanel','Chanel','Mode','Chanel logo.svg'),
 ('louisvuitton','Louis Vuitton','Mode','Louis Vuitton logo and wordmark.svg'),
 ('burberry','Burberry','Mode','Burberry Logo.svg'),
]
assets = ROOT / 'Shared/BrandAssets.xcassets'
assets.mkdir(exist_ok=True)
(assets/'Contents.json').write_text(json.dumps({'info': {'author':'xcode','version':1}}))
records, provenance = [], []
def save_asset(slug, data):
    # Assets remain vectors, with original geometry and colors; no third-party renderer.
    import xml.etree.ElementTree as ET
    tree=ET.fromstring(data)
    assert tree.tag.endswith('svg'), slug
    assert b'<script' not in data.lower(), slug
    folder=assets/('brand_'+slug+'.imageset');folder.mkdir(exist_ok=True)
    if slug == 'gucci':
        import re
        data = re.sub(rb' clip-path="url\(#[^"]+\)"', b'', data)
    (folder/'logo.svg').write_bytes(data)
    (folder/'Contents.json').write_text(json.dumps({'images':[{'filename':'logo.svg','idiom':'universal'}], 'info':{'author':'xcode','version':1}, 'properties':{'preserves-vector-representation':True}},indent=2))
for category, slugs in selections.items():
    for slug in slugs:
        info=metadata[slug]; data=package.extractfile('package/icons/'+slug+'.svg').read()
        save_asset(slug,data)
        records.append(dict(id=slug,name=info['title'],category=category,source=info['source'],credit='Simple Icons '+VERSION))
        provenance.append(dict(id=slug,collection='Simple Icons',version=VERSION,sha256=hashlib.sha256(data).hexdigest(),metadata=info))
query={'action':'query','format':'json','prop':'imageinfo','iiprop':'url|extmetadata','titles':'|'.join('File:'+x[3] for x in commons)}
metadata_cache = ROOT / 'build/commons-logos-metadata.json'
if metadata_cache.exists(): response=json.loads(metadata_cache.read_bytes())
else:
    response=json.loads(download('https://commons.wikimedia.org/w/api.php?'+urllib.parse.urlencode(query)))
    metadata_cache.write_text(json.dumps(response))
pages={p['title']:p for p in response['query']['pages'].values()}
def get_commons(item):
    slug,name,category,filename=item
    page=pages['File:'+filename]; info=page['imageinfo'][0]
    license=info['extmetadata']['LicenseShortName']['value']
    assert license=='Public domain', (slug,license)
    url=info['url'].split('?')[0]
    data=download(url)
    return item,info,url,data
with ThreadPoolExecutor(max_workers=1) as executor:
    for item,info,url,data in executor.map(get_commons, commons):
        slug,name,category,filename=item
        save_asset(slug,data)
        source='https://commons.wikimedia.org/wiki/File:'+urllib.parse.quote(filename.replace(' ','_'))
        records.append(dict(id=slug,name=name,category=category,source=source,credit='Wikimedia Commons · Public domain'))
        provenance.append(dict(id=slug,collection='Wikimedia Commons',source=source,downloadURL=url,sha256=hashlib.sha256(data).hexdigest(),metadata=info['extmetadata']))
assert len(records)==100, len(records)
assert len({r['id'] for r in records})==100
records.sort(key=lambda r:r['name'].casefold())
(ROOT/'Shared/Brands.json').write_text(json.dumps(records,ensure_ascii=False,indent=2))
credits=ROOT/'Shared/BrandLicenses'; credits.mkdir(exist_ok=True)
for filename in ['LICENSE.md','DISCLAIMER.md']:
    (credits/('SimpleIcons-'+filename)).write_bytes(package.extractfile('package/'+filename).read())
for item in provenance:
    if item['id'] == 'gucci':
        item['assetNormalization'] = 'Redundant oversized rectangular clipping removed for Xcode SVG compatibility; letter paths, transforms and colors unchanged.'
        item['assetSHA256'] = hashlib.sha256((assets/'brand_gucci.imageset/logo.svg').read_bytes()).hexdigest()
(credits/'BrandSources.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2))
print('Imported',len(records),'logos:',{c:sum(x['category']==c for x in records) for c in ['Autos','Mode','Uhren','Tech','Lifestyle']})
