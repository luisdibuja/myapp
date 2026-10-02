pipeline {
    agent any

    environment {
        K8S_HOST = '172.29.107.235'
    }

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

        stage('Docker Build') {
            steps {
                script {
                    env.DOCKER_IMAGE = 'luisdibuja/myapp:' + sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()
                }
                sh 'docker build --tag "$DOCKER_IMAGE" .'
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-myapp',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set +x
                        set -eu
                        DOCKER_CONFIG=$(mktemp -d)
                        export DOCKER_CONFIG
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT
                        trap 'exit 1' HUP INT TERM

                        printf '%s' "$DOCKERHUB_TOKEN" |
                            docker login --username "$DOCKERHUB_USER" --password-stdin
                        docker push "$DOCKER_IMAGE"
                    '''
                }
            }
        }

        stage('Kubernetes Deploy') {
            steps {
                timeout(time: 4, unit: 'MINUTES') {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'k8s-myapp-ssh',
                        keyFileVariable: 'K8S_KEY',
                        usernameVariable: 'K8S_USER'
                    )]) {
                        sh '''
                            set +x
                            set -eu
                            imageTag=${DOCKER_IMAGE##*:}
                            ssh -o BatchMode=yes \\
                                -o IdentitiesOnly=yes \\
                                -o StrictHostKeyChecking=yes \\
                                -o UserKnownHostsFile=ci/known_hosts \\
                                -o HostKeyAlgorithms=ssh-ed25519 \\
                                -o ConnectTimeout=10 \\
                                -o ServerAliveInterval=10 \\
                                -o ServerAliveCountMax=3 \\
                                -i "$K8S_KEY" \\
                                "$K8S_USER@$K8S_HOST" "deploy $imageTag"
                        '''
                    }
                }
            }
        }

        stage('Smoke Test') {
            steps {
                retry(5) {
                    sleep time: 2, unit: 'SECONDS'
                    sh '''
                        set -eu
                        smokeStatus=$(curl --silent --show-error --connect-timeout 2 --max-time 5 --output target/smoke-response.txt --write-out '%{http_code}' "http://$K8S_HOST:8080/Hello/hello")
                        test "$smokeStatus" = "200"
                        test "$(cat target/smoke-response.txt)" = "Hello World from Tomcat!"
                        echo "Smoke test passed: HTTP 200 and expected message."
                    '''
                }
            }
        }
    }
}
