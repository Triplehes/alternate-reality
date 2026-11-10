#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_dir=$(dirname "$script_dir")
port="${PORT:-8080}"

cd "$project_dir"
flutter build web
echo "Serving Alternate Reality at http://localhost:$port"
exec python3 -m http.server "$port" --directory build/web
