# Copyright 2011-2012, Ryan J. Geyer
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include Rgeyer::Chef::NetLdap

action :create do
  listen_host = ""
  listen_host = "127.0.0.1" unless node["openldap"]["allow_remote"] == "true"

  listen_port = node["openldap"]["listen_port"]

  sys_firewall node["openldap"]["listen_port"]

  slapd_dir = ::File.join(node["openldap"]["os_config_dir"], "slapd.d")
  bootstrap_file = ::File.join(slapd_dir, "bootstrapped")

  unless ::File.exist?(bootstrap_file)
    ::Chef::Log.info("Clobbering the openldap slapd.d configuration at #{node["openldap"]["os_config_dir"]}")
    slapd_conf = ::File.join(Chef::Config[:file_cache_path], "slapd.conf")

    ruby_block "Clobber #{node["openldap"]["os_config_dir"]}" do
      block do
        FileUtils.rm_rf(slapd_dir)
      end
    end

    directory slapd_dir do
      recursive true
      owner node["openldap"]["username"]
      group node["openldap"]["group"]
      action :create
    end

    template slapd_conf do
      source "slapd.conf.erb"
      cookbook "openldap"
      variables(
        :rootdn => new_resource.config_admin_dn,
        :rootpw => slappasswd_encode(new_resource.config_admin_password),
        :schemas => node["openldap"]["schemas"]
                )
    end

    execute "Convert slapd.conf to cn=config" do
      command "slaptest -f #{slapd_conf} -F #{slapd_dir}"
      notifies :delete, "template[#{slapd_conf}]"
    end

    execute "Set permissions for slapd.d directory" do
      command "chown -R #{node["openldap"]["username"]}:#{node["openldap"]["group"]} #{slapd_dir}"
    end

    file bootstrap_file do
      owner "root"
      group "root"
      action :create
    end
  end

  # TODO: Make this compatible with CentOS I.E. /etc/sysconfig/ldap
  # Seem to get a problem with slapd listening at all on the specified
  # port and LDAPI, disabling for now
  template node["openldap"]["slapd_options_file"] do
    source "slapd.options.erb"
    cookbook "openldap"
    variables(:listen_host => listen_host, :listen_port => listen_port)
    backup false
    action :nothing
  end

  service "slapd" do
    action [:enable,:restart]
  end

  # TODO: Bake this into the config provider and offer an enable/disable RootDSE
  if node["platform"] == "ubuntu" && node["platform_version"] == "9.10"
    openldap_execute_ldif do
      source "ubuntu-karmic-9.10-fixRootDSE.ldif"
      source_type :cookbook_file
    end
  end

  new_resource.updated_by_last_action(true)
end

