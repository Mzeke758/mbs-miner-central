import os
import re
import shutil
import urllib.request
import urllib.parse

BASE_URL = 'https://id-preview--39ea59ef-38bd-4a92-be4d-65603fe4c4ff.lovable.app/'

if __name__ == '__main__':
    print('Fetching', BASE_URL)
    req = urllib.request.Request(BASE_URL, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        html = r.read().decode('utf-8', errors='replace')
    print('Fetched HTML length', len(html))
    with open('index.html', 'w', encoding='utf-8') as f:
        f.write(html)

    # Remove stale assets directories
    for d in ['_next', 'fonts']:
        if os.path.isdir(d):
            print('Removing', d)
            shutil.rmtree(d)

    urls = set(re.findall(r'\b(?:src|href|imageSrcSet|srcSet)=\s*"([^"]+)"', html))
    expanded = set()
    for u in urls:
        if ',' in u:
            for part in u.split(','):
                part = part.strip().split(' ')[0]
                if part:
                    expanded.add(part)
        else:
            expanded.add(u)
    urls = expanded

    def is_asset_path(path: str) -> bool:
        if not path.startswith('/'):
            return False
        if path.startswith('/_next/'):
            return True
        if path.startswith('/fonts/'):
            return True
        if path.startswith('/favicon') or path == '/favicon.svg':
            return True
        if path == '/apple-touch-icon.png':
            return True
        if path == '/manifest.webmanifest':
            return True
        return False

    asset_paths = set()
    for u in urls:
        if u.startswith(('http://', 'https://')):
            parsed = urllib.parse.urlparse(u)
            if parsed.netloc.endswith('lovable.app') or parsed.netloc.endswith('lovable.dev'):
                candidate = parsed.path + ('?' + parsed.query if parsed.query else '')
                if is_asset_path(parsed.path):
                    asset_paths.add(candidate)
        elif u.startswith('/'):
            if is_asset_path(u.split('?', 1)[0]):
                asset_paths.add(u)

    asset_paths = sorted(asset_paths)
    print('Found', len(asset_paths), 'asset paths')
    with open('assets.txt', 'w', encoding='utf-8') as f:
        for p in asset_paths:
            f.write(p + '\n')

    errors = []
    for p in asset_paths:
        target_url = urllib.parse.urljoin(BASE_URL, p)
        parsed = urllib.parse.urlparse(target_url)
        target_path = parsed.path.lstrip('/')
        target_dir = os.path.dirname(target_path)
        if target_dir and not os.path.isdir(target_dir):
            os.makedirs(target_dir, exist_ok=True)
        print('Downloading', target_url, '->', target_path)
        try:
            req = urllib.request.Request(target_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            with open(target_path, 'wb') as f:
                f.write(data)
        except Exception as e:
            if p == '/manifest.webmanifest':
                fallback_url = 'https://lovable.dev/manifest.webmanifest'
                print('Fallback manifest download', fallback_url)
                try:
                    req = urllib.request.Request(fallback_url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req, timeout=30) as fr:
                        data = fr.read()
                    with open(target_path, 'wb') as f:
                        f.write(data)
                    continue
                except Exception as fex:
                    e = f'fallback failed: {fex}'
            errors.append((target_url, str(e)))

    clean_paths = [p.split('?', 1)[0] for p in asset_paths]
    clean_paths = sorted(dict.fromkeys(clean_paths))
    with open('assets_clean.txt', 'w', encoding='utf-8') as f:
        for p in clean_paths:
            f.write(p + '\n')

    for bad_file in ['auth-bridge', 'home']:
        if os.path.exists(bad_file):
            print('Removing non-asset file', bad_file)
            os.remove(bad_file)

    print('Download complete with', len(errors), 'errors')
    for u, e in errors:
        print('ERR', u, e)
