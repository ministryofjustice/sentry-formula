{% from "sentry/map.jinja" import sentry with context %}
{% from 'utils/apps/lib.sls' import app_skeleton with context %}

include:
  - nginx
  - postgresql
  - supervisor
  - firewall
  - logstash.client


{{ app_skeleton('sentry') }}


postgres_user_sentry:
  postgres_user.present:
    - name: sentry
    - createdb: True
    - password: sentry
    - runas: postgres
    - require:
      - service: postgresql


postgres_database_sentry:
  postgres_database.present:
    - name: sentry
    - encoding: UTF8
    - lc_ctype: en_GB.UTF-8
    - lc_collate: en_GB.UTF8
    - template: template0
    - owner: sentry
    - runas: postgres
    - require:
        - postgres_user: postgres_user_sentry


sentry-deps:
  pkg.installed:
    - pkgs:
      - build-essential
      - python-dev


/srv/sentry/application/current:
  file.directory:
    - user: sentry
    - group: sentry
  virtualenv.managed:
    - user: sentry
    - system_site_packages: False
    - requirements: salt://sentry/files/requirements.txt


/srv/sentry/application/current/sentry.conf.py:
  file.managed:
    - source: salt://sentry/templates/sentry.conf.py
    - template: jinja
    - mode: 600
    - owner: sentry
    - group: sentry
    - require:
      - file: /srv/sentry/application/current
    - watch_in:
      - supervisord: supervise-sentry


sentry-init:
  cmd.wait:
    - name: /srv/sentry/application/current/bin/sentry upgrade
    - user: sentry
    - require:
      - user: sentry
    - env:
        SENTRY_CONF: /srv/sentry/application/current/sentry.conf.py
    - watch:
      - file: /srv/sentry/application/current/sentry.conf.py
      - virtualenv: /srv/sentry/application/current


#based on: https://sentry.readthedocs.org/en/latest/faq/index.html#how-do-i
sentry-bootstrap:
  cmd.script:
    - name: salt://sentry/templates/bootstrap.py
    - template: jinja
    - user: sentry
    - unless: 'test -e /srv/sentry/application/shared/bootstrap_project'
    - env:
        SENTRY_CONF: /srv/sentry/application/current/sentry.conf.py
    - require:
      - user: sentry
      - file: /srv/sentry/application/current/sentry.conf.py
      - virtualenv: /srv/sentry/application/current


{% from 'supervisor/lib.sls' import supervise with context %}
{{ supervise('sentry',
             cmd="/srv/sentry/application/current/bin/sentry",
             args="--config=/srv/sentry/application/current/sentry.conf.py start",
             working_dir="/srv/sentry/application/current",
             supervise=True) }}


/etc/nginx/conf.d/sentry.conf:
  file:
    - managed
    - source: salt://nginx/templates/vhost-proxy.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: nginx
    - require:
      - pkg: nginx
    - context:
      appslug: sentry
      server_name: 'sentry.*'
      proxy_to: localhost:9000


{% from 'logstash/lib.sls' import logship with context %}
{{ logship('sentry-access', '/var/log/nginx/sentry.access.json', 'nginx', ['nginx','sentry','access'], 'rawjson') }}
{{ logship('sentry-error',  '/var/log/nginx/sentry.error.log', 'nginx', ['nginx','sentry','error'], 'json') }}


{% from 'firewall/lib.sls' import firewall_enable with  context %}
{{ firewall_enable('sentry',9000,proto='tcp') }}
