# Copyright 2011-2013, Ryan J. Geyer
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
  base_dn     = new_resource.base_dn
  db_type     = new_resource.db_type
  cache_size  = new_resource.cache_size
  max_objects = new_resource.max_objects
  max_locks   = new_resource.max_locks
  max_lockers = new_resource.max_lockers
  checkpoint  = new_resource.checkpoint

  admin_pwd = slappasswd_encode(new_resource.db_admin_password)
  admin_dn = "cn=#{new_resource.db_admin_cn}"
  admin_cn = new_resource.db_admin_cn

  config_pwd = new_resource.config_admin_password
  config_dn = "cn=chef-openldap-cookbook,#{base_dn}"

  admin_dn = "#{admin_dn},#{base_dn}" if base_dn
  existing_db = config_ldap.search(:base => "cn=config", :filter => Net::LDAP::Filter.eq("olcSuffix", base_dn))
  if existing_db.length > 0
    Chef::Log.info("A database already exists for entries under #{base_dn}.  Exiting...")
  else
    create_db_attrs = {
      :objectclass => ["olcDatabaseConfig","olc#{db_type}Config"],
      :olcDatabase => "{1}#{db_type}",
      :olcDbDirectory => node["openldap"]["os_db_dir"],
      :olcSuffix => base_dn,
      :olcDbConfig => ["{0}set_cachesize #{cache_size}",
                       "{1}set_lk_max_objects #{max_objects}",
                       "{2}set_lk_max_locks #{max_locks}",
                       "{3}set_lk_max_lockers #{max_lockers}"],
      :olcLastMod => "TRUE",
      :olcDbCheckpoint => checkpoint,
      :olcDbIndex => ["uid pres,eq",
                      "cn,sn,mail pres,eq,approx,sub",
                      "objectClass eq"],
      :olcAccess => "to * by self write by anonymous auth by dn.exact=\"#{admin_dn}\" manage by dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" manage",
      :olcRootDN => config_dn,
      :olcRootPw => config_pwd
    }
    config_ldap{|ldap| ldap.add(:dn => "olcDatabase={1}#{db_type},cn=config", :attributes => create_db_attrs) }

    unless base_dn.empty?
      db_ldap(base_dn){|ldap| ldap.add(:dn => base_dn, :attributes => {:objectclass => ["domain","top"]}) }
    end

    db_ldap(base_dn){|ldap| ldap.add(:dn => admin_dn, :attributes => {:objectclass => ["person","top"], :cn => admin_cn, :sn => admin_cn, :userPassword => admin_pwd}) }
  end

  new_resource.updated_by_last_action(true)
end