# release.sh

A super convenient script to automate the release process for your Git projects. It ensures streamlined workflows by:
 - managing semantic versioning (\<major\>.\<minor\>.\<patch\>),
 - generating changelogs (CHANGELOG.md),
 - and tagging releases.

	NB! This repo is also using the `release.sh` management script. You can see how it handles the releases.

### TL;DR

Copy and paste the `release.sh` file into the root folder of your project. At least change the `REPOSITORY_URL` to point to your project git repo.

```bash
chmod +x release.sh
sh release.sh

# or shebang it :) 
```

## Configuration

|Variable|Default|Description|
|-|-|-|
|`BRANCH_RELEASE`|main|Release branch name. Keep the same as BRANCH_WORKING if you want don't need to make releases in separate branch|
|`BRANCH_WORKING`|main|Working branch name.|
|`REMOTE`|origin|Git remote host name|
|`REPOSITORY_URL`|https://github.com/EdgeLimits/release.sh||
|`PROJECT_URL`|https://github.com/EdgeLimits/release.sh/issues|(optional) Link to your project management / issue tracking|
|`PROJECT_REFERENCE_LOCATION`|branch|Location where the changelog generator searches for rerefence number (Example `#123`). `branch` or `commit`|
|`CHANGELOG_FILE`|CHANGELOG.md|Changelog file name|
|`CHANGELOG_COMMIT_MESSAGE`|`docs: update CHANGELOG.md`|Changelog commit message|
|`VERSION_FILES`|("version.txt")|List of files in which the current version will be persisted. Separated by a whitespace.|
|`VERSION_TYPE`|patch|Default version increment. `major`, `minor`, `patch`.|

Running options:

|Flag|Description|
|-|-|
|`--dry-run`|No changes will be made; for preview purposes only.|
|`--quiet`|No output logs|

## Conventional commits 

The sole purpose of this `release.sh` script is to ease the version management of your git project and automate the release process. All you have to do is to ensure that your commit messages follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) convention.

```
<type>(optional scope): <description>
```

Currently, it supports the following `types`:
- `feat` - features;
- `fix` - big fixtures;
- `test` - tests;
- `chore` - misc updates;
- `docs` - documentations;

For example: 
```
git commit -m "feat: adding release.sh manager to the project"
```
Generate changelog:
```
## Version v0.0.2
### Features

* feat: adding release.sh manager to the project[<hash>](<url_to_commit>)
```

If you want to reference issues or project tasks in the changelog file, you have two options to reference the number:
**a) in the commit message:**
Requirements: `PROJECT_URL` must be set, `PROJECT_REFERENCE_LOCATION=commit`
```
git commit -m "feat(#123): adding release.sh manager to the project"
```

**b) in the branch name:**
Requirements: `PROJECT_URL` must be set, `PROJECT_REFERENCE_LOCATION=branch`
```
git checkout -b feature/#123-reseale-manager
```

Generate changelog:
```
## Version v0.0.2
### Features

* [#123](<url_to_project>/123) feat: adding release.sh manager to the project[<hash>](<url_to_repo>/<hash>)
```

### Enforcement using pre-commit 
In Python projects, you can enforce conventional commit checks using pre-commit.
```
(venv) pip install pre-commit
(venv) pip install commitizen

pre-commit install
```
Add **commitizen** to `.pre-commit-config.yaml`
```
...
  - repo: https://github.com/commitizen-tools/commitizen
    rev: v3.29.1
    hooks:
      - id: commitizen
        name: Commitizen check message format
        entry: cz
        pass_filenames: false
        args:
          ["check", "--commit-msg-file", ".git/COMMIT_EDITMSG", "--allow-abort"]
        stages: [commit-msg]

```

## Autmagical flow

So, what happens when you execute the `release.sh` script, it will:
1. Check if the necessary tools are installed and the configuration is correct;
2. Get the current version of the project;
3. Prompt you to select the version bump type (major, minor, patch);
4. Confirm release current version -> target version?;
5. Write the new version to the version file(s);
6. Generate the changelog file;
7. Commit the changelog and tag the release;
8. Merge the working branch into the release branch (step will skipped if `BRANCH_RELEASE` is the same as `BRANCH_WORKING`)

That's it in short! :) 

## References

1. [Semantic Versioning](https://semver.org/)
2. [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
3. [Commitizen](https://commitizen-tools.github.io/commitizen/)
