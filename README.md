# Landoop Ansible Roles

In this repository we share some of our ansible roles that we think may be of interest.

We take care to convert them into examples rather than the more complex versions we use
for our specific needs.

Our OS of choice is CentOS 7 and we usually avoid to compensate for different OSes, so
keep this in mind. We like other GNU/Linux distributions too but keeping our systems
uniform helps with the administration burden.

# Roles

## nginx-lets-encrypt

This role set's up nginx with let's encrypt support. It downloads automatically
certificates for new sites provided proper DNS records. It sets up a cron job to
renew them automatically.

It also backups certificates and acmetool's configuration files into your ansible repo.
It is a good idea to use `git-crypt` to protect them. Backup helps you avoid let's
encrypt limits while experimenting and reconcile your certs in case of emergency.

You can find a sample nginx configuration file at
`roles/nginx-lets-encrypt/files/conf.d/TEMPLATE.conf.sample`. You should use it as
it contains boilerplate that ensure's lets encrypt support. We chose specifically
to use a http-proxy for handling let's encrypt challenge responses, in order to be
able to easily host many sites on one machine.
