pipeline {
    agent any
    options {
        // Aggressive build rotation: Keep ONLY last 2 builds given disk space constraints
        buildDiscarder(logRotator(numToKeepStr: '2', artifactNumToKeepStr: '2'))
        timeout(time: 1, unit: 'HOURS')
    }
    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        booleanParam(name: 'runSonar', defaultValue: false, description: 'Run SonarQube code analysis?')
        choice(name: 'TARGET_ENV', choices: ['sbx', 'qa', 'stg', 'prod'], description: 'Select the target environment for deployment')
    }
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        IMAGE_REPO = "pasindu12345/food-ordering-application-server"
        IMAGE_NAME = "${IMAGE_REPO}:latest"
        IMAGE_VERSION_TAG = "${IMAGE_REPO}:v0.0.${BUILD_NUMBER}"
        S3_BUCKET = "food-delivery-terraform-state-pasindu"
        AWS_BIN = "${WORKSPACE}/aws-bin/aws"
    }

    stages {
        stage('Determine Environment') {
            steps {
                script {
                    // Logic: Map Git Branch to Environment
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        env.DEPLOY_ENV = 'prod'
                    } else if (env.BRANCH_NAME == 'qa') {
                        env.DEPLOY_ENV = 'qa'
                    } else if (env.BRANCH_NAME == 'staging') {
                        env.DEPLOY_ENV = 'stg'
                    } else {
                        // For webhook triggers on other branches, or if manually triggered with a selection
                        env.DEPLOY_ENV = params.TARGET_ENV ?: 'sbx'
                    }
                    echo "Target Environment determined as: ${env.DEPLOY_ENV}"
                }
            }
        }

        stage('Quick Clean & Prep') {
            steps {
                script {
                    echo "--- Disk usage before cleanup ---"
                    sh 'df -h'
                    sh 'docker system prune -af || true'
                    
                    // Ensure AWS CLI is installed
                    sh 'chmod +x aws-install-script.sh && ./aws-install-script.sh'
                    
                    echo "--- Disk usage after cleanup ---"
                    sh 'df -h'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh "terraform plan -out tfplan"
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                }
            }
        }

        stage('Approval') {
            when {
                not { equals expected: true, actual: params.autoApprove }
            }
            steps {
                script {
                    def plan = readFile 'terraform/tfplan.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh "terraform apply -input=false tfplan"
                }
            }
        }

        stage('Get Server IPs & Ansible Config') {
            steps {
                script {
                    dir('terraform') {
                        def buildIp = sh(script: 'terraform output -raw build_server_ip', returnStdout: true).trim()
                        def deployIp = sh(script: 'terraform output -raw deploy_server_ip', returnStdout: true).trim()
                        
                        echo "Build Server IP: ${buildIp}"
                        echo "Deploy Server IP: ${deployIp}"

                        // Store connection strings in S3 for later stages
                        writeFile file: 'build_server_conn.txt', text: "ubuntu@${buildIp}"
                        writeFile file: 'deploy_server_conn.txt', text: "ubuntu@${deployIp}"
                        sh "${AWS_BIN} s3 cp build_server_conn.txt s3://${S3_BUCKET}/food-ordering-server/build_server_conn.txt"
                        sh "${AWS_BIN} s3 cp deploy_server_conn.txt s3://${S3_BUCKET}/food-ordering-server/deploy_server_conn.txt"

                        // Dynamically create Ansible Inventory for the determined environment
                        def inventoryContent = """
[${env.DEPLOY_ENV}]
${deployIp} ansible_user=ubuntu
"""
                        writeFile file: '../ansible/inventory.ini', text: inventoryContent
                    }
                    
                    // Run Ansible Management Playbook limited to the determined environment
                    echo "Configuring Environment: ${env.DEPLOY_ENV}"
                    sshagent(['Jenkins-slave']) {
                        sh "ansible-playbook -i ansible/inventory.ini ansible/server-management.yml --limit ${env.DEPLOY_ENV} --ssh-extra-args='-o StrictHostKeyChecking=no'"
                    }
                }
            }
        }

        stage('Run Sonarqube') {
            when { expression { params.runSonar == true } }
            steps {
                script {
                    withSonarQubeEnv(installationName: 'SonarScanner') {
                        sh './mvnw sonar:sonar -Dsonar.projectKey=food-ordering-app'
                    }
                }
            }
        }

        stage('Remote Build & Push') {
            steps {
                script {
                    // Download the connection string from S3
                    sh "${AWS_BIN} s3 cp s3://${S3_BUCKET}/food-ordering-server/build_server_conn.txt build_server_conn.txt"
                    def buildServer = readFile('build_server_conn.txt').trim()
                    
                    sshagent(['Jenkins-slave']) {
                        withCredentials([usernamePassword(credentialsId: '12345678', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                            echo "Transferring code to Build Server: ${buildServer}"
                            sh "rsync -avz -e 'ssh -o StrictHostKeyChecking=no' --exclude '.git' --exclude 'terraform' ./ ${buildServer}:/home/ubuntu/app/"
                            
                            echo "Building Docker image on remote Build Server..."
                            sh """
                                ssh -o StrictHostKeyChecking=no ${buildServer} '
                                    cd app && \
                                    chmod +x docker-script.sh && \
                                    ./docker-script.sh && \
                                    sudo docker build -t ${IMAGE_NAME} -t ${IMAGE_VERSION_TAG} . && \
                                    sudo docker login -u $USERNAME -p $PASSWORD && \
                                    sudo docker push ${IMAGE_NAME} && \
                                    sudo docker push ${IMAGE_VERSION_TAG} && \
                                    sudo docker system prune -af
                                '
                            """
                        }
                    }
                }
            }
        }

        stage('Remote Deploy') {
            steps {
                script {
                    // Download the connection string from S3
                    sh "${AWS_BIN} s3 cp s3://${S3_BUCKET}/food-ordering-server/deploy_server_conn.txt deploy_server_conn.txt"
                    def deployServer = readFile('deploy_server_conn.txt').trim()

                    sshagent(['Jenkins-slave']) {
                        withCredentials([usernamePassword(credentialsId: '12345678', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                            echo "Deploying to Deploy Server: ${deployServer}"
                            sh "scp -o StrictHostKeyChecking=no docker-compose.yml docker-script.sh docker-compose-script.sh ${deployServer}:/home/ubuntu/"
                            
                            sh """
                                ssh -o StrictHostKeyChecking=no ${deployServer} '
                                    chmod +x docker-script.sh docker-compose-script.sh && \
                                    ./docker-script.sh && \
                                    sudo docker login -u $USERNAME -p $PASSWORD && \
                                    ./docker-compose-script.sh ${IMAGE_NAME}
                                '
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    echo "--- Post-build aggressive cleanup ---"
                    sh 'rm -rf target/ || true'
                    sh 'docker system prune -af || true'
                    sh 'rm -rf /var/lib/jenkins/.sonar/cache/* || true'
                    sh 'df -h'
                    deleteDir()
                } catch (Exception e) {
                    echo "Cleanup failed: ${e.getMessage()}"
                }
            }
        }
    }
}