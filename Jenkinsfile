pipeline {
    agent any

    stages {
        stage('Smoke') {
            steps {
                echo "Branch: ${env.BRANCH_NAME}"
                sh 'echo Jenkins Multibranch Pipeline OK'
            }
        }
    }
}
