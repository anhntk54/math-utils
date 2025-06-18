#!/bin/bash

# Hàm để lấy thời gian định dạng YYYYMMDD-HHMMSS (UTC+0)
get_time_string() {
  date -u +%Y%m%d-%H%M%S
}

# Hàm để lấy số PR từ nhánh (dựa trên tên nhánh, giả định định dạng refs/pull/PRNUMBER/head)
get_pr_number() {
  if [[ "$GIT_BRANCH" =~ refs/pull/([0-9]+)/head ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "0"
  fi
}

# Lấy nhánh hiện tại
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Lấy phiên bản hiện tại từ package.json
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo "Current version: $CURRENT_VERSION"

# Phân tách phiên bản hiện tại (loại bỏ hậu tố pre-release)
IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION%%-*}"  # Loại bỏ -dev.* hoặc -pr.*

# Xác định loại tăng phiên bản dựa trên commit message (thủ công)
LAST_COMMIT_MESSAGE=$(git log -1 --pretty=%B)
if echo "$LAST_COMMIT_MESSAGE" | grep -q "BREAKING CHANGE"; then
  VERSION_TYPE="major"
elif echo "$LAST_COMMIT_MESSAGE" | grep -q "^feat"; then
  VERSION_TYPE="minor"
elif echo "$LAST_COMMIT_MESSAGE" | grep -q "^fix"; then
  VERSION_TYPE="patch"
else
  VERSION_TYPE="patch"  # Mặc định là patch nếu không khớp
fi

# Tăng phiên bản dựa trên nhánh
case "$GIT_BRANCH" in
  "main")
    # Tăng patch cho nhánh ổn định
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
    ;;
  "dev")
    # Đặt phiên bản cụ thể như yêu cầu (0.3.1-dev.20250618-022555) hoặc tăng patch
    TIME_STRING=$(get_time_string)
    NEW_VERSION="0.3.1-dev.${TIME_STRING}"
    ;;
  *)
    # Xử lý pull request hoặc các nhánh khác
    PR_NUMBER=$(get_pr_number)
    if [ "$PR_NUMBER" -gt 0 ]; then
      # Pull request: x.y.z-pr[pr number].[time_string]
      TIME_STRING=$(get_time_string)
      NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}-pr${PR_NUMBER}.${TIME_STRING}"
    else
      # Các nhánh khác (alpha, staging, issue-*): tăng patch và thêm dev.[time_string]
      NEW_PATCH=$((PATCH + 1))
      TIME_STRING=$(get_time_string)
      NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}-dev.${TIME_STRING}"
    fi
    ;;
esac

echo "New version: $NEW_VERSION"

# Cập nhật package.json
if [ "$GIT_BRANCH" = "main" ] || [ "$GIT_BRANCH" = "dev" ]; then
  # Commit phiên bản cho main và dev
  sed -i '' "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" package.json
  git add package.json
  git commit -m "release: v${NEW_VERSION}"
else
  # Không commit cho pull request
  echo "$NEW_VERSION" > version.txt
  echo "Version for PR: $NEW_VERSION (not committed)"
fi

# Build TypeScript
npm run build
git add dist/

# Tag và push (chỉ cho main và dev)
if [ "$GIT_BRANCH" = "main" ] || [ "$GIT_BRANCH" = "dev" ]; then
  git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
  git push origin "v${NEW_VERSION}"
fi

# Publish lên npm (chỉ cho main và dev)
if [ "$GIT_BRANCH" = "main" ] || [ "$GIT_BRANCH" = "dev" ]; then
  npm publish --access public
else
  echo "Skipping publish for non-stable branch $GIT_BRANCH"
fi
