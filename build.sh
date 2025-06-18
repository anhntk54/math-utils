#!/bin/bash

# Hàm để lấy thời gian định dạng YYYYMMDD-HHMMSS (UTC+0, điều chỉnh theo múi giờ nếu cần)
get_time_string() {
  date -u +%Y%m%d-%H%M%S
}

# Hàm để lấy số PR từ môi trường GitHub Actions
get_pr_number() {
  if [ -n "$GITHUB_EVENT_NAME" ] && [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
    echo "$GITHUB_REF" | grep -oP 'refs/pull/\K\d+' || echo "0"
  else
    echo "0"
  fi
}

# Lấy phiên bản hiện tại từ package.json
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo "Current version: $CURRENT_VERSION"

# Lấy nhánh hiện tại
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

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

# Phân tách phiên bản hiện tại
IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION%%-*}"  # Loại bỏ hậu tố pre-release

# Tăng phiên bản dựa trên nhánh
case "$BRANCH_NAME" in
  "main")
    # Tăng patch cho nhánh ổn định
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
    ;;
  "dev")
    # Tăng patch và thêm dev.[time_string]
    NEW_PATCH=$((PATCH + 1))
    TIME_STRING=$(get_time_string)
    NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}-dev.${TIME_STRING}"
    ;;
  *)
    # Xử lý pull request hoặc các nhánh khác (alpha, staging, issue-*)
    PR_NUMBER=$(get_pr_number)
    if [ "$PR_NUMBER" -gt 0 ]; then
      # Pull request: x.y.z-pr[pr number].[time_string]
      TIME_STRING=$(get_time_string)
      NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}-pr${PR_NUMBER}.${TIME_STRING}"
    else
      # Các nhánh khác (alpha, staging, issue-*): giữ nguyên hoặc tăng patch
      NEW_PATCH=$((PATCH + 1))
      TIME_STRING=$(get_time_string)
      NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}-dev.${TIME_STRING}"
    fi
    ;;
esac

echo "New version: $NEW_VERSION"

# Cập nhật package.json
if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "dev" ]; then
  # Commit phiên bản cho main và dev
  echo "$NEW_VERSION" > package.json
  sed -i "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" package.json
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
if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "dev" ]; then
  git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
  git push origin "v${NEW_VERSION}"
fi

# Publish lên npm (chỉ cho main và dev)
if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "dev" ]; then
  npm publish --access public
else
  echo "Skipping publish for non-stable branch $BRANCH_NAME"
fi
