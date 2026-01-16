pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Run test.sh') {
      steps {
        sh 'chmod +x test.sh'
        sh './test.sh'
      }
    }
  }
}
