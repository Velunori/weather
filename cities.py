#!/usr/bin/env python3
"""Atomic saved-city storage. One JSON request on stdin, no network."""
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import sys


def normalize(city):
    name = str(city.get('name', '')).strip()
    if not name or len(name) > 160: raise ValueError('Enter a city name')
    lat, lon = city.get('latitude'), city.get('longitude')
    if lat is not None or lon is not None:
        lat, lon = float(lat), float(lon)
        if not math.isfinite(lat) or not math.isfinite(lon) or not -90 <= lat <= 90 or not -180 <= lon <= 180: raise ValueError('Invalid coordinates')
        identity = f'{lat:.5f},{lon:.5f}'
    else: identity = name.casefold()
    return dict(id=hashlib.sha256(identity.encode()).hexdigest()[:20], name=name, latitude=lat, longitude=lon, description=str(city.get('description', ''))[:300])


def dispatch(request):
    folder = Path(os.environ.get('XDG_STATE_HOME', Path.home()/'.local/state'))/'velunori/weather'
    folder.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(folder, 0o700)
    path = folder/'cities.json'
    with (folder/'cities.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        before = json.loads(path.read_text()) if path.exists() else {'cities': []}
        rows = list(before['cities'])
        if request['action'] == 'add':
            city = normalize(request['city'])
            if any(row['id'] == city['id'] for row in rows):
                # Keep useful geocoder region text if importing the primary city.
                rows = [dict(city, description=city['description'] or row.get('description','')) if row['id']==city['id'] else row for row in rows]
            else: rows.append(city)
        elif request['action'] == 'remove': rows = [row for row in rows if row['id'] != request['id']]
        elif request['action'] != 'list': raise ValueError('Unknown city action')
        result = {'cities': rows}
        if result != before or not path.exists():
            temp = path.with_suffix('.tmp')
            fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(fd, 'w') as stream: json.dump(result, stream)
            os.replace(temp, path)
        return result


if __name__ == '__main__':
    try: result = dict(ok=True, **dispatch(json.loads(sys.stdin.readline(100000))))
    except Exception: result = dict(ok=False, error='Could not save cities. Check the city and try again.')
    print(json.dumps(result))
