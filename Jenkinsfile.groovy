pipeline {
  agent {
    label "dockerhub-maven"
  }
  environment {
    CHART_REPOSITORY= 'https://artifactory.cluster.foxsports-gitops-prod.com.au/artifactory/helm' // Please do not edit this line! Managed by customize.sh
    ORG = 'fsa-streamotion' 
    APP_NAME = 'gitops-toolkit'
    DOCKER_REGISTRY='kayosportsau'
  }
  stages {

    stage('Push To DockerHub') {
      steps {
        container('maven') {
              // ensure we're not on a detached head
              sh "git config --global credential.helper store"
              sh "jx step git credentials"

              sh "echo \$(jx-release-version) > VERSION"
              sh "jx step tag --version \$(cat VERSION)"

              sh "export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml"

              script {
                def buildVersion =  readFile "${env.WORKSPACE}/VERSION"
                currentBuild.description = "$buildVersion"
                currentBuild.displayName = "$buildVersion"
              }          
        }
      }
    }
  }
  post {
        always {
          cleanWs()
        }
  }
}
