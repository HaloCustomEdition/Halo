# Build

The Halo download package is build every 24 hours.

To make build on your own follow the steps below:

First install these programms:

* zip
* git-lfs

Clone the Halo repository.

    cd /usr/local/src/
    sudo git clone https://github.com/HaloCustomEdition/Halo.git

Edit the file.

    sudo vi /etc/cron.daily/halo-build.sh

And add these lines.

    #!/bin/sh

    sudo git -C /usr/local/src//Halo pull
    cd /usr/local/src/Halo
    sudo zip -FSr /var/www/54.171.67.203/Halo.zip . -x ".travis.yml" "*.git*" "gulpfile.js" "deploy.sh" "package.json" "*out*" "*node_modules*" "*page*"


And make it executable

    sudo chmod +x /etc/cron.daily/halo-build.sh

From now on your server updates the Halo repository and creates a new zip file daily.

### github pages

The Halo github page is updated with Travis CI.

[![Build Status](https://travis-ci.org/HaloCustomEdition/Halo.svg)](https://travis-ci.org/HaloCustomEdition/Halo)
