# Copyright 2013, Ryan J. Geyer
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

action :stop do
  service "slapd" do
    action :stop
  end
end

action :start do
  service "slapd" do
    action :start
  end
end

action :restart do
  service "slapd" do
    action :restart
  end
end

action :status do
  status = `service slapd status`
  Chef::Log.info "  OpenLDAP Status:\n#{status.strip}"
end

action :lock do
  # TODO: Set olcReadOnly to True
end

action :unlock do
  # TODO: Set olcReadOnly to False
end

action :move_data_dir do
  # Config Dir
  slapd_dir = ::File.join(node["openldap"]["os_config_dir"], "slapd.d")
  unless ::File.symlink?(slapd_dir) ||
    (::File.directory?(node["openldap"]["config_dir"]) && ::Dir.entries(node["openldap"]["config_dir"]).size > 0)
    directory node["openldap"]["config_dir"] do
      recursive true
      owner node["openldap"]["username"]
      group node["openldap"]["group"]
      mode 0700
      action :create
    end

    execute "Move OpenLDAP Config Dir" do
      command "mv #{slapd_dir}/* #{node["openldap"]["config_dir"]}/"
    end

    ruby_block "Delete OpenLDAP OS Config Dir" do
      block do
        FileUtils.rm_rf(slapd_dir)
      end
    end
  end

  link slapd_dir do
    to node["openldap"]["config_dir"]
  end

  # DB Dir
  unless ::File.symlink?(node["openldap"]["os_db_dir"]) ||
    (::File.directory?(node["openldap"]["db_dir"]) && ::Dir.entries(node["openldap"]["db_dir"]).size > 0)
    directory node["openldap"]["db_dir"] do
      recursive true
      owner node["openldap"]["username"]
      group node["openldap"]["group"]
      mode 0700
      action :create
    end

    execute "Move OpenLDAP Data Dir" do
      command "mv #{node["openldap"]["os_db_dir"]}/* #{node["openldap"]["db_dir"]}/"
    end

    ruby_block "Delete OpenLDAP OS Data Dir" do
      block do
        FileUtils.rm_rf(node["openldap"]["os_db_dir"])
      end
    end
  end

  link node["openldap"]["os_db_dir"] do
    to node["openldap"]["db_dir"]
  end
end

action :reset do
  # TODO: Not sure what to do here?
end

action :firewall_update_request do
  sys_firewall "Sending request to open port #{node["openldap"]["listen_port"]} allowing this server to connect" do
    machine_tag new_resource.machine_tag
    port node["openldap"]["listen_port"].to_i
    enable new_resource.enable
    ip_addr new_resource.ip_addr
    action :update_request
  end
end

action :firewall_update do
  sys_firewall "Opening port #{node["openldap"]["listen_port"]} for tagged '#{new_resource.machine_tag}' to connect" do
    machine_tag new_resource.machine_tag
    port node["openldap"]["listen_port"]
    enable new_resource.enable
    action :update
  end
end

action :write_backup_info do
  # TODO: What exactly should I write to file?
end

action :pre_restore_check do
  # TODO: Eh?
  true
end

action :post_restore_cleanup do
  # Config Dir
  slapd_dir = ::File.join(node["openldap"]["os_config_dir"], "slapd.d")

  ruby_block "Delete OpenLDAP OS Config Dir" do
    block do
      FileUtils.rm_rf(slapd_dir)
    end
  end

  link slapd_dir do
    to node["openldap"]["config_dir"]
  end

  # DB Dir
  ruby_block "Delete OpenLDAP OS Data Dir" do
    block do
      FileUtils.rm_rf(node["openldap"]["os_db_dir"])
    end
  end

  link node["openldap"]["os_db_dir"] do
    to node["openldap"]["db_dir"]
  end

  true
end

action :pre_backup_check do
  # TODO: Eh?
  true
end

action :post_backup_cleanup do
  # TODO: Eh?
  true
end

action :set_privileges do
  # TODO: Maybe refactor the config :set_admin_creds
end

action :remove_anonymous do
  # TODO: Seriously?
end

action :install_client do
  # TODO: I think it's just gonna be everything installed by install_server
end

action :install_server do
  node["openldap"]["packages"].each do |p|
    package p
  end

  openldap_config "Create an initial slapd.d config if it does not exist" do
    action :create
  end

  openldap_config "Set (or reset) persistent admin creds" do
    action :set_admin_creds
  end

  %w{back_bdb back_hdb}.each do |mod|
    openldap_module mod do
      action :enable
    end
  end

  openldap_schema "Enable schema list" do
    schemas node["openldap"]["schemas"]
    action :enable
  end
end

action :install_client_driver do
  # TODO: Don't think it's necessary, no real app/client ST's
end

action :setup_monitoring do
  # TODO: Lots of goodies in the monitor overlay should be turned on and captured
end

action :grant_replication_slave do
  openldap_module "syncprov" do
    action :enable
  end

  openldap_config "Add syncprov to all databases" do
    action :add_syncprov_to_all_dbs
  end
end

action :promote do
  # TODO: We're not there yet
end

action :enable_replication do
  # TODO: This gets run on the slave/consumer during the initialization process
  openldap_config "Add olcsyncrepl to all databases" do
    action :add_olcsyncrepl_to_all_dbs
  end
end

action :generate_dump_file do
  # TODO: Do a slapcat export
end

action :restore_from_dump_file do
  # TODO: slapadd an LDIF file
end