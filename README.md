# cd-demo

## 环境准备

启动三个AMI实例

* Amazon Linux AMI 2016.09.0 (HVM), SSD Volume Type
* Instance type: t2.micro
* Public IP
* Security Group All traffic All port Anywhare

在每个实例上初始化配置。

sudo yum update -y
sudo yum install -y docker git
sudo usermod -a -G docker ec2-user
sudo service docker start

退出登录。

## 部署私有镜像仓库
登录node1

ssh -i lab.pem ec2-user@52.78.73.245

docker run -d --restart=always -p 5000:5000 registry


登录 node2和node3 做相同操作

sudo vi /etc/sysconfig/docker

OPTIONS="--default-ulimit nofile=1024:4096 --insecure-registry=172.31.7.232:5000"

sudo service docker restart

## 部署Rancher 服务器
登录node1

docker run -d --restart=always -p 8080:8080 rancher/server

用浏览器访问 http://node1-public-ip:8080

点击  Add Node

复制出 节点添加命令

sudo docker run -d --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.1.0 http://52.78.73.245:8080/v1/scripts/8EA22CC07281FB82FC42:1480604400000:6iVONa0crZwbsxVfReKjgHVJYs

生产API key 备用

点击 API -- Environment API Keys -- 输入名称和描述 -- 复制出页面上的秘钥

API Key Created

Access key: 0AE22ECB99C023380EEF

TF8SE9v6sFb55NViaFnGMFm6BLSzeEhiM1FiKJQd


## 添加节点到群集中

登录node2

ssh -i lab.pem ec2-user@52.79.80.60

sudo docker run -d --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.1.0 http://52.78.73.245:8080/v1/scripts/8EA22CC07281FB82FC42:1480604400000:6iVONa0crZwbsxVfReKjgHVJYs


进web页面， 点 Infrastructure -> hosts 应该可以看到 node2

登录node3

ssh -i lab.pem ec2-user@52.79.79.231

sudo docker run -d --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.1.0 http://52.78.73.245:8080/v1/scripts/8EA22CC07281FB82FC42:1480604400000:6iVONa0crZwbsxVfReKjgHVJYs



进web页面， 点 Infrastructure -> hosts 应该可以看到 node3

## 安装Jenkins

登录node3


wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war

启动 Jenkins

nohup java -jar jenkins.war > server.log 2>&1 &

tail -f server.log

在控制台中复制 密码串

打开浏览器  http://node3-public-ip:8080/

粘贴到页面中，点击安装建议的插件，输入首个管理员信息，登录。



## 修改源码文件

修改 sudo vi test-build/docker-compose.yml  修改 本地镜像库路径

pyapp:
  restart: always
  tty: true
  image: 172.31.7.232:5000/python-redis-demo:b$$BUILD_NUMBER$$
  links:
  - 'redis:'
  stdin_open: true


修改 sudo vi test-build/test-build.sh 修改成 node1 的rancher 服务器的访问地址，并加入上面所生产的秘钥。

./rancher-compose --url http://52.78.73.245:8080 --access-key 0AE22ECB99C023380EEF --secret-key TF8SE9v6sFb55NViaFnGMFm6BLSzeEhiM1FiKJQd -p python-redis-demo-build${BUILD_NUMBER} up -d


修改Jenkinfile

docker build -t 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER} .
docker push 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER}

如下所示

echo 'Build new docker image'
sh 'docker build -t 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER} .'
}
}

stage 'Push-Image'
node("master") {
echo 'Push new build to registory'
sh 'docker push 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER}'
sh 'docker rmi 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER}'
}

## 建立 CD 流水线

点击 new item --- Pipleline -- Pipeline -- Git  -- https://github.com/martinliu/cd-demo.git  -- Save

点击 Build Now
