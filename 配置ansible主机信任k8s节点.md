#生成ssh公钥认证所需的公钥和私钥文件
``` bash
# ssh-keygen -t rsa -P ''
# vim /root/password.txt 
192.168.100.181  123456
192.168.100.182  123456
192.168.100.183  123456
192.168.100.184  123456
192.168.100.185  123456
```
注:不要留空，不然脚本会认为空白行也是需要执行的，会非正常退出。
#配置分发密钥脚本并分发密钥
``` bash
#!/bin/bash
##分发秘钥
copy-sshkey()
{
file=/root/password.txt

if [ -e $file ]
then
 echo "---password文件存在,分发秘钥---"
 cat $file | while read line
 do
    host_ip=`echo $line | awk '{print $1}'`
    password=`echo $line | awk '{print $2}'`
    echo "$host_ip"

   /usr/bin/expect << EOF
   set time 20
   spawn ssh-copy-id -i .ssh/id_rsa.pub root@$host_ip
   expect {  
        "(yes/no)?"  
        {  
                send "yes\n"  
                expect "password:" {send "$password\n"}  
        }  
        "*password:"  
        {  
                send "$password\n"  
        }  
    } 
   expect eof  
EOF
 done
else
 echo "---文件不存在---"
fi
}
copy-sshkey

if   [ $? == 0 ]
then
     echo "---脚本正常执行,删除密码文件--- "
     rm -rf $file
else
     echo "---脚本未正常执行--- "
fi
# chmod 755 pass.sh 
# source pass.sh
```
