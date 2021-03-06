pipeline {
        agent {
            kubernetes {
                label 'jenkins-slave'
                defaultContainer 'jnlp'
                yaml """
apiVersion: v1
kind: Pod
spec:
    containers:
    - name: jnlp
      image: openshift/jenkins-agent-nodejs-8-centos7:v3.11
      tty: true
    - name: tools
      image: 172.30.1.1:5000/cicd/openshift-build-tools:latest
      command:
      - cat
      tty: true
        """
             }
        }

    environment {
        APPLICATION_NAME = 'hello-react'
        GIT_BRANCH="master"
        DEV_PROJECT = "dev"
        TEST_PROJECT = "test"
        STAGE_PROJECT = "stage"
        ARTIFACT_FOLDER = "target"
        ARGOCD_SERVER = "argocd-server-argocd.192.168.64.7.nip.io"
        DOCKER_REGISTRY = "172.30.1.1:5000"
        DOCKER_NAMESPACE = "dev"
    }

    stages {
        stage('Get Latest Code') {
            steps {
                sh "env"
                git branch: "${GIT_BRANCH}", url: "${GIT_URL}", credentialsId: "cicd-bitbucket"
            }
        }

        stage('Create web app'){
            steps {
                dir("app") {
                    sh "npm ci"
                    sh "npm run build"
                }
            }
        }

        stage('Store web app') {
             steps {
                script {
                    def safeBuildName  = "${APPLICATION_NAME}_${BUILD_NUMBER}",
                        artifactFolder = "${ARTIFACT_FOLDER}",
                        fullFileName   = "${safeBuildName}.tar.gz",
                        applicationZip = "${artifactFolder}/${fullFileName}"
                        applicationDir = ["app/build",
                                            "container/nginx.conf",
                                            "Dockerfile",
                                            ].join(" ");
                    def needTargetPath = !fileExists("${artifactFolder}")
                    if (needTargetPath) {
                        sh "mkdir ${artifactFolder}"
                    }

                    sh "tar -czvf ${applicationZip} ${applicationDir}"
                    archiveArtifacts artifacts: "${applicationZip}", excludes: null, onlyIfSuccessful: true
                }
            }
        }


        stage('Create Image Builder') {
            when {
                expression {
                    openshift.withCluster() {
                        openshift.withProject(DEV_PROJECT) {
                            return !openshift.selector("bc", "${APPLICATION_NAME}").exists();
                        }
                    }
                }
            }
            
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject(DEV_PROJECT) {
                            openshift.newBuild("--name=${APPLICATION_NAME}", "--docker-image=docker.io/nginx:mainline-alpine", "--binary=true")
                            }
                        }
                    }
                }
            }

        stage('Build Image') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject(env.DEV_PROJECT) {
                            openshift.selector("bc", "$APPLICATION_NAME").startBuild("--from-archive=${ARTIFACT_FOLDER}/${APPLICATION_NAME}_${BUILD_NUMBER}.tar.gz", "--wait=true")
                        }
                    }
                }
            }
        }

        stage('Tag Image') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject(env.DEV_PROJECT) {
                        openshift.tag("${APPLICATION_NAME}:latest", "${APPLICATION_NAME}:${env.GIT_COMMIT}") 
                        }
                    }
                }
            }
        }

        stage('Deploy to dev') {
            steps {
                container('tools') {
                    deployImageArgoCd("${env.APPLICATION_NAME}-dev", "${APPLICATION_NAME}:${env.GIT_COMMIT}")
                }
            }
        }
    
        stage('Deploy to test') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject(env.DEV_PROJECT) {
                            openshift.tag("${APPLICATION_NAME}:${env.GIT_COMMIT}", "${APPLICATION_NAME}:latest-test") 
                        }
                    }
                }
                container('tools') {
                    deployImageArgoCd("${env.APPLICATION_NAME}-test", "${APPLICATION_NAME}:${env.GIT_COMMIT}")            
                }
            }
        }

        stage('Promote to STAGE?') {
            steps {
                timeout(time:15, unit:'MINUTES') {
                    input message: "Promote to STAGE?", ok: "Promote"
                }
                script {
                    openshift.withCluster() {
                        openshift.withProject(env.DEV_PROJECT) {
                            openshift.tag("${APPLICATION_NAME}:${env.GIT_COMMIT}", "${APPLICATION_NAME}:latest-stage")
                        }
                    }
                }
            }
        }

        stage('Deploy to stage') {
                steps {
                    container('tools') {
                        deployImageArgoCd("${env.APPLICATION_NAME}-stage", "${env.DOCKER_REGISTRY}/${env.DOCKER_NAMESPACE}/${APPLICATION_NAME}:${env.GIT_COMMIT}")
                    }
                }
        }
    }
}

void deployImageArgoCd(deployId, imageTag) {
    withCredentials([string(credentialsId: "argocd-deploy", variable: 'ARGOCD_AUTH_TOKEN')]) {
        sh "argocd --grpc-web app set "+ deployId + " --insecure --kustomize-image " + imageTag
        sh "argocd --grpc-web app sync "+ deployId + " --force --insecure"
        sh "argocd --grpc-web app wait "+ deployId + " --timeout 60 --insecure"
    }
}
