#!/bin/bash

# ======================================== #
# =============== RELEASE.sh ============= #
# ======================================== #

BRANCH_RELEASE="releases"
BRANCH_WORKING="dev"
REMOTE="origin"
REPOSITORY_URL="https://github.com/EdgeLimits/release.sh"
PROJECT_URL="https://github.com/EdgeLimits/release.sh/issues"
PROJECT_REFERENCE_LOCATION="branch" # branch, commit
CHANGELOG_FILE="CHANGELOG.md"
CHANGELOG_COMMIT_MESSAGE="docs: update CHANGELOG.md"
VERSION_FILES=("version.txt")
VERSION_TYPE="patch"
DRYRUN="0"
RUNSILENT="0"

# ======================================== #

while [[ "$#" -gt 0 ]]; do
  case $1 in
  -n | --dry-run)
    DRYRUN="1"
    ;;
  -q | --quiet)
    RUNSILENT="1"
    ;;
  esac
  shift
done

# ======================================== #

conditional_echo() {
  if [[ "$RUNSILENT" -eq 0 ]]; then
    echo "$1"
  fi
}

check_config() {
  if ! command -v git &>/dev/null; then
    echo "ERROR: git is not installed. Please install git to proceed."
    exit 1
  fi

  if [[ -z "$REPOSITORY_URL" ]]; then
    echo "ERROR: REPOSITORY_URL is not set. Please configure the script."
    exit 1
  fi

  if [[ -z "$BRANCH_WORKING" ]]; then
    echo "ERROR: BRANCH_DEVELOPMENT is not set. Please configure the script."
    exit 1
  fi

  if [[ -z "$BRANCH_RELEASE" ]]; then
    echo "ERROR: BRANCH_RELEASE is not set. Please configure the script."
    exit 1
  fi

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "ERROR: Current directory is not a git repository."
    exit 1
  fi

  if ! git remote | grep -q "^$REMOTE$"; then
    echo "ERROR: Remote '$REMOTE' does not exist. Please check your git configuration."
    exit 1
  fi

  BRANCH_CURRENT=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ "$BRANCH_CURRENT" != "$BRANCH_WORKING" ]]; then
    conditional_echo "Switching from branch '$BRANCH_CURRENT' to '$BRANCH_WORKING'..."
    git checkout "$BRANCH_WORKING" || {
      echo "ERROR: Failed to switch to branch '$BRANCH_WORKING'."
      exit 1
    }
  fi

  conditional_echo "Pulling the latest changes from '$REMOTE/$BRANCH_WORKING'..."
  git pull "$REMOTE" "$BRANCH_WORKING" || {
    echo "ERROR: Failed to pull the latest changes."
    exit 1
  }

  conditional_echo "Fetching the latest tags..."
  git fetch --tags || {
    echo "ERROR: Failed to fetch tags."
    exit 1
  }

  conditional_echo "Configuration check completed successfully."
}

get_current_version() {
  CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null)
  if [[ -z "$CURRENT_VERSION" ]]; then
    conditional_echo "No version tags found in the repository. Defaulting to 0.0.0."
    CURRENT_VERSION="0.0.0"
  else
    if [[ "$CURRENT_VERSION" =~ ^v ]]; then
      CURRENT_VERSION="${CURRENT_VERSION#v}"
    fi
  fi

  conditional_echo "Current release version: $CURRENT_VERSION"
}

prompt_target_version() {
  conditional_echo "Select the version bump type:"
  conditional_echo "1) Major"
  conditional_echo "2) Minor"
  conditional_echo "3) Patch"
  read -rp "Enter your choice [1-3]: " VERSION_CHOICE

  case $VERSION_CHOICE in
  1)
    VERSION_TYPE="major"
    ;;
  2)
    VERSION_TYPE="minor"
    ;;
  3 | "")
    VERSION_TYPE="patch"
    ;;
  *)
    conditional_echo "Invalid choice. Defaulting to $VERSION_TYPE."
    ;;
  esac

  conditional_echo "Selected version bump type: $VERSION_TYPE"
}

