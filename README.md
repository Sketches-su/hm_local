# hm_local - Nginx+Apache+PHP management script for local web development

**Русскоязычное описание** [здесь](README_ru.md).

This script is what I use for managing my local virtual hosts. I don't recommend using it on production servers (by performance and security reasons).

**Tip**: you can try this script in seconds without the need to install anything. Just clone the repo and copy `config.test` into `config`, and you're ready to go. Type `./hm_local add testhost.dev` (no `sudo` needed here!), then look into `test/` directory to see what happened.

**Features:**
* Apache as the primary webserver.
* (optional) nginx as front-end - actually not needed for local web development but added for easier integration with the existing nginx installation.
* CGI support - helps working with very old websites (this happens...)
* PHP as classic CGI - quite inefficient for production but perfect for local development. You can adjust the PHP.INI without the need to restart anything. If you have different PHP versions installed, you can easily switch between them by symlinking the one you need.
* `sendmail` simulator to capture mails sent by `mail()` function. (Still useless for SMTP-based mailers.)
* automatic patching of `/etc/hosts`.
* default configuration values are strict enough which helps developing with production in mind. `memory_limit` exceeded - does my script really need that much RAM or I can optimize it further? `open_basedir` restriction - wait, why does my script access the directory it doesn't need? `shell_exec()` is failed - where it is called from, did I ever use it? (Of course you may tweak your setup by editing per-host PHP.INIs - just be conscious and ask yourself questions.)

## Installation

Here I describe the installation on a clean system. If you have nginx and/or Apache already installed, skip what you don't need.

First you should decide how your local domains will be resolved. The script has out-of-the box support for automatic patching `/etc/hosts` file for every domain and domain alias created. Though this is easy and transparent, this should be considered a poor man's solution (for example, wildcards like `*.example.com` are not available) and as such you should prefer something better. As a starting point, [here](http://www.leaseweblabs.com/2013/08/wildcard-dns-ubuntu-hosts-file-using-dnsmasq/) you can read instructions for setting up `dnsmasq` for automatic resolving any subdomain under your custom TLD into your local IP address. Once set up, it doesn't need any further attention.

Install Apache (optionally, with `mpm-itk` module) and PHP. For example, on Debian or Ubuntu:

```
user@home:~$ sudo apt-get install apache2-common apache2-mpm-itk \
             libapache2-mod-rpaf php5-common \
             php5-cli php5-cgi php5-gd php5-mcrypt php5-mysqlnd php5-xsl
user@home:~$ sudo service apache2 stop
```

If you plan to use nginx, edit `/etc/apache2/apache2.conf` to make it listen to port 8080 (or any port other than 80).

```
user@home:~$ sudo service apache2 start
user@home:~$ sudo a2enmod rewrite
user@home:~$ sudo a2enmod cgi
user@home:~$ sudo a2enmod rpaf
# If you plan using nginx:
user@home:~$ wget http://nginx.org/keys/nginx_signing.key
user@home:~$ sudo apt-key add nginx_signing.key
user@home:~$ sudo bash -c 'echo "deb http://nginx.org/packages/DISTRO/ CODENAME nginx" >> /etc/apt/sources.list.d/nginx.list'
user@home:~$ sudo bash -c 'echo "deb-src http://nginx.org/packages/DISTRO/ CODENAME nginx" >> /etc/apt/sources.list.d/nginx.list'
user@home:~$ sudo apt-get update
user@home:~$ sudo apt-get install nginx
```

...where `DISTRO` is a distribution (`debian` or `ubuntu`) and `CODENAME` is a distribution codename (see the right one [here](http://nginx.org/en/linux_packages.html)).

Create a subdirectory for your virtual hosts.

Download the script:

```
user@home:~$ cd /anywhere/you/want
user@home:~$ git clone https://github.com/Sketches-su/hm_local
user@home:~$ cd hm_local
user@home:~$ cp config.dist config
```

Review and edit `config` to make sure all the settings are correct. Most probably these need to be adjusted:
* `HM_PATCH_HOSTS` - set this to 0 if you have set up `dnsmasq` (or used any other DNS resolving solution) as prescribed above
* `HM_USE_NGINX` - set this to 0 if you aren't using nginx
* `HM_USER` - set your non-root username
* `HM_VHOST_PATH` - type the full path to the virtual host subdirectory you created earlier;
* `APACHE_LISTEN_PORT` - set this to 80 if you aren't using nginx

If you decided not to use `mpm-itk`, edit `tpl/apache2.conf` and remove the `AssignUserID` line.

Run `crontab -e` and add the following:

```
*/30 * * * * find /home/user/www/*/tmp -type f -name 'sess_*' -mmin +120 -delete
```

(don't forget to replace `/home/user/www` with your `HM_VHOST_PATH` value)

Initialize the configuration files:

```
user@home:~$ sudo touch /etc/apache2/sites-available/hm_local.conf
user@home:~$ sudo a2ensite hm_local
```

Now it's time to create your first virtual host:

```
user@home:~$ sudo ./hm_local add test.dev
```

Now point your browser to http://test.dev/ and check if "It works!".

If Apache throws 500 Internal Server Error, it seems that some required Apache modules are disabled. See `$HM_VHOST_PATH/test.dev/logs/apache-error.log` to find what's wrong.

## Usage

* `sudo ./hm_local add hostname [alias [alias [...]]]` - create a virtual host. If no aliases are specified, the default one (`www.hostname`) is created. But if aliases are specified explicitly, that default one is not created.
* `sudo ./hm_local del hostname` - delete the virtual host and all of its files
* `sudo ./hm_local dis hostname` - turn the virtual host off (not wiping it from `/etc/hosts` though)
* `sudo ./hm_local en hostname` - turn the virtual host on
* `sudo ./hm_local rec` - recombine the configuration files and restart the services (after editing host's `nginx.conf` or `apache2.conf` for example)

