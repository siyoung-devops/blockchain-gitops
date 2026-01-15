pipeline {
  agent any
  stages {
    stage('Smoke') {
      steps {
        echo "BRANCH_NAME=${env.BRANCH_NAME}"
        sh 'pwd'
        sh 'ls -la'
      }
    }
  }
}