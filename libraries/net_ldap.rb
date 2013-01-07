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

begin
  require 'net-ldap'
rescue LoadError
  Chef::Log.warn("net-ldap gem not installed, be sure to run openldap::setup_openldap")
end

module Rgeyer
  module Chef
    module NetLdap
      def secure_password
        chars = (
          ('a'..'z').to_a +
          ('A'..'Z').to_a +
          ('0'..'9').to_a +
          ["!","@","#","$","%","^","&","*","(",")","-","_","=","+"]
        ) - %w(i o 0 1 l 0)
        (1..32).collect{|a| chars[rand(chars.size)] }.join
      end

      def slappasswd_encode(password)
        `slappasswd -s "#{password}"`
      end

      def config_ldap(&block)
        @@config_ldap ||= Net::LDAP.new(
          :base => "cn=config",
          :auth => {
            :method => :simple,
            :username => new_resource.config_admin_dn,
            :password => new_resource.config_admin_password
          }
        )
        if block
          retval = nil
          @@config_ldap.open{|l| yield l }
          unless @@config_ldap.get_operation_result.code == 0
            raise "LDAP Code: #{@@config_ldap.get_operation_result.code} Error: #{@@config_ldap.get_operation_result.message} -- #{@@config_ldap.get_operation_result.inspect}"
          end
          retval
        else
          @@config_ldap
        end
      end

      def db_ldap(base_dn, &block)
        password = new_resource.config_admin_password
        root_dn = "cn=chef-openldap-cookbook,#{base_dn}"
        config_ldap do |ldap|
          olc_db_record = ldap.search(:dn => "cn=config", :filter => ::Net::LDAP::Filter.eq("olcSuffix", base_dn))
          # TODO: Error handling/reporting if the specified DB base_dn does not exist
          ldap.delete_attribute(olc_db_record.first.dn, :olcRootDN)
          ldap.delete_attribute(olc_db_record.first.dn, :olcRootPW)
          ldap.modify(:dn => olc_db_record.first.dn, :operations => [
            [:replace, :olcRootDN, root_dn],
            [:replace, :olcRootPW, slappasswd_encode(password)]
          ])
        end
        db_ldap = Net::LDAP.new(
          :base => base_dn,
          :auth => {
            :method => :simple,
            :username => root_dn,
            :password => password
          }
        )
        retval = nil
        db_ldap.open {|l| yield l }
        unless db_ldap.get_operation_result.code == 0
          raise "LDAP Code: #{db_ldap.get_operation_result.code} Error: #{db_ldap.get_operation_result.message} -- #{db_ldap.get_operation_result.inspect}"
        end
        retval
      end

      def is_consumer
        config_ldap.search(:base => "cn=config",:filter => Net::LDAP::Filter.eq('olcsyncrepl', '*')).length > 0
      end
    end
  end
end