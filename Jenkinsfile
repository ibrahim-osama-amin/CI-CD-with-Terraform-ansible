#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
    [$class: 'GitSCMSource',
     remote: 'https://github.com/ibrahim-osama-amin/Jenkins-shared-library.git',
     credentialsId: 'github-credentials'
    ]
)

pipeline {
    agent any
    tools {
        maven 'Maven'
    }
    environment {
        IMAGE_NAME = 'ibrahimosama/my-repo:java-maven-Terraform'
        ANSIBLE_SERVER = "192.168.111.136"
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>' //reading the new version value from pom.xml 
                    def version = matcher[0][1] //access the first child element and the first file in it (parsing xml files)
                    env.IMAGE_NAME = "$version-$BUILD_NUMBER" //build number environment variable from jenkins
                } 
            }
        }

        stage('build app') {
            steps {
               script {
                  echo 'building application jar...'
                  sh 'mvn clean package' //to delete the old jar file before creating the new file
               }
            }
        }
        stage('build and push image') {
            steps {
                script {
                   echo 'building docker image...'
                   buildImage(env.IMAGE_NAME)
                   echo 'pushing docker image...'
                   dockerLogin()
                   dockerPush(env.IMAGE_NAME)
                }
            }
        }
        stage('provision server') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                TF_VAR_env_prefix = 'test'
            }
            steps {
                script {
                    echo 'Provisioning the server using Terraform'
                    dir('terraform') {
                        echo 'Cleaning previous Terraform state...'
                        sh 'rm -rf .terraform'
                        echo 'terraform inializing'
                        sh "terraform init -reconfigure" //had to do this becacuse I am not saving the state somewhere else
                        echo 'terraform init done, now applying ....'
                        sh "terraform apply --auto-approve"
                        EC2_PUBLIC_IP = sh(
                            script: "terraform output ec2_public_ip",
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }
    stage ("Deploy the container using Ansible"){
            steps {
                script {
                    echo "copying all neccessary files to ansible control node"
                    sshagent(['ansible-server']) {
                        sh "scp -o StrictHostKeyChecking=no ansible/* root@${ANSIBLE_SERVER}:/root/" //copy ansible files
                        withCredentials([sshUserPrivateKey(credentialsId: 'paris-eu-west-3', keyFileVariable: 'keyfile', usernameVariable: 'user')]) {
                            sh 'scp $keyfile root@$ANSIBLE_SERVER:/root/ssh-key.pem' //copy the AWS private key to ansible
                        }
                    }
                }
            }
        }
    
    stage("execute ansible playbook") {
            steps {
                script {
                    echo "calling ansible playbook to configure ec2 instances"
                    def remote = [:]
                    remote.name = "ansible-server"
                    remote.host = ANSIBLE_SERVER
                    remote.allowAnyHosts = true

                    withCredentials([sshUserPrivateKey(credentialsId: 'ansible-server', keyFileVariable: 'keyfile', usernameVariable: 'user')]){
                        remote.user = user
                        remote.identityFile = keyfile
                        sshCommand remote: remote, command: "ansible-playbook my-playbook.yaml"
                    }
                }
            }
    }


    stage('commit version update') {
            steps {
                script {
                    echo 'Committing version update to Github'
                    withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        // git config here for the first time run
                        sh 'git config --global user.email "iosama.amin@gmail.com"'
                        sh 'git config --global user.name "jenkins"'
                        sh "git remote set-url origin https://${PASS}@github.com/ibrahim-osama-amin/CI-CD-with-Terraform-ansible.git"
                        sh 'git add .'
                        sh 'git commit -m "CI: version bump"'
                        sh 'git push origin HEAD:main'
                    }
                }
            }
}
}
}

//This way to handle configuration and credentials is insecure and inficcient, I recommend you do it using configuration manager and secrets manager like Ansible 
