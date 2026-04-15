#!/usr/bin/env bash
set -e

# Kullanım: ./create_github_template.sh
OWNER="Yaratan89"
REPO="StokDepomda"
VISIBILITY="public"
BRANCH="main"

# Git branch ve remote ayarı
git branch -M "$BRANCH"
git remote add origin "git@github.com:${OWNER}/${REPO}.git" 2>/dev/null || true

# Eğer gh CLI varsa
if command -v gh >/dev/null 2>&1; then
  echo "gh CLI bulundu. Repo oluşturuluyor ve pushlanıyor..."
  gh repo create "${OWNER}/${REPO}" --${VISIBILITY} --source=. --remote=origin --push
  echo "Repo oluşturuldu ve pushlandı."
  echo "Repo template olarak işaretleniyor..."
  gh api -X PATCH "/repos/${OWNER}/${REPO}" -f is_template=true
  echo "Repo template olarak ayarlandı: ${OWNER}/${REPO}"
  exit 0
fi

# gh yoksa GitHub API + PAT
if [ -z "$GITHUB_TOKEN" ]; then
  echo "gh CLI bulunamadı ve GITHUB_TOKEN çevre değişkeni ayarlı değil."
  echo "Lütfen gh CLI yükleyin veya GITHUB_TOKEN ayarlayın ve betiği tekrar çalıştırın."
  exit 1
fi

echo "gh CLI yok. GitHub API ile repo oluşturuluyor..."
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  -d "{\"name\":\"${REPO}\",\"private\":$( [ "$VISIBILITY" = "private" ] && echo true || echo false )}" \
  https://api.github.com/user/repos > /dev/null

git push -u origin "$BRANCH"

echo "Repo template olarak işaretleniyor..."
curl -s -X PATCH -H "Authorization: token ${GITHUB_TOKEN}" \
  -d '{"is_template":true}' \
  "https://api.github.com/repos/${OWNER}/${REPO}" > /dev/null

echo "Tamam. Repo oluşturuldu ve template olarak ayarlandı: ${OWNER}/${REPO}"
