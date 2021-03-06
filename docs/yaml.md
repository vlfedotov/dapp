Original proposal doc: https://github.com/flant/dapp/blob/master/docs/rfc/yaml_with_ansible.md.

# Yaml dappfile

Configuration is a collection of yaml documents (http://yaml.org/spec/1.2/spec.html#id2800132). These yaml documents are searched in one of the following files:

* `REPO_ROOT/dappfile.yml`
* `REPO_ROOT/dappfile.yaml`

Yaml configuration file will precede ruby `REPO_ROOT/Dappfile` if the case both files exists. `REPO_ROOT/dappfile.yml` will precede `REPO_ROOT/dappfile.yaml` in case both files exists.

Processing of Yaml configuration mainly consists of 2 steps:

* Rendering go templates into `WORKDIR/.dappfile.render.yml` or `WORKDIR/.dappfile.render.yaml`.
* Processing the result file as a set of yaml documents.

## Go templates

Go templates are available within yaml config.

* Sprig functions supported: https://golang.org/pkg/text/template/, http://masterminds.github.io/sprig/.
* `env` sprig fucntion also supported to access build-time environment variables (unlike helm, where `env` function is forbidden).

Dapp firstly will render go templates into `WORKDIR/.dappfile.render.yml` or `WORKDIR/.dappfile.render.yaml`. That file will remain after build and will be available if some validation or build error occured.

## Differences from Dappfile

1. No equivalent for `dimg_group` and nested `dimg`s and `artifact`s.
2. No context inheritance because of 1. Use go-template functionality
   to define common parts.
3. Use `import` in `dimg` for copy artifact results instead of `export`
4. Each `artifact` must have a name

## Configuration

```
YAML_DOC
---
YAML_DOC
---
...
```

Each YAML_DOC is either `dimg` or `artifact` and contain all instructions to build docker image.

One of `dimg: NAME` or `artifact: NAME` is a required param for each document.

## Directives

### Basic

#### `dimg: NAME` (one of required)

If doc contains `dimg` key, then dapp will treat this yaml-doc as dimg configuration.

`NAME` may be:

* Special value `~` to define unnamed dimg. This should be default choice for dimg name in dappfile.
* Some string to define named dimg with specified name. The name should contain only those characters, that are valid for docker image name.
* Array of strings to define multiple dimgs with the same configuration with different names. Different names will affect docker images names.

Conflicts with `artifact: NAME`.

#### `artifact: NAME` (one of required)

If doc contains `artifact` key, then dapp will treat this yaml-doc as artifact configuration.

`NAME` is a string, that defines artifact name. Artifact may be referenced in import by that name.

Conflicts with `dimg: NAME`.

#### `from: DOCKER_IMAGE` (required)

Specify docker image as a base image for current dimg or artifact.

#### `docker: DOCKER_PARAMS_MAP`

Define map with docker image params. Supported params are:

* CMD (https://docs.docker.com/engine/reference/builder/#/cmd)
* ENV (https://docs.docker.com/engine/reference/builder/#/env)
* ENTRYPOINT (https://docs.docker.com/engine/reference/builder/#/entrypoint)
* EXPOSE (https://docs.docker.com/engine/reference/builder/#/expose)
* LABEL (https://docs.docker.com/engine/reference/builder/#/label)
* ONBUILD (https://docs.docker.com/engine/reference/builder/#/onbuild)
* USER (https://docs.docker.com/engine/reference/builder/#/user)
* VOLUME (https://docs.docker.com/engine/reference/builder/#/volume)
* WORKDIR (https://docs.docker.com/engine/reference/builder/#/workdir)

Example:

```
docker:
  WORKDIR: /app
  EXPOSE: '8080'
  USER: app
```

#### `import: IMPORTS_ARR`

Each element of `IMPORTS_ARR` is a map:

```
artifact: ARTIFACT_NAME
add: SOURCE_DIRECTORY_TO_IMPORT
to: DESTINATION_DIRECTORY # optional
before: STAGE | after: STAGE
```

* `ARTIFACT_NAME` refers to artifact to copy files from.
* `SOURCE_DIRECTORY_TO_IMPORT` specifies directory/file path in artifact that should be imported.
* `DESTINATION_DIRECTORY` sets the destination path in current image configuration. Optional the same as `SOURCE_DIRECTORY_TO_IMPORT` by default.
* `after: STAGE` or `before: STAGE` specifies the stage for artifact import within current image configuration build stages. Allowed options are `install` or `setup`.

Example:

```
import:
- artifact: application-assets
  add: /app/public/assets
  after: install
- artifact: application-assets
  add: /vendor
  to: /app/vendor
  after: install
```

#### `git: GIT_ARR`

Example, add local git repository:

```
git:
- add: /
  to: /app
  owner: app
  group: app
  excludePaths:
  - public/assets
  - vendor
  - .helm
  stageDependencies:
    install:
    - package.json
    - Bowerfile
    - Gemfile.lock
    - app/assets/*
```

Example, add remote git repository:

```
git:
- url: https://github.com/kr/beanstalkd.git
  add: /
  to: /build
```

### Shell

Shell builder instructions are given as follows:

```
shell:
  STAGE:
  - INSTRUCTION
  - INSTRUCTION
  ...
  STAGE:
  - INSTRUCTION
  - INSTRUCTION
  ...
```

* `STAGE` is one of: `beforeInstall`, `install`, `beforeSetup`, `setup`.
* `INSTRUCTION` is a free form bash expression.

Example:

```
shell:
  beforeInstall:
    - useradd -d /app -u 7000 -s /bin/bash app
    - rm -rf /usr/share/doc/* /usr/share/man/*
    - apt-get update
    - apt-get -y install apt-transport-https git curl gettext-base locales tzdata
  setup:
    - locale-gen en_US.UTF-8
```

### Ansible

Ansible builder instructions are given as follows:

```
ansible:
  STAGE:
  - ANSIBLE_TASK
  - ANSIBLE_TASK
  ...
  STAGE:
  - ANSIBLE_TASK
  - ANSIBLE_TASK
  ...
```

* `STAGE` is one of: `beforeInstall`, `install`, `beforeSetup`, `setup`.
* Each `ANSIBLE_TASK` is an element from ansible `tasks` array, see https://docs.ansible.com/ansible/latest/playbooks_intro.html

Supported ansible modules list:

* Commands Modules (https://docs.ansible.com/ansible/latest/list_of_commands_modules.html)
    * command
    * shell
    * raw
    * script
* Files Modules (https://docs.ansible.com/ansible/latest/list_of_files_modules.html)
    * assemble
    * archive
    * unarchive
    * blockinfile
    * lineinfile
    * file
    * find
    * tempfile
    * copy
    * acl
    * xattr
    * ini_file
    * iso_extract
* Net Tools Modules (https://docs.ansible.com/ansible/latest/list_of_net_tools_modules.html)
    * get_url
    * slurp
    * uri
* Packaging Modules (https://docs.ansible.com/ansible/latest/list_of_packaging_modules.html)
    * apk
    * apt
    * apt_key
    * apt_repository
    * yum
    * yum_repository
* System Modules (https://docs.ansible.com/ansible/latest/list_of_system_modules.html)
    * user
    * group
    * getent
    * locale_gen
* Utilities Modules (https://docs.ansible.com/ansible/latest/list_of_utilities_modules.html)
    * assert
    * debug
    * set_fact
    * wait_for
* Crypto Modules (https://docs.ansible.com/ansible/latest/list_of_crypto_modules.html)
    * openssl_certificate
    * openssl_csr
    * openssl_privatekey
    * openssl_publickey

Example:

```
ansible:
  beforeInstall:
  - name: "Create non-root main application user"
    user:
      name: app
      comment: "Non-root main application user"
      uid: 7000
      shell: /bin/bash
      home: /app
  - name: Disable docs and man files installation in dpkg
    copy:
      content: |
        path-exclude=/usr/share/man/*
        path-exclude=/usr/share/doc/*
      dest: /etc/dpkg/dpkg.cfg.d/01_nodoc
  install:
  - name: "Precompile assets"
    shell: |
      set -e
      export RAILS_ENV=production
      source /etc/profile.d/rvm.sh
      cd /app
      bundle exec rake assets:precompile
    args:
      executable: /bin/bash
```
