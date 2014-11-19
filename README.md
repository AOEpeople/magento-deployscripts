Magento Deployment Scripts
==========================

Author: Fabrizio Branca

This is a collection of scripts used to build/package, deploy and install Magento projects.

*Import note:*
Never use the master branch in your build jobs. Instead clone a specific tag:
```
git clone -b v1.0.0 https://github.com/AOEpeople/magento-deployscripts.git
```
Since these scripts might change significantly and your deployment process might fail otherwise.

### Overview

* [build.sh](#buildsh)
* [deploy.sh](#deploysh)
* [install.sh](#installsh)

### Usage

Add the magento-deployment scripts to your project using Composer. Checkout composer.json example file below.

### Introduction

#### build vs. provisioning vs. deployment vs. installation

Checkout http://www.slideshare.net/aoepeople/rock-solid-magento/91 (and the next slides after that)

TODO: add more information here

### <a name="buildsh"></a>build.sh

```
Usage:
 ./deploy.sh -r <packageUrl> -t <targetDir> -e <environment> [-u <downloadUsername>] [-p <downloadPassword>] [-a <awsCliProfile>] [-d]
 -r     Package url (http, S3 or local file)
 -t     Target dir
 -u     Download username
 -p     Download password
 -a     aws cli profile (defaults to 'default')
 -d     Also download and install .extra.tar.gz package
```

Generated files
* projectName.tar.gz
* projectName.extra.tar.gz
* MD5SUMS

#### Base package vs extra package

Checkout http://www.slideshare.net/aoepeople/rock-solid-magento/55 (and the next slides after that)

<a name="tarexcludes"></a>Example Configuration/tar_excludes.txt content

```
.git*
./htdocs/includes
./htdocs/downloader
./htdocs/pkginfo
./htdocs/LICENSE*
./htdocs/RELEASE_NOTES.txt
./htdocs/phpunit.xml*
./htdocs/*.sample
./htdocs/var
./htdocs/media
./.modman/Aoe_TemplateHints
./.modman/EcomDev_PHPUnit
```

#### Expected project files/directories

* composer.json
* tools/composer.phar (This should be part of your project repo. Obviously this can't be pulled in via Composer. Chicken and egg, problem... :)
* tools/modman (This is part of https://github.com/AOEpeople/magento-deployscripts which is being pulled in via composer)
* htdocs/index.php
* .modman directory: The modules located here can be directly committed to the main project repository (e.g. if they're project specific) or they can be pulled in via Composer)
* .modman/ProjectName_Base: There's no exclipict check for this base module to be present, but this is a recommendation. Add the basic project setup (local.xml, htaccess,...) to this base module.
* .modman/.basedir
* [Configuration/tar_excludes.txt](#tarexcludes) (this file controls what goes in the base package and what goes in the extra package. See below)

Additionally install.sh expects/checks these files:

* tools/systemstorage_import.sh (This is part of https://github.com/AOEpeople/magento-deployscripts which is being pulled in via composer)
* tools/apply (This is part of https://github.com/AOEpeople/EnvSettingsTool which is being pulled in via composer)
* tools/n98-magerun.phar (This is part of https://github.com/AOEpeople/magento-deployscripts which is being pulled in via composer)
* Configuration/settings.csv (This is being used by EnvSettingsTool to apply all environment specific settings during the installation process)
* Configuration/mastersystem.txt (Defines which system is the master system. E.g. "production". This is required to determine if the systemstorage backup needs to be imported during the installation process.)
* Configuration/project.txt (project name. E.g. "acme")

These files and folders can easily be constructud by using following composer.json as a basis for your project

```
{
    "name": "my/project",
    "minimum-stability": "dev",
    "require": {
        "aoepeople/composer-installers": "*",
        "aoepeople/envsettingstool": "*",
        "tmp/magento_community": "1.9.0.1"
        "aoepeople/magento-deployscripts": "1.0.3"
    },
    "repositories": [
        {
            "type": "vcs",
            "url": "https://github.com/AOEpeople/composer-installers.git"
        },
        {
            "type": "vcs",
            "url": "https://github.com/AOEpeople/EnvSettingsTool.git"
        },
        {
            "type": "package",
            "package": {
                "name": "tmp/magento_community",
                "type": "magento-source",
                "version": "1.9.0.1",
                "dist": {
                    "url": "https://github.com/OpenMage/magento-mirror/archive/1.9.0.1.zip",
                    "type": "zip"
                }
            }
        },
        {
            "type": "vcs",
            "url": "https://github.com/AOEpeople/magento-deployscripts.git"
        }
    ],
    "config" : {
        "bin-dir": "tools"
    }
}
```

#### Auto-generated meta files

Following files will be stored inside the base package

* build.txt
* htdocs/version.txt (will be accessible from the web)

### <a name="deploysh"></a>deploy.sh

### <a name="installsh"></a>install.sh

### opsworks_*.sh

### systemstorage_import.sh

### *lint.sh

### Tools

#### n98-magerun
#### modman
