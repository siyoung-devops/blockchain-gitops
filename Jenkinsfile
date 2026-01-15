pipeline {
    agent any

    stages {
        stage('Smoke') {
            steps {
                echo "Branch: ${env.dev}"
                sh 'echo Jenkins Multibranch Pipeline OK'
            }
        }
    }
}
