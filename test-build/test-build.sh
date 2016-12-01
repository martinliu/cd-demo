#!/bin/sh

#cd ${WORKSPACE}/src
#docker build -t 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER} .
#docker push 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER}
#cd ${WORKSPACE}/test-build

sed -i 's/\$\$BUILD_NUMBER\$\$/'${BUILD_NUMBER}'/g' docker-compose.yml
sed -i 's/\$\$PORT_NUMBER\$\$/'`expr 5000 + ${BUILD_NUMBER}`'/g' docker-compose.yml
chmod 777 ./rancher-compose
export RANCHER_CLIENT_DEBUG=true
./rancher-compose --debug --url http://52.78.73.245:8080/v1 --access-key 811E9C1B61479FF0BBCA --secret-key GCuVUSap2poayDiMwUhDnK8PH1tCs4XYYVrkkkDo -p python-redis-demo-build${BUILD_NUMBER} up -d 
#./rancher-compose --url http://10.0.0.5:8080 --access-key CA23527D9BE1E5855619 --secret-key GF6Q1vMsimqY8MHp6t17eqoZXcbQ8VEBcjU11z7H -p python-redis-demo-build27 up --pull -d --upgrade pyapp
# --confirm-upgrade
