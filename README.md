# gettest

A simple script to quickly create and manage testing directories from templates. There are some default templates built in, but you can also [create your own](#custom-templates).

It is designed so that you can spin up a test directory as quickly and frictionless as possible but also keeping all your projects managed so that you can find them later when you need them.

## Usage

Simply use the following command to get a new testing directory.

```bash
gettest go playing with sqlite3
```

The first parameter is the template to use and everything else is a name to identify your project. You can also leave the name blank, then you will be prompted after the directory has been created if you want to give your project a name, because sometimes you maybe don't have a name right away when getting into the environment.

After executing the command, your test environment is created and your prefered editor is opened in the directory.

When you call `gettest` without any arguments, a list is presented with all your projects sorted by date, you you can quickly jump back in to previous test projects.

```
$ gettest --help
gettest [options] [template] [name...]

Arguments:
	template           The template to open
	name               Name to store the project as

Options:
	-d, --delete       Select projects to delete
	-h, --help         Show this help message and exit
```

## Configuration

`gettest` can be configured by environment variables.

- With `GETTEST_EDITOR`, you can define the editor to be used. The default is `$EDITOR`.
- With `GETTEST_DIR`, you can define the directory where `gettest` stores your projects and where templates will be looked for. The default is either `${XDG_DATA_HOME}/gettest` if `XDG_DATA_HOME` is defined, otherwise it is `$HOME/.local/share/gettest`.
- With `GETTEST_TEMPLATE_DIR`, you can overwrite the directory where templates are looked for. The default is `${GETTEST_DIR}/templates`.
- With `GETTEST_PROJECTS_DIR`, you can overwrite the directory where projects are stored in. The default is `${GETTEST_DIR}/projects`.

## Templates

Currently, the following templates are built-in:

- `plain` (aliases: `p`)
- `bash` (alias: `sh`)
- `python` (aliases: `py`)
- `go`
- `rust`

### Custom templates

Templates are stored as `.sh` files in your `GETTEST_TEMPLATE_DIR` (see [Configuraiton](#configuration)). The name of the script defines the name of the template. When chosen, the script will be executed inside the project dorectory.

So this would be an example for initializing a Go project.

```bash
#!/usr/bin/env bash

go mod init test >/dev/null

cat <<EOF > main.go
package main

func main() {

}
EOF
```

> [!TIP]
> You can overwrite built-in templates by creating custom templates with the same name.
