def label = "mypod-${UUID.randomUUID().toString()}"
podTemplate(label: label, containers: [
    containerTemplate(name: 'terraform', image: 'hashicorp/terraform:light', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.8.8', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:latest', command: 'cat', ttyEnabled: true)
  ],
volumes: [
  hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
]) {

    node(label) {
        def myRepo = checkout scm
    def gitCommit = myRepo.GIT_COMMIT
    def gitBranch = myRepo.GIT_BRANCH
    def shortGitCommit = "${gitCommit[0..10]}"
    def previousGitCommit = sh(script: "git rev-parse ${gitCommit}~", returnStdout: true)
        
        stage('Get the project') {
            checkout scm
            container('terraform') {

                stage('Terrafor init and apply') {
                    sh 'cd infra/platform/k8s-eks && terraform init && terraform apply --auto-approve'
                }
                
                stage('Test') {
                    sh '''
                      echo "$(npm bin)/ng test --progress=false --watch false"
                      echo "test me"
                    '''
                  //junit "test-results.xml"
                }
                          
                stage 'Package and Code Analysis'
                    withSonarQubeEnv {
                        sh '$(npm bin)/ng lint'
                        sh 'sonar-scanner  -Dsonar.projectKey=angular-conduit-ui -Dsonar.sources=.' 
                    }
            }

    stage('Prepare k8s for Pipeline') {
      container('kubectl') {
          sh """
            rm -rf node_modules
            docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}
            docker build -t paruff/realworld:${gitCommit} .
            docker push paruff/realworld:${gitCommit}
            """
      }
    }

        stage('helm  pipeline services') {
      container('helm') {
          sh """
            rm -rf node_modules
            docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}
            docker build -t paruff/realworld:${gitCommit} .
            docker push paruff/realworld:${gitCommit}
            """
        
      }
    }

    }
}
