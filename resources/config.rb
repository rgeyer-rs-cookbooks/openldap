# Copyright 2012, Ryan J. Geyer
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

actions :create
actions :add_syncprov_to_all_dbs
actions :add_olcsyncrepl_to_all_dbs
actions :set_admin_creds

default_action :create

attribute :config_admin_dn, :kind_of => [ String ], :default => "cn=#{node["db"]["admin"]["user"]},cn=config"
attribute :config_admin_password, :kind_of => [ String ], :default => node["db"]["admin"]["password"]

# Required for :add_syncprov_to_all_dbs
attribute :provider_checkpoint_updates, :kind_of => [ Integer ], :default => 100
attribute :provider_checkpoint_minutes, :kind_of => [ Integer ], :default => 10