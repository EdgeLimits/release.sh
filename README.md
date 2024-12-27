# release.sh

## 0. Prerequisites (optional)

If you are using the 'release.sh' in a python project, it is recommended to install pre-commit hooks. To install pre-commit hooks and [commitizen](https://pypi.org/project/commitizen/), run the following command:
```bash
source venv/bin/activate

pip install commitizen
pip install pre-commit

pre-commit install
```

## 1. Release
To release a new version of the package, run the following command:
```bash
sh releash.sh
```


## References

This project is inspired by the following projects:
- [semver](https://semver.org/) 
- [commitizen changelog](https://commitizen-tools.github.io/commitizen/commands/changelog/)
- [github release artifact](https://github.com/marketplace/actions/auto-release#example)
