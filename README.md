# 持续部署演示

## 环境准备

### Python App

启动三个AMI实例， node1、node2、node3，实例配置如下：

* Amazon Linux AMI 2016.09.0 (HVM), SSD Volume Type
* Instance type: t2.micro
* Public IP
* Security Group All traffic All port Anywhare

在每个实例上初始化配置命令如下：

sudo yum update -y
sudo yum install -y docker git
sudo usermod -a -G docker ec2-user
sudo service docker start

## 部署和配置私有镜像仓库

登录node1，运行以下命令

docker run -d --restart=always -p 5000:5000 registry


登录node2和node3做如下相同操作

编辑docker配置文件
sudo vi /etc/sysconfig/docker

修改如下参数行
OPTIONS="--default-ulimit nofile=1024:4096 --insecure-registry=172.31.7.232:5000"

重启docker服务
sudo service docker restart

## 部署Rancher服务器

登录node1，运行下面命令
docker run -d --restart=always -p 8080:8080 rancher/server

用浏览器访问 http://node1-public-ip:8080 页面能够访问了之后。

点击  Add Host 按钮，在页面中复制出主机添加命令，复制出命令待用，命令如下所示。

sudo docker run -d --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.1.0 http://52.78.73.245:8080/v1/scripts/8EA22CC07281FB82FC42:1480604400000:6iVONa0crZwbsxVfReKjgHVJYs

生成环境API key对备用，点击 API -- 显示 Environment API Keys -- 输入key的名称和描述 -- 点击确定后，复制出页面上的秘钥。秘钥对内容如下所示：

API Key Created

Access key: 0AE22ECB99C023380EEF

Security key: TF8SE9v6sFb55NViaFnGMFm6BLSzeEhiM1FiKJQd

在页面中复制出Rancher服务器API访问URL网址，如下所示：

## 添加节点到Rancher群集中

登录node2和node3执行以下操作。

sudo docker run -d --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.1.0 http://52.78.73.245:8080/v1/scripts/8EA22CC07281FB82FC42:1480604400000:6iVONa0crZwbsxVfReKjgHVJYs


进Rancher web页面， 点 Infrastructure -> hosts 应该可以看到node2和node3



## 安装Jenkins服务器

登录node3，下载最新版Jenkins的运行包：

wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war

在命令行启动Jenkins到后台运行

nohup java -jar jenkins.war > server.log 2>&1 &

执行下面的命令，观察Jenkins服务器的启动过程，当控制台中复出现密码串后按ctl+c，在屏幕上复制出密码字符串备用。
tail -f server.log

打开浏览器初始化配置Jenkins服务器  http://node3-public-ip:8080/

把密码字符串粘贴到页面中，点击安装建议插件，输入首个管理员信息，用刚才输入的用户名和密码登录Jenkins服务器

在Jenkins服务器的环境变量中添加如下环境变量。

RancherApiURL http://52.78.73.245:8080/
Akey  0AE22ECB99C023380EEF
Skey  TF8SE9v6sFb55NViaFnGMFm6BLSzeEhiM1FiKJQd
RegURL 172.31.7.232:5000


## 修改pyapp源码文件

修改 pyapp/test-build/docker-compose.yml ，把应用镜像名称改为本地镜像库ip地址路径（node1的内网ip）路径，如下 image： 这一行所示，其它代码保持不变。

pyapp:
  restart: always
  tty: true
  image: $$RegURL$$/python-redis-demo:b$$BUILD_NUMBER$$
  links:
  - 'redis:'
  stdin_open: true


修改 pyapp/test-build/test-build.sh 在rancher-compose命令后加入上面的步骤中所产生的 Rancher服务器api网址，和环境API秘钥对，如下所示：

./rancher-compose --url ${RancherApiURL} --access-key ${Akey} --secret-key ${Skey} -p python-redis-demo-build${BUILD_NUMBER} up -d


## 修改pyapp的流水线文件Jenkinfile.pyapp

替换下面两行的镜像

docker build -t $$RegURL$$/python-redis-demo:b${BUILD_NUMBER} .
docker push $$RegURL$$/python-redis-demo:b${BUILD_NUMBER}

如下所示

echo 'Build new docker image'
sh 'docker build -t ${RegURL}/python-redis-demo:b${BUILD_NUMBER} .'
}
}

stage 'Push-Image'
node("master") {
echo 'Push new build to registory'
sh 'docker push ${RegURL}/python-redis-demo:b${BUILD_NUMBER}'
sh 'docker rmi ${RegURL}/python-redis-demo:b${BUILD_NUMBER}'
}

## 建立 CD 流水线

点击 new item --- 选择 Pipleline -- 点击 Git  -- 输入 https://github.com/martinliu/cd-demo.git  -- 输入 Jenkins.pyapp -- 点击 Save。

点击这个流水线，点击 Build Now ，查看构建日志。
