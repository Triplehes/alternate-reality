#!/usr/bin/env python3
"""Build an offline preview or connected Android release without embedded secrets."""
import argparse
import json
import os
from pathlib import Path
import subprocess
from urllib.parse import urlparse

parser = argparse.ArgumentParser()
parser.add_argument('--config', type=Path)
parser.add_argument('--offline', action='store_true')
parser.add_argument('--production', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
if bool(args.config) == args.offline:
    parser.error('Choose exactly one of --offline or --config <file>.')
if args.production and args.offline:
    parser.error('Production builds require an HTTPS backend. Use a preview for offline testing.')
if not (root / 'android/key.properties').exists():
    parser.error('Missing release signing: follow docs/RELEASE.md.')
command = ['flutter', 'build', 'apk', '--release', '--flavor', 'production' if args.production else 'preview']
if args.config:
    path = args.config.resolve()
    config = json.loads(path.read_text())
    if set(config) != {'AI_BACKEND_URL'}:
        parser.error('Release config must contain only AI_BACKEND_URL. Never embed an access token or provider key.')
    url = urlparse(config['AI_BACKEND_URL'])
    if (url.scheme != 'https' or not url.hostname or url.username or url.password or url.query or url.fragment
        or url.hostname in {'localhost', '127.0.0.1', '::1', '10.0.2.2'} or 'example' in url.hostname):
        parser.error('Use your deployed HTTPS backend URL, without credentials, query parameters or a placeholder domain.')
    command.append('--dart-define-from-file=' + str(path))
subprocess.run(command, cwd=root, check=True, env=os.environ.copy())
