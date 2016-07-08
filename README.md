# Managing Swift Repositories

## Change Submodule's URL
```console
$ git config --file .gitmodules submodule.<submodule name>.url <url>
$ git submodule sync --recursive <submodule name>
$ git add --force <submodule name>
```
