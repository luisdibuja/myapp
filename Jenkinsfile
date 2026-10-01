pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }
	triggers {
    githubPush() 
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
	        stage('Smoke Test') {
            steps {
                retry(5) {
                    sleep time: 2, unit: 'SECONDS'
                    sh '''
                        set -eu
                        smokeStatus=$(curl --silent --show-error --connect-timeout 2 --max-time 5 --output target/smoke-response.txt --write-out '%{http_code}' http://127.0.0.1:8080/Hello/hello)
                        test "$smokeStatus" = "200"
                        test "$(cat target/smoke-response.txt)" = "Hello World from Tomcat!"
                        echo "Smoke test passed: HTTP 200 and expected message."
                    '''
                }
            }
        }
    }
}
