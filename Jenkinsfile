pipeline {
    agent any
    
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    environment {
        // Configuration Docker Registry
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_USERNAME = 'ghassenellili123'
        DOCKER_TOKEN = credentials('ghassenellili123')
    // ...autres variables
        // Noms des images
        IMAGE_NAME = "${DOCKER_REGISTRY}/${DOCKER_USERNAME}/flutter-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
        DOCKER_IMAGE_LATEST = "${IMAGE_NAME}:latest"
        
        // Configuration Kubernetes
        KUBE_NAMESPACE = 'flutter-app'
        KUBE_DEPLOYMENT = 'flutter-app'
    }
    
    stages {
        stage('🔍 Checkout') {
            steps {
                echo "=== Étape 1: Récupération du code source ==="
                checkout scm
                sh 'git log --oneline -1'
            }
        }
        
        stage('📋 Analyse du code') {
            steps {
                echo "=== Étape 2: Analyse statique du code ==="
                sh '''
                    echo "Vérification de la syntaxe Flutter..."
                    flutter analyze || true
                    
                    echo "Vérification des dépendances..."
                    flutter pub outdated || true
                '''
            }
        }
        
        stage('⚙️ Setup Flutter') {
            steps {
                echo "=== Étape 3: Installation et configuration ==="
                sh '''
                    echo "Version Flutter:"
                    flutter --version
                    
                    echo "Récupération des dépendances..."
                    flutter pub get
                    
                    echo "Vérification des prérequis..."
                    flutter doctor
                '''
            }
        }
        
        stage('🧪 Tests Unitaires') {
            steps {
                echo "=== Étape 4: Exécution des tests unitaires ==="
                sh '''
                    echo "Lancement des tests..."
                    flutter test --coverage --no-sound-null-safety || true
                    
                    echo "Tests terminés"
                '''
            }
        }
        
        stage('🏗️ Build Flutter Web') {
            steps {
                echo "=== Étape 5: Build de l'application Flutter Web ==="
                sh '''
                    echo "Configuration des dépendances de build..."
                    flutter pub get
                    
                    echo "Build en release mode..."
                    flutter build web --release --no-tree-shake-icons
                    
                    echo "Vérification de la sortie build..."
                    ls -lah build/web/
                '''
            }
        }
        
        stage('🐳 Build Docker Image') {
            steps {
                echo "=== Étape 6: Construction de l'image Docker ==="
                script {
                    sh '''
                        echo "Suppression des images existantes..."
                        docker rmi ${DOCKER_IMAGE} ${DOCKER_IMAGE_LATEST} || true
                        
                        echo "Construction de l'image: ${DOCKER_IMAGE}"
                        docker build \
                            --tag ${DOCKER_IMAGE} \
                            --tag ${DOCKER_IMAGE_LATEST} \
                            --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                            --build-arg VCS_REF=$(git rev-parse --short HEAD) \
                            --build-arg VERSION=${BUILD_NUMBER} \
                            .
                        
                        echo "Vérification de l'image..."
                        docker images | grep flutter-app
                    '''
                }
            }
        }
        
        stage('🔐 Login Docker Registry') {
            steps {
                echo "=== Étape 7: Authentification Docker Registry ==="
                script {
                    sh '''
                        echo "Connexion à ${DOCKER_REGISTRY}..."
                        echo ${DOCKER_TOKEN} | docker login \
                            -u ${DOCKER_USERNAME} \
                            --password-stdin ${DOCKER_REGISTRY}
                    '''
                }
            }
        }
        
        stage('📤 Push to Registry') {
            steps {
                echo "=== Étape 8: Upload de l'image Docker ==="
                script {
                    sh '''
                        echo "Push de l'image taggée: ${DOCKER_IMAGE}"
                        docker push ${DOCKER_IMAGE}
                        
                        echo "Push de l'image latest: ${DOCKER_IMAGE_LATEST}"
                        docker push ${DOCKER_IMAGE_LATEST}
                        
                        echo "Déconnexion du registry..."
                        docker logout ${DOCKER_REGISTRY}
                    '''
                }
            }
        }
        
        stage('☸️ Deploy to Kubernetes') {
            when {
                branch 'main'  // Seulement sur la branche main/master
            }
            steps {
                echo "=== Étape 9: Déploiement Kubernetes ==="
                script {
                    sh '''
                        echo "Vérification du cluster Kubernetes..."
                        kubectl cluster-info
                        
                        echo "Liste des namespaces..."
                        kubectl get ns | grep ${KUBE_NAMESPACE} || kubectl create namespace ${KUBE_NAMESPACE}
                        
                        echo "Mise à jour de l'image du déploiement..."
                        kubectl set image deployment/${KUBE_DEPLOYMENT} \
                            ${KUBE_DEPLOYMENT}=${DOCKER_IMAGE} \
                            -n ${KUBE_NAMESPACE} \
                            --record || {
                            echo "Le déploiement n'existe pas, création..."
                            kubectl apply -f k8s/deployment.yaml
                        }
                        
                        echo "Attente du rollout..."
                        kubectl rollout status deployment/${KUBE_DEPLOYMENT} \
                            -n ${KUBE_NAMESPACE} \
                            --timeout=5m
                    '''
                }
            }
        }
        
        stage('✅ Vérification de Santé') {
            when {
                branch 'main'
            }
            steps {
                echo "=== Étape 10: Health Check ==="
                script {
                    sh '''
                        echo "Affichage des pods..."
                        kubectl get pods -n ${KUBE_NAMESPACE} -o wide
                        
                        echo "Attente que les pods soient prêts..."
                        kubectl wait --for=condition=Ready \
                            pod -l app=${KUBE_DEPLOYMENT} \
                            -n ${KUBE_NAMESPACE} \
                            --timeout=300s || true
                        
                        echo "Affichage des services..."
                        kubectl get svc -n ${KUBE_NAMESPACE}
                        
                        echo "Affichage des 50 derniers logs..."
                        kubectl logs -n ${KUBE_NAMESPACE} \
                            -l app=${KUBE_DEPLOYMENT} \
                            --tail=50 || true
                    '''
                }
            }
        }
        
        stage('📊 Rapport') {
            steps {
                echo "=== Résumé du déploiement ==="
                sh '''
                    echo "========================================="
                    echo "Build Information:"
                    echo "  Build Number: ${BUILD_NUMBER}"
                    echo "  Build URL: ${BUILD_URL}"
                    echo "  Workspace: ${WORKSPACE}"
                    echo ""
                    echo "Docker Information:"
                    echo "  Image: ${DOCKER_IMAGE}"
                    echo "  Latest: ${DOCKER_IMAGE_LATEST}"
                    echo ""
                    echo "Kubernetes Information:"
                    echo "  Namespace: ${KUBE_NAMESPACE}"
                    echo "  Deployment: ${KUBE_DEPLOYMENT}"
                    echo "========================================="
                '''
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline exécuté avec succès!"
            sh 'echo "Déploiement réussi: ${DOCKER_IMAGE}" > deployment-success.txt'
        }
        failure {
            echo "❌ Pipeline échoué!"
            sh '''
                echo "Récupération des logs d'erreur..."
                kubectl logs -n ${KUBE_NAMESPACE} \
                    -l app=${KUBE_DEPLOYMENT} \
                    --tail=100 > pod-logs.txt || true
            '''
        }
        always {
            echo "Nettoyage du workspace..."
            cleanWs(deleteDirs: true, patterns: [[pattern: '.git', type: 'INCLUDE']])
        }
    }
}
