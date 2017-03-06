yum install salt-api
useradd -M -s /sbin/nologin saltdev
echo "saltdev" |passwd --stdin saltdev
# salt api基于证书通信
CRT_DIR=/etc/pki/tls/certs
PRIVADE_KEY_DIR=/etc/pki/tls/private
cd $CRT_DIR
make testcert
cd ../private
# 解码key，生成无密码key文件
openssl rsa -in localhost.key -out localhost_nopass.key

echo "
rest_cherrypy:
  port: 8000
  debug: True
  ssl_crt: $CRT_DIR/localhost.crt
  ssl_key: $PRIVADE_KEY_DIR/localhost_nopass.key
external_auth:
  pam:
    saltdev:
      - .*
      - '@wheel'
      - '@runner'
" >> /etc/salt/master
service salt-master restart
service salt-api restart

# 测试
# curl -k https://192.168.1.99:8000/login -H "Accept: application/x-yaml" -d username='saltdev' -d password='saltdev' -d eauth='pam'
# curl -k https://192.168.1.99:8000/ -H "Accept: application/x-yaml" -H "X-Auth-Token: 8b62b1a9ae6d65b3c25774a725297e0e3316830e" -d client='local' -d tgt='*' -d fun='test.ping'