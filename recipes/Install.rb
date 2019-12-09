#
# Cookbook:: KafkaServer
# Recipe:: Install
#
# Copyright:: 2019, The Authors, All Rights Reserved.

package %w(java-1.8.0-openjdk-devel git tmux) do
  action :install
end

group 'kafkaAdmin'

user 'kafkaAdmin' do
  manage_home false
  shell '/bin/nologin'
  group 'kafkaAdmin'
  home '/home/kafkaAdmin'
  action :create
end

# kafka_2.12-2.3.0
package_name = "kafka_2.12-#{node['kafkaServer']['kafkaVersion']}"

# https://www-eu.apache.org/dist/kafka/2.3.0/kafka_2.12-2.3.0.tgz
package_path = "#{node['kafkaServer']['kafkaRepo']}#{node['kafkaServer']['kafkaVersion']}/#{package_name}.tgz"

# /opt/kafka_2.12-2.3.0.tgz
local_path = "/opt/#{package_name}.tgz"

directory 'kafkaDirectory' do
  path "/opt/#{package_name}"
  group 'kafkaAdmin'
  action :create
end

remote_file 'kafkaPackage' do
  path local_path
  source package_path
  action :create
end

# tar -xvf /opt/kafka_2.12-2.3.0.tgz -C /opt/kafka_2.12-2.3.0 --strip-components=1
execute 'untarKafka' do
  command "tar -xvf #{local_path} -C /opt/#{package_name} --strip-components=1"
  action :run
end

# ln -s /opt/kafka_2.12-2.3.0 /opt/kafka
execute 'kafkaSymLink' do
  command "ln -s /opt/#{package_name} /opt/kafka"
  action :run
end

execute 'kafkaPermissions' do
  command 'chown -R kafkaAdmin:kafkaAdmin /opt/kafka*'
  action :run
end

template 'zookeeperTemplate' do
  source 'zookeeper.service.erb'
  path '/etc/systemd/system/zookeeper.service'
  owner 'root'
  group 'root'
  action :create
end

template 'kafkaTemplate' do
  source 'kafka.service.erb'
  path '/etc/systemd/system/kafka.service'
  owner 'root'
  group 'root'
  action :create
end

execute 'reloadService' do
  command 'systemctl daemon-reload'
  action :run
end

service 'zookeeperService' do
  service_name 'zookeeper'
  action :start
end

service 'kafkaService' do
  service_name 'kafka'
  action :start
end

file 'clean' do
  path local_path
  action :delete
end