confirm_version_bump() {
  # Split the current version into components
  IFS='.' read -r MAJOR MINOR PATCH <<<"$CURRENT_VERSION"

  # Calculate the target version based on VERSION_TYPE
  case $VERSION_TYPE in
  major)
    TARGET_VERSION="$((MAJOR + 1)).0.0"
    ;;
  minor)
    TARGET_VERSION="$MAJOR.$((MINOR + 1)).0"
    ;;
  patch)
    TARGET_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
    ;;
  *)
    conditional_echo "ERROR: Invalid VERSION_TYPE '$VERSION_TYPE'. Exiting."
    exit 1
    ;;
  esac

  NEWTAG="v$TARGET_VERSION"
  conditional_echo "..$CURRENT_VERSION - current version"
  conditional_echo "..$TARGET_VERSION - target version"
  conditional_echo "..$NEWTAG - new tag"

  read -rp "Do you want to proceed with this version bump? [y/N]: " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    conditional_echo "Version bump canceled."
    exit 0
  fi

  conditional_echo "Version bump confirmed: $CURRENT_VERSION -> $TARGET_VERSION"
}

generate_changelog() {
  tags=($(git tag --sort=-v:refname))
  latest_tag=${tags[0]}
  previous_tag=""

  local output=""

  generate_sub_section() {
    local title="$1"
    local keyword="$2"
    local log="$3"

    section=$(echo "$log" | grep "$keyword(\|$keyword:" |
      while read -r line; do
        commit_hash=$(echo "$line" | grep -oE "^[a-f0-9]{7,40}")
        commit_message=$(echo "$line" | sed -E "s/^[a-f0-9]{7,40} (\(.*\))? *(.*)/\2/")

        if [[ "$PROJECT_REFERENCE_LOCATION" == "branch" ]]; then
          decorator=$(echo "$line" | sed -n 's/.*(\(.*\)).*/\1/p')
          filtered_decorator=$(echo "$decorator" | sed 's/tag:[^,]*, //g')
          issue_ref=$(echo "$filtered_decorator" | grep -o '#[0-9]\+' | head -n 1)
        elif [[ "$PROJECT_REFERENCE_LOCATION" == "commit" ]]; then
          issue_ref=$(echo "$commit_message" | grep -o "#[0-9]\+")
        else
          issue_ref=""
        fi

        if [[ -n "$PROJECT_URL" && -n "$issue_ref" ]]; then
          issue_number=$(echo "$issue_ref" | sed 's/#//')
          issue_link="[#$issue_number](${PROJECT_URL}/$issue_number)"
        else
          issue_link="$issue_ref"
        fi

        printf "* %s %s [%s](${REPOSITORY_URL}/commit/%s)\n" \
          "$issue_link" "$commit_message" "$commit_hash" "$commit_hash"
      done)

    if [[ -n "$section" ]]; then
      output+=$(printf "### %s\n\n" "$title")
      output+=$"\n\n"
      output+=$(printf "%s\n" "$section")
      output+=$"\n\n"
    fi
  }

  generate_sub_section_group() {
    output+=$(printf "## %s\n\n" "Version $2")
    output+=$"\n\n"
    generate_sub_section "Features" "feat" "$1"
    generate_sub_section "Bug fixes" "fix" "$1"
    generate_sub_section "Testing" "test" "$1"
    generate_sub_section "Misc updates" "chore" "$1"
    generate_sub_section "Documentations" "docs" "$1"
    output+=$" --- \n\n"
  }

  output+="# Changelog"$'\n\n'

  for tag in "${tags[@]}"; do
    if [ -n "$previous_tag" ]; then
      range="$tag...$previous_tag"
      generate_sub_section_group "$(git log --oneline --decorate $range)" $previous_tag
    else
      range="$tag..HEAD"
      generate_sub_section_group "$(git log --oneline --decorate $range)" $NEWTAG
    fi
    previous_tag=$tag
  done

  first_commit=$(git rev-list --max-parents=0 HEAD)
  if [ "$previous_tag" != "$first_commit" ]; then
    generate_sub_section_group "$(git log --oneline --decorate $first_commit..$previous_tag)" $previous_tag
  else
    generate_sub_section_group "$(git log --oneline --decorate $first_commit)" "Initial Commit"
  fi

  if [[ "$DRYRUN" -eq 0 ]]; then
    echo "$output" >"$CHANGELOG_FILE"
  else
    conditional_echo "$output"
  fi
}

