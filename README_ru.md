# hm_local - скрипт управления Nginx+Apache+PHP для локальной веб-разработки

Этим скриптом я пользуюсь для управления локальными виртуальными хостами. Не рекомендую использовать его в продакшене (по соображениям безопасности и быстродействия).

**Подсказка:** вы можете попробовать этот скрипт в считанные секунды, ничего не устанавливая в систему. Просто склонируйте репозиторий, скопируйте `config.test` в `config`, и готово. Введите `./hm_local add testhost.local` (`sudo` не нужно) и загляните в каталог `test/`, чтобы увидеть, что там получилось.

**Возможности:**
* Apache в качестве основного веб-сервера.
* (опционально) Nginx в качестве фронт-енда - не особо-то важно для локальной разработки, но реализовано для более лёгкой интеграции с уже установленным Nginx.
* Поддержка CGI - помогает при работе с очень старыми сайтами (иногда приходится же);
* PHP в режиме классического CGI - весьма неэффективно для продакшена, но прекрасно для локальной разработки. Можно править PHP.INI наживую и ничего после этого не перезапускать. Если установлено несколько версий PHP, можно переключать их простой заменой символьной ссылки.
* эмулятор `sendmail` для перехвата писем, отправленных функцией `mail()`. (Конечно же, бесполезен для мейлеров, основанных на SMTP.)
* автоматическое исправление `/etc/hosts`.
* стандартные настройки конфигурации (`error_reporting`, `open_basedir`, `memory_limit`, `disable_functions`, etc.) достаточно строги, что позволяет вести разработку, держа в голове продакшен. Превышен `memory_limit` - а зачем моему скрипту нужно столько памяти, нельзя ли оптимизировать? Ограничение `open_basedir` - а зачем мой скрипт полез куда ему не надо? `shell_exec()` не сработал - а откуда он вызван, разве я где-то его использовал? (Разумеется, вы можете править настройки, редактируя PHP.INI для каждого хоста. Просто осознавайте, что делаете, и задавайте себе вопросы.)

## Установка

Описываю установку на чистую систему, с нуля. Если nginx и/или Apache уже установлены, пропускайте те этапы, которые для вас неактуальны.

Установите Apache (опционально с модулем `mpm-itk`) и PHP. Например, на Debian или Ubuntu:

```
user@home:~$ sudo apt-get update
user@home:~$ sudo apt-get install apache2-common apache2-mpm-itk \
             libapache2-mod-rpaf php5-common \
             php5-cli php5-cgi php5-gd php5-mcrypt php5-mysqlnd php5-xsl
user@home:~$ sudo service apache2 stop
```

Если вы планируете использовать Nginx, отредактируйте `/etc/apache2/apache2.conf`, чтобы Apache слушал порт 8080 (или какой-нибудь другой, не 80-ый).

```
user@home:~$ sudo service apache2 start
user@home:~$ sudo a2enmod rewrite
user@home:~$ sudo a2enmod cgi
user@home:~$ sudo a2enmod rpaf
# Если будете использовать nginx:
user@home:~$ wget http://nginx.org/keys/nginx_signing.key
user@home:~$ sudo apt-key add nginx_signing.key
user@home:~$ sudo bash -c 'echo "deb http://nginx.org/packages/DISTRO/ CODENAME nginx" >> /etc/apt/sources.list.d/nginx.list'
user@home:~$ sudo bash -c 'echo "deb-src http://nginx.org/packages/DISTRO/ CODENAME nginx" >> /etc/apt/sources.list.d/nginx.list'
user@home:~$ sudo apt-get update
user@home:~$ sudo apt-get install nginx
```

Здесь `DISTRO` - дистрибутив (`debian` или `ubuntu`), `CODENAME` - кодовое имя дистрибутива (список см. [здесь](http://nginx.org/ru/linux_packages.html)).

Создайте каталог для ваших виртуальных хостов.

Скачайте скрипт:

```
user@home:~$ cd /куда/хотите
user@home:~$ git clone https://github.com/Sketches-su/hm_local
user@home:~$ cd hm_local
user@home:~$ cp config.dist config
```

Теперь просмотрите и поправьте `config`. В первую очередь внимание нужно обратить на следующие параметры:
* `HM_USE_NGINX`
* `HM_USER`
* `HM_VHOST_PATH` - укажите полный путь к каталогу виртуальных хостов, созданному вами ранее;
* `APACHE_LISTEN_PORT`

Если вы не используете `mpm-itk`, в `tpl/apache2.conf` уберите директиву `AssignUserID`.

Выполните `crontab -e` и добавьте следующую строчку:

```
*/30 * * * * find /home/user/www/*/tmp -type f -name 'sess_*' -mmin +120 -delete
```

(не забудьте заменить `/home/user/www` на ваше значение `HM_VHOST_PATH`)

Инициализируйте файлы конфигурации:

```
user@home:~$ sudo touch /etc/apache2/sites-available/hm_local.conf
user@home:~$ sudo a2ensite hm_local
```

Теперь всё готово для создания первого виртуального хоста:

```
user@home:~$ sudo ./hm_local add test.local
```

Теперь откройте в браузере http://test.local/ и убедитесь, что "It works!".

## Использование

* `sudo ./hm_local add hostname [alias [alias [...]]]` - создаёт виртуальный хост. Если ни один псевдоним не указан, один создаётся автоматически (`www.hostname`). Но если хотя бы один псевдоним задан явно, `www.` не создаётся.
* `sudo ./hm_local del hostname` - удалить виртуальный хост со всеми файлами
* `sudo ./hm_local dis hostname` - деактивировать виртуальный хост (но не убирать из `/etc/hosts`)
* `sudo ./hm_local en hostname` - включить виртуальный хост
* `sudo ./hm_local rec` - пересобрать конфигурационные файлы и перезапустить сервисы (например, после редактирования `nginx.conf` или `apache2.conf` какого-либо виртуального хоста)

