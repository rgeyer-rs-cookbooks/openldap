# DESCRIPTION:
A set of Chef tools for installing, configuring, and managing OpenLDAP

# REQUIREMENTS:
This cookbook requires the rightscale cookbook.

# ATTRIBUTES:

openldap/config_admin_password, set as the rootpw for the cn=config database, as well as all databases created (or accessed) by this cookbook

A rootdn will be created named cn=chef-openldap-cookbook,<basedn> for any database created or accessed by this cookbook

As a failsafe, all databases will allow manage from a locally authenticated (by SASL) user connecting to LDAPI

# USAGE:

# TODO:

* Security
  * Consider creating a user for each DB which will be the "admin" user for this cookbook.  This would *not* be the rootdn and rootpw, and would be restricted to access from localhost only using "peername" http://www.openldap.org/doc/admin24/access-control.html

collectd monitoring goodness.
http://prefetch.net/articles/monitoringldap.html

Use a rubygem to access and manipulate ldap
https://rubygems.org/gems/net-ldap

Fully implement provider/consumer

Enable LDAP over SSH encryption

CRAZY MAD UZEFULZ -- http://blogs.mindspew-age.com/tag/memory-mapped-database/

Backup infoz
  * http://www.openldap.org/faq/data/cache/287.html
  * http://www.openldap.org/lists/openldap-technical/201202/msg00121.html
  * http://www.openldap.org/lists/openldap-software/200608/msg00152.html