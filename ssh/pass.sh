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
