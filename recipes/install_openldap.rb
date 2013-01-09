#
# Cookbook Name:: openldap
# Recipe:: install_openldap
#
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

rightscale_marker :begin

include_recipe "openldap::default"

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

directory node["openldap"]["db_dir"] do
  recursive true
  owner node["openldap"]["username"]
  group node["openldap"]["group"]
  action :create
end

right_link_tag "openldap:active=true"

rightscale_marker :end