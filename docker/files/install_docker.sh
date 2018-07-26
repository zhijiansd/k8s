#!/bin/bash
##安装相应系统工具
yum -y install yum-utils device-mapper-persistent-data lvm2
##添加源
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
##安装docker
yum -y install docker-ce
