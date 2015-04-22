#!/srv/sentry/application/current/bin/python
{% from "sentry/map.jinja" import sentry with context %}

from sentry.utils.runner import configure
configure()

from sentry.models import Team, Project, ProjectKey, User, Organization

user = User()
user.username = '{{sentry.bootstrap.username}}'
user.email = '{{sentry.bootstrap.email}}'
user.is_superuser = True
user.set_password('{{sentry.bootstrap.password}}')
user.save()

organization = Organization()
organization.name = '{{sentry.bootstrap.organization}}'
organization.owner = user
organization.save()

team = Team()
team.organization = organization
team.name = '{{sentry.bootstrap.team}}'
team.owner = user
team.save()

project = Project()
project.organization = organization
project.team = team
project.owner = user
project.name = '{{sentry.bootstrap.project}}'
project.save()

#let's replace the key
key = ProjectKey.objects.filter(project=project)[0]
key.public_key = '{{sentry.bootstrap.public_key}}'
key.secret_key = '{{sentry.bootstrap.secret_key}}'
key.save()
print 'SENTRY_DSN = "%s"' % (key.get_dsn(),)

with open('/srv/sentry/application/shared/bootstrap_project', 'w') as f:
    f.write(key.get_dsn())
