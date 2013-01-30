maintainer       "Ryan J. Geyer"
maintainer_email "me@ryangeyer.com"
license          "Apache 2.0"
description      "Installs/Configures openldap"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

%w{rightscale rightscale_sandbox sys_dns block_device db}.each do |d|
  depends d
end

supports "ubuntu"
supports "centos"

recipe "openldap::default", "It's the default"
recipe "openldap::do_create_database", "Creates a new database to contain records for the specified base_dn"
recipe "openldap::do_enable_schemas", "Enables the OpenLDAP schemas listed"
recipe "openldap::install_openldap", "Installs a basic, working OpenLDAP server daemon"
recipe "openldap::setup_rightscale_syslog", "Appends configuration for OpenLDAP to the RightScale syslog configuration."

attribute "openldap/allow_remote",
  :display_name => "OpenLDAP Allow Remote?",
  :description => "A boolean indicating if the OpenLDAP server should accept remote connections or not",
  :choice => ["true", "false"],
  :required => "required",
  :category => "OpenLDAP Daemon",
  :recipes => ["openldap::install_openldap", "openldap::default"]

attribute "openldap/listen_port",
  :display_name => "OpenLDAP listen port",
  :description => "The TCP/IP port the OpenLDAP server should listen on",
  :default => "389",
  :category => "OpenLDAP Daemon",
  :recipes => ["openldap::install_openldap", "openldap::default"]

attribute "openldap/schemas",
  :display_name => "OpenLDAP Schemas",
  :description => "A list (in the form of an array) of schemas to install",
  :type => "array",
  :default => ["core","cosine","inetorgperson"],
  :category => "OpenLDAP olcConfig",
  :recipes => ["openldap::install_openldap", "openldap::do_enable_schemas", "openldap::default"]

attribute "openldap/database_admin_cn",
  :display_name => "OpenLDAP Database Admin CN",
  :description => "The desired \"Common Name\" for the administrator of the new database",
  :required => "required",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/database_admin_password",
  :display_name => "OpenLDAP Config Admin password",
  :description => "The desired password for the administrator of the new database",
  :required => "required",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/base_dn",
  :display_name => "OpenLDAP Database Base DN",
  :description => "The base DN of the new database to create, if set to 'Ignore' the new database will contain all DN's other than cn=config",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/db_type",
  :display_name => "OpenLDAP Database Type",
  :description => "The OpenLDAP database type, currently only bdb and hdb are supported",
  :choice =>  ["hdb","bdb"],
  :default => "hdb",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/cache_size",
  :display_name => "OpenLDAP Database Cache Size",
  :description => "A Berkley DB tuning setting, leave it as \"0 2097152 0\" if you don't know what you're doing.",
  :default => "0 2097152 0",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/max_objects",
  :display_name => "OpenLDAP Database Max Objects",
  :description => "A Berkley DB tuning setting, leave it as \"1500\" if you don't know what you're doing.",
  :default => "1500",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/max_locks",
  :display_name => "OpenLDAP Database Max Locks",
  :description => "A Berkley DB tuning setting, leave it as \"1500\" if you don't know what you're doing.",
  :default => "1500",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/max_lockers",
  :display_name => "OpenLDAP Database Max Lockers",
  :description => "A Berkley DB tuning setting, leave it as \"1500\" if you don't know what you're doing.",
  :default => "1500",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]

attribute "openldap/checkpoint",
  :display_name => "OpenLDAP Database Checkpoint",
  :description => "A Berkley DB tuning setting, leave it as \"512 30\" if you don't know what you're doing.",
  :default => "512 30",
  :category => "OpenLDAP Database",
  :recipes => ["openldap::do_create_database"]