action :add_syncprov_to_all_dbs do
  if is_consumer
    raise "Can not initialize this server as a provider, since it is already configured as a consumer."
  end

  hdb_filter = Net::LDAP::Filter.eq("objectclass", "olchdbconfig")
  bdb_filter = Net::LDAP::Filter.eq("objectclass", "olcbdbconfig")
  filter = hdb_filter | bdb_filter
  dbs = nil
  config_ldap{|ldap| dbs = ldap.search(:base => "cn=config", :filter => filter, :attributes => ["dn", "olcSuffix", "olcAccess"]) }

  # TODO: Should I clear all of the openldap:<basedn>=provider tags?

  dbs.each do |db|
    # Setup the overlay
    existing_overlay = nil
    config_ldap do |ldap|
      existing_overlay = ldap.search(:base => db.dn, :filter => Net::LDAP::Filter.eq("objectclass", "olcSyncProvConfig"))
    end
    update = existing_overlay.length > 0
    if update
      config_ldap do |ldap|
        ldap.modify(:dn => existing_overlay.first.dn, :operations => [
          [:replace, :olcSpCheckpoint, ["#{new_resource.provider_checkpoint_updates} #{new_resource.provider_checkpoint_minutes}"]]
        ])
      end
    else
      create_attrs = {
        :objectClass => ["olcOverlayConfig", "olcSyncProvConfig"],
        :olcOverlay => "syncprov",
        :olcSpCheckpoint => "#{new_resource.provider_checkpoint_updates} #{new_resource.provider_checkpoint_minutes}"
      }
      config_ldap do |ldap|
        ldap.add(:dn => "olcOverlay=syncprov,#{db.dn}", :attributes => create_attrs)
      end
    end

    db_suffix = db.olcSuffix.first.to_s
    repl_user_cn = node["db"]["replication"]["user"]
    repl_user_dn = "cn=#{repl_user_cn},#{db_suffix}"
    repl_user_pass = slappasswd_encode(node["db"]["replication"]["password"])
    # Create a replication user
    db_ldap(db_suffix) do |ldap|
      repl_user = ldap.search(:base => repl_user_dn)
      if repl_user && repl_user.length > 0
        ldap.modify(:dn => repl_user_dn, :operations => [[:replace, :userPassword, repl_user_pass]])
      else
        attributes = {
          :objectClass => ["person", "top"],
          :cn => repl_user_cn,
          :sn => repl_user_cn,
          :userPassword => repl_user_pass
        }
        ldap.add(:dn => repl_user_dn, :attributes => attributes)
      end
    end

    # Grant read access to the replication user
    olcaccess_operation = {
      :action => :add,
      :value => "to * by dn.exact=\"#{repl_user_dn}\" read"
    }

    db.olcaccess.each do |olcaccess|
      if /to \*|dn\.subtree="#{db_suffix}"/ =~ olcaccess
        olcaccess_operation[:action] = :none
        unless olcaccess.include?("by dn.exact=\"#{repl_user_dn}\" read")
          olcaccess_operation[:value] = "#{olcaccess} by dn.exact=\"#{repl_user_dn}\" read"
          olcaccess_operation[:action] = :replace
        end
      end
    end

    config_ldap do |ldap|
      ldap.modify(:dn => db.dn, :operations => [[olcaccess_operation[:action], :olcAccess, olcaccess_operation[:value]]])
    end unless olcaccess_operation[:action] == :none

    right_link_tag "openldap:#{db_suffix}=provider"
  end

  new_resource.updated_by_last_action(true)
end

action :add_olcsyncrepl_to_all_dbs do
  # TODO: Get this from tags or dns name
  provider_hostname = node[:db][:current_master_ip]

  hdb_filter = Net::LDAP::Filter.eq("objectclass", "olchdbconfig")
  bdb_filter = Net::LDAP::Filter.eq("objectclass", "olcbdbconfig")
  filter = hdb_filter | bdb_filter
  dbs = nil
  config_ldap{|ldap| dbs = ldap.search(:base => "cn=config", :filter => filter, :attributes => ["dn", "olcSuffix"]) }

  dbs.each do |db|
    db_suffix = db.olcSuffix.first.to_s

    repl_user_cn = node["db"]["replication"]["user"]
    repl_user_dn = "cn=#{repl_user_cn},#{db_suffix}"
    repl_user_pass = node["db"]["replication"]["password"]

    config_ldap do |ldap|
      olcSyncRepl = "rid=000 provider=ldap://#{provider_hostname} type=refreshAndPersist searchbase=#{db_suffix} bindmethod=simple binddn=#{repl_user_dn} credentials=#{repl_user_pass} attrs=\"*,+\""
      ldap.modify(:dn => db.dn, :operations => [[:add, :olcSyncRepl, olcSyncRepl]])
    end
  end

  new_resource.updated_by_last_action(true)
end

action :set_admin_creds do
  hashed_pass = slappasswd_encode(new_resource.config_admin_password)
  config_admin_dn = new_resource.config_admin_dn
  if `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcRootPw=*)"` =~ /numEntries/
    openldap_execute_ldif do
      executable "ldapadd"
      source "deleteConfigAdminPassword.ldif"
      source_type :cookbook_file
    end
  end

  if `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcRootDn=*)"` =~ /numEntries/
    openldap_execute_ldif do
      executable "ldapadd"
      source "deleteConfigAdminDn.ldif"
      source_type :cookbook_file
    end
  end

  openldap_execute_ldif do
    executable "ldapadd"
    source "setConfigAdminCreds.ldif.erb"
    source_type :template
    config_admin_dn config_admin_dn
    config_admin_password hashed_pass
  end

  new_resource.updated_by_last_action(true)
end