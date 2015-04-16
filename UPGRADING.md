Upgrading from v1.x.x To v2.x.x
--------------------------------

When upgrading to sentry v7.x.x from v6.x.x, you may run into the following issue captured here https://github.com/getsentry/sentry/issues/1386

The workaround is as follows:

```bash
  $sudo su - sentry
  sentry@monitoring-01:~$ psql
  sentry=> update sentry_project set team_id = (select id from sentry_team limit 1) where team_id is null;
```

Then you can now run a salt highstate as usual:

```bash
sudo salt-call state.highstate
```
