#!/bin/sh
# Deploy admin Edge Functions (reads verify_jwt from supabase/config.toml).
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

for fn in admin-list-users admin-auth-create-user admin-auth-delete-user; do
  echo "==> supabase functions deploy $fn"
  supabase functions deploy "$fn"
done

echo "Done. All three admin functions are deployed."
