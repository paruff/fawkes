pipeline {
  agent any

  stages {
     stage('checkout project') {
            steps {
              checkout scm
            }
    } 
  
    stage('runTests') {
        steps {
            sh 'sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose'
            sh 'sudo chmod a+x /usr/local/bin/docker-compose'
            sh 'sudo chmod a+x /var/lib/jenkins/workspace/verfut-test/qa/wait-for-it.sh'
            sh 'cd qa && /usr/local/bin/docker-compose up --abort-on-container-exit --exit-code-from seleniumtests'
        }
    }
   }
}
