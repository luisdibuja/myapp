pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -B clean package'
            }
        }

        stage('Deploy') {
            steps {
                deploy(
                    adapters: [
                        tomcat9(
                            credentialsId: 'tomcat-deploy',
                            url: 'http://localhost:8080'
                        )
                    ],
                    contextPath: '/Hello',
                    war: 'target/Hello.war'
                )
            }
        }
    }
}
