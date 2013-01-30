default["openldap"]["listen_port"]          = "389"
default["openldap"]["schemas"]              = ["core","cosine","inetorgperson"]
default["openldap"]["home_dir"]             = "/mnt/storage/openldap"
default["openldap"]["db_dir"]               = ::File.join(node["openldap"]["home_dir"], "db")
default["openldap"]["config_dir"]           = ::File.join(node["openldap"]["home_dir"], "slapd.d")
default["openldap"]["cache_size"]           = "0 2097152 0"
default["openldap"]["max_objects"]          = "1500"
default["openldap"]["max_locks"]            = "1500"
default["openldap"]["max_lockers"]          = "1500"
default["openldap"]["checkpoint"]           = "512 30"
default["openldap"]["db_type"]              = "hdb"
default["openldap"]["replication_user_cn"]  = "dbrepl"

# TODO: Add platform specificity to these
default["openldap"]["pid_file"]             = "/var/run/openldap/slapd.pid"

case node["platform_family"]
  when "rhel"
    default["openldap"]["packages"]           = [
      "openldap-servers","openldap-clients","db4-utils"
    ]
    default["openldap"]["os_config_dir"]      = "/etc/openldap"
    default["openldap"]["os_db_dir"]          = "/var/lib/ldap" #?
    default["openldap"]["username"]           = "ldap"
    default["openldap"]["group"]              = "ldap"
    default["openldap"]["module_dir"]         = "/usr/lib64/openldap"
    default["openldap"]["slapd_options_file"] = "/etc/sysconfig/ldap"
  when "debian"
    packages = ["slapd","ldap-utils"]
    case node["platform_version"]
      when "9.10"
        packages << "db4.2-util"
      when "10.04"
        packages << "db4.7-util"
    end

    default["openldap"]["packages"]           = packages
    default["openldap"]["os_config_dir"]      = "/etc/ldap"
    default["openldap"]["os_db_dir"]          = "/var/lib/ldap" # TODO: Test this
    default["openldap"]["username"]           = "openldap"
    default["openldap"]["group"]              = "openldap"
    default["openldap"]["module_dir"]         = "/usr/lib/ldap" # TODO: Test this, could be lib64 instead?
    default["openldap"]["slapd_options_file"] = "/etc/default/slapd"
end