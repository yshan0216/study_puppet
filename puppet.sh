名词解释：
事实(fact)





cat > init.pp << "EOF"
class sudo {
	package { 'sudo':
		ensure => present,
	}
	
	if $::osfamily == 'Debian' {
		package { 'sudo-ldap':
			ensure => present,
			require => Package['sudo'],
		}
	}
	
	file {
		owner => 'root',
		group => 'root',
		mode => '0440',
		source => "puppet://$::server/modules/sudo/etc/sudoers",
		require => Package['sudo'],
	}
}
EOF


#/etc/puppet/puppet.conf
[main]
logdir = /var/log/puppet
vardir = /var/lib/puppet
ssldir = /var/lib/puppet/ssl
rundir = /var/run/puppet
factpath = $vardir/lib/facter
pluginsync = true
runinterval = 1380
configtimeout = 600
splay = true
report = true
server = puppet.example.com
ca_server = puppetca.example.com

#/etc/puppet/manifests/site.pp
node 'puppet.example.com'
{
# Puppet code will go here.
}
node 'web.example.com'
{
# Puppet code will go here.
}
node 'db.example.com'
{
# Puppet code will go here.
}
node 'mail.example.com'
{
# Puppet code will go here.
}


#相似主机的处理方法
node
	'web1.example.com',
	'web2.example.com',
	'web3.example.com',
{
# Puppet code goes here
}

#使用正则表达式
node /^web\d+\.example\.com$/

node default {
	include defaultclass
}

#节点继承
#Puppet支持节点继承，但并不推荐使用这种方法。
node basenode{
	include sudo
	include mailx
}

node 
	'web.example.com'
	inherits basenode{
		include apache
}

#变更及变量域的概念。
#Puppet是一种声明式语言，声明式语言的性质要求顺序不能影响变量值。
#这一原则即要求<在同一变量域中>不能以一个变更进行重复定义。

#什么是域？
#简单理解就是变量的有效作用范围。
#每个类、定义、节点都会引入一个新的域。
#Puppet存在4种域:顶级域、节点域、父域、本地域
#顶级域
#1、在所有的结构体之外，即是顶极域。
#2、所有在site.pp中定义和导入的清单都属于顶级域。
#3、在变量前加上::就可以显式地访问顶级域。
#例如：通常把fact写成$::osfamily，由于明确了变量所在域，避免变量在任意位置被重新赋值。

#节点域
#1、指节点定义中节点名称后面的一对大括号包围的区域。

#父域
#1、如果类A通过inherits引用类B，则B是A的父域。

#本地域
#1、由一个类或类型定义包围的区域。

#模块
#1、由Puppet资源、类、文件和配置文件模板组成的自包含集合。
#2、模块是Puppet清单的结构化组合。
#3、Puppet根据module path寻找模块并加载，值由/etc/puppet/puppet.conf的$modulepath定义。
#4、默认包括/etc/puppet/modules和/var/lib/puppet/modules这两个目录。

#模块的目录结构
#sudo模块/etc/puppet/modules/sudo/
/manifests
/manifests/init.pp
/files
/templates

#init.pp文件结构
class sudo {
	configuration
}

#使用puppet模块构建工具
puppet module generate module-name
#模块名称常用的命名规则是"组织名称+服务名称"

#使用git管理模板代码
#1、安装git
apt-get install git
#2、配置全局变量
git config --global user.name "tony"
git config --global user.email "tony@example.com"
#3、初始化工作目录
cd /etc/puppet/modules
git init
#4、将目录下所有文件加入版本库
git add *
#5、提交变更到版本库。
git commit -a -m "Initial commit"
#6、查看git版本信息
git log
git status


#file:ssh/manifests/init.pp
class ssh {
	class {'::ssh::install':} ->
	class {'::ssh::config':} ->
	class {'::ssh::service':} ->
	class['ssh']
}

#file:ssh/manifests/install.pp
class ssh::install {
	package {
		"openssh":
		ensure => present,
	}
}

#file:ssh/manifests/config.pp
class ssh::config {
	file {
		"/etc/ssh/sshd_config":
		ensure => present,
		owner => root,
		group => root,
		mode => 0600,
		source => "puppet:///modules/ssh/sshd_config",
		require => class["ssh::install"],
		notify => class["ssh::service"],
	}
}

#file:ssh/manifests/service.pp
class ssh::service {
	service {
		"sshd":
		ensure => running,
		hasstatus => true,
		hasrestart => true,
		enable => true,
		require => class["ssh::config"],
	}
}


#Page 42
#file:ssh/manifests/install.pp
class ssh::install {
	$package_name = $::osfamily ?
		'Redhat' => "openssh-server",
		'Debian' => "openssh-server",
		'Solaris' => "openssh",
	}
	package {
		"ssh":
		ensure => present,
		name => $package_name,
	}
}

#Page 43
#class ssh::params
class ssh:params {
	case $::osfamily {
		Solaris:{
			$ssh_package_name = 'opessh'
		}
		Debian:{
			$ssh_package_name = 'opessh-server'
		}
		Redhat:{
			$ssh_package_name = 'opessh-server'
		}
		default:{
			fail("Module propuppet-ssh does not support osfamily: ${::osfamily}")
		}
	}
}


第四章
4.2使用Apache和Passenger运行Puppet Master
Phusion Passenger模块也称为mod_rails、mod_passenger或Passenger。
是一个将Ruby程序嵌入执行的Apache模块。

Puppet性能提升的几个有效方法：
1、将默认Web服务器替换成Apache或Nginx。
2、使用负载均衡软件。

第六章
虚拟资源：可以让example.com的域 管理员在一个地方定义一组用户资源，然后选择性地将其中的一个子集添加到配置目录中。管理员不需要担心资源重复定义的的问题，因为资源只会声明一次，然后被实例化或“实现”一次或者多次。
这个类似于类和类的实例化声明。

Puppet queue使用ActiveMQ中间件服务来处理信息传递和队列。
Apache ActiveMQ是一个消息代理中间件服务，用于处理异步和同步消息的传递。
Active MQ基于Java编写。运行是需要JRE环境。
官方网站：activemq.apache.org









