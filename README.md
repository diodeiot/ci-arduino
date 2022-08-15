# Diode IoT Arduino CI Scripts

This repos contains various scripts and tools related to running continuous integration (CI) checks on Diode IoT's 
Arduino Library Repos.

## Adding New Repo

* Copy `.github` folder to new repo.
* Change `githubci.yml.temp` file name to `githubci.yml` in the `.github/workflows/` folder.
* Edit `githubci.yml` and change `DOC_LANG` to any desired documentation language. (options: en, tr) (default: en)
* Edit `githubci.yml` and change `PRETTY_NAME` to repo name. (default: "Diode IoT [Repository name after last '_' character]") 
* These actions will now run automatically on any push and pull request.
* Copy `.clang-format` `.gitignore` `LICENSE` files to the root folder of new repo.

## Formatting Check with clang-format

The `run-clang-format.py` script is used to run clang-format and check file formatting.
Even a single extra white space can cause the CI to fail on formatting.
You can typically just let clang-format do its thing and edit files in place using:
```
clang-format -i file_to_format.cpp
```

## Documentation with Doxygen

The `doxygen_deploy.sh` script uses Doxygen to generate and deploy documentation
for the library. Any issues, like missing documentation, will cause the CI to fail.
