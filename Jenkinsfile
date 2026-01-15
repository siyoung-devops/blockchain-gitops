pipeline {
  agent any
  stages {
    stage('Build') {
      when {
        branch 'dev'
      }
      steps {
        echo 'Running on dev branch'
      }
    }
  }
}
