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

# TODO: Maybe implement disable?
actions :enable

default_action :enable

attribute :base_dn, :kind_of => [ String ], :default => "cn=config"
attribute :user_cn, :kind_of => [ String ], :default => "cn=#{node[:openldap][:config_admin_cn]},cn=config"
attribute :user_password, :kind_of => [ String ], :default => node[:openldap][:config_admin_password]

attribute :name, :kind_of => [ String ], :name_attribute => true, :required => true