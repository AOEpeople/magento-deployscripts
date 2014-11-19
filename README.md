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

### Usage

Add the magento-deployment scripts to your project using Composer:

```
{
    "name": "my/project",
    "minimum-stability": "dev",
    "require": {
        "aoepeople/magento-deployscripts": "1.0.1"
    },
    "repositories": [
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

### Introduction

#### build vs. provisioning vs. deployment vs. installation

Checkout http://www.slideshare.net/aoepeople/rock-solid-magento/91 (and the next slides after that)

TODO: add more information here

### build.sh

### deploy.sh

### install.sh

### opsworks_*.sh

### *lint.sh

### Tools

#### n98-magerun
#### modman
