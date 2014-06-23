sentry-formula
==============

Installs sentry on a box. Automatically installs postgresql on the same box.
Basic configurability is exposed through pillar. In case you have unique configuration requirements,
just overwrite `sentry/templates/sentry.conf.py` file in your main `file_roots` folder.

See salt docs [file_roots](http://docs.saltstack.com/en/latest/ref/file_server/file_roots.html)


On first install it creates superuser.
- username: sentry
- password: sentry
- email: sentry@example.com


pillar
======
example::

    sentry:
      external_url: http://sentry.example.com
      x_forwarded': False
      secret': 12345678901234567890987654321234567890po[hgfrt567iuyj
