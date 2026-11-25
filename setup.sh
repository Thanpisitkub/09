#!/usr/bin/env bash
# One-shot setup: stores your Roblox keys as GitHub secrets and pushes the project, which triggers
# the build + upload to Roblox. Works with a repo that already exists (e.g. Thanpisitkub/09) or creates one.
# Run it inside the project folder (Termux on Android):  bash setup.sh
set -euo pipefail

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "ต้องติดตั้ง $1 ก่อน:  pkg install $1"; exit 1; }
}
need git
need gh

echo "== ส่งเกมขึ้น Roblox แบบไม่ใช้ Studio =="

# gh needs the "workflow" permission, otherwise GitHub refuses to accept .github/workflows/publish.yml
if ! gh auth status >/dev/null 2>&1; then
  echo "ล็อกอิน GitHub (GitHub.com > HTTPS > Login with a web browser)"
  gh auth login -h github.com -p https -w -s repo,workflow
elif ! gh auth status 2>&1 | grep -q "workflow"; then
  echo "ขอสิทธิ์เพิ่มสำหรับไฟล์ workflow (ทำตามรหัสที่ขึ้น)"
  gh auth refresh -h github.com -s repo,workflow
fi
gh auth setup-git

read -rp "Repo (ชื่อผู้ใช้/ชื่อ repo) [Thanpisitkub/09]: " REPO
REPO="${REPO:-Thanpisitkub/09}"
read -rp "Universe ID: " UNIVERSE
read -rp "Place ID: " PLACE
read -rsp "Roblox API Key (พิมพ์แล้วจะไม่แสดงบนจอ): " KEY
echo

if [ -z "$UNIVERSE" ] || [ -z "$PLACE" ] || [ -z "$KEY" ]; then
  echo "ต้องใส่ครบทั้ง 3 ค่า"; exit 1
fi

[ -d .git ] || git init -b main
git checkout -B main >/dev/null 2>&1 || true
git add .
git -c user.name="${GIT_AUTHOR_NAME:-dev}" -c user.email="${GIT_AUTHOR_EMAIL:-dev@users.noreply.github.com}" \
  commit -m "Throw Food For Animals" >/dev/null 2>&1 || true

if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "พบ repo $REPO แล้ว จะใช้ repo นี้ (ไฟล์ README เดิมที่มีแค่ชื่อ repo จะถูกแทนที่)"
  git remote remove origin >/dev/null 2>&1 || true
  git remote add origin "https://github.com/$REPO.git"
else
  echo "ไม่พบ repo นี้ กำลังสร้างใหม่แบบ private"
  gh repo create "$REPO" --private --source=. --remote=origin
fi

gh variable set ROBLOX_UNIVERSE_ID --body "$UNIVERSE" -R "$REPO"
gh variable set ROBLOX_PLACE_ID --body "$PLACE" -R "$REPO"
printf '%s' "$KEY" | gh secret set ROBLOX_API_KEY -R "$REPO"

git push -u origin main --force
echo "push แล้ว — GitHub กำลัง build และอัปโหลดเกมให้ (ดูสถานะด้านล่าง)"
sleep 8
gh run watch "$(gh run list -R "$REPO" --limit 1 --json databaseId -q '.[0].databaseId')" -R "$REPO" || true
echo "เสร็จแล้ว ถ้าขึ้น ✓ ให้เปิดเกมในแอป Roblox ด้วยบัญชีเจ้าของได้เลย"