commit_changlelog_and_tag() {
  LASTCOMMIT=$(echo $(git rev-parse $REMOTE/$BRANCH_WORKING))
  NEEDSTAG=$(echo $(git describe --contains $LASTCOMMIT 2>/dev/null))
  TAGEXISTS=$(echo $(git ls-remote --tags --ref $REMOTE | grep "$NEWTAG"))

  if [ -z "$NEEDSTAG" ]; then
    if [ -z "$TAGEXISTS" ]; then
      if [[ "$DRYRUN" -eq 0 ]]; then
        conditional_echo "committing changelog"
        git add $CHANGELOG_FILE

        for VERSION_FILE in "${VERSION_FILES[@]}"; do
          if [ -f "$VERSION_FILE" ]; then
            git add "$VERSION_FILE"
          else
            conditional_echo "$VERSION_FILE does not exist."
          fi
        done
        git commit -m "$CHANGELOG_COMMIT_MESSAGE"

        conditional_echo "..tagging release"
        git tag -a $NEWTAG -m "Release $NEWTAG $(date +'%Y-%m-%d %H:%M:%S')"

        conditional_echo "..pushing changes"
        git push $REMOTE $NEWTAG
        git push $REMOTE
      fi
    else
      conditional_echo "ERROR: TAG $NEWTAG already exists."
      exit 1
    fi
  else
    conditional_echo "ERROR: Commit already tagged as a release. ($LASTCOMMIT)"
    exit 1
  fi
}

write_version_to_files() {
  for version_file in "${VERSION_FILES[@]}"; do
    full_path=$(realpath "$version_file")

    if [ -f "$full_path" ]; then
      if [[ "$DRYRUN" -eq 0 ]]; then
        echo "$TARGET_VERSION" >"$full_path"
      fi
      conditional_echo "Written version $TARGET_VERSION to $full_path"
    else
      conditional_echo "File $full_path does not exist, skipping."
    fi
  done
}

merge_branches() {
  if [ "$BRANCH_WORKING" != "$BRANCH_RELEASE" ]; then
    conditional_echo "Switching to $BRANCH_RELEASE branch..."
    if [[ "$DRYRUN" -eq 0 ]]; then
      git checkout "$BRANCH_RELEASE"
    fi

    conditional_echo "Pulling the latest changes from remote $BRANCH_RELEASE..."
    if [[ "$DRYRUN" -eq 0 ]]; then
      git pull origin "$BRANCH_RELEASE"
    fi

    conditional_echo "Merging $BRANCH_WORKING into $BRANCH_RELEASE..."
    if [[ "$DRYRUN" -eq 0 ]]; then
      git merge "$BRANCH_WORKING"
    fi

    conditional_echo "Pushing the merged changes to remote $BRANCH_RELEASE..."
    if [[ "$DRYRUN" -eq 0 ]]; then
      git push origin "$BRANCH_RELEASE"
    fi

    conditional_echo "Jumping back to $BRANCH_WORKING branch..."
    if [[ "$DRYRUN" -eq 0 ]]; then
      git checkout "$BRANCH_WORKING"
    fi
  fi
}

# ======================================== #
# ============ RELEASE.sh ================ #
# ======================================== #

# Check if the necessary tools are installed and the configuration is correct
check_config

# Get the current version of the project
get_current_version

# Prompt the user to select the version bump type
prompt_target_version

# Confirm release current version -> target version?
confirm_version_bump

# Write the new version to the version file(s)
write_version_to_files

# Generate the changelog
generate_changelog

# Commit the changelog and tag the release
commit_changlelog_and_tag

# Merge the working branch into the release branch
merge_branches

exit 0
