stage 'Build-Docker-Image'
node("master") {
   echo 'Check out code build image'
   git 'https://github.com/martinliu/cd-demo.git'
   dir('./src') {
    // build new images
    echo 'Build new docker image'
    sh 'docker build -t 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER} .'
}
}

stage 'Push-Image'
node("master") {
   echo 'Push new build to registory'
    sh 'docker push 172.31.7.232:5000/python-redis-demo:b${BUILD_NUMBER}'
}

stage 'Depooy-QA'
node("master") {
   echo 'Build a QA evn for new build'
   dir('./test-build') {
    // run build file
    sh 'sh ./test-build.sh'
}
}
