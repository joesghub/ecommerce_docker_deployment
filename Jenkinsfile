pipeline {
  agent any

  environment {
    DOCKER_CREDS = credentials('docker-hub-credentials')
  }

  stages {
    stage ('Build') {
      agent any
      steps {
        sh '''#!/bin/bash
        <code to build the application>
        '''
      }
    }

    stage ('Test') {
      agent any
      steps {
        sh '''#!/bin/bash
        <code to activate virtual environment>
        pip install pytest-django
        python backend/manage.py makemigrations
        python backend/manage.py migrate
        pytest backend/account/tests.py --verbose --junit-xml test-reports/results.xml
        ''' 
      }
    }

    stage('Cleanup') {
      agent { label 'build-node' }
      steps {
        sh '''
          # Only clean Docker system
          docker system prune -f
          
          # Safer git clean that preserves terraform state
          git clean -ffdx -e "*.tfstate*" -e ".terraform/*"
        '''
      }
    }

    stage('Build & Push Images') {
      agent { label 'build-node' }
      steps {
        sh 'echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin'
        
        // Build and push backend
        sh '''
          docker build -t joedhub/backend:latest -f Dockerfile.backend .
          docker push joedhub/backend:latest
        '''
        
        // Build and push frontend
        sh '''
          docker build -t joedhub/frontend:latest -f Dockerfile.frontend .
          docker push joedhub/frontend:latest
        '''
      }
    }

    stage('Infrastructure') {
      agent { label 'build-node' }
      steps {
        dir('Terraform') {
          sh '''
            terraform init
            terraform apply -auto-approve \
              -var="dockerhub_username=${DOCKER_CREDS_USR}" \
              -var="dockerhub_password=${DOCKER_CREDS_PSW}" \
              -var="aws_access_key=${AWS_ACCESS_KEY}" \
              -var="aws_secret_key=${AWS_SECRET_KEY}"
          '''
        }
      }
    }
  }

  post {
    always {
      agent { label 'build-node' }
      steps {
        sh '''
          docker logout
          docker system prune -f
        '''
      }
    }
  }
}
