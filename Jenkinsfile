pipeline {
    agent any 
    stages {
        stage('Docker Build') {
            steps {
                echo 'building docker'
                sh 'commit_id=$(git rev-parse HEAD)'
		sh 'docker build -t 187632318301.dkr.ecr.us-east-1.amazonaws.com/ayush-ecr:${commit_id} .'
            }
        }
        stage('pushing image to ECR') {
            steps {
                echo 'pushinfg image'
                sh 'commit_id=$(git rev-parse HEAD)'
		sh '	docker push 187632318301.dkr.ecr.us-east-1.amazonaws.com/ayush-ecr:${commit_id}'
            }
        }
        stage('Deploying on eks') {
            steps {
                echo 'deploying on eks'
		sh 'kubectl create -f deployment.yml'
		sh 'sleep 10'
		sh 'kubectl get pods'
		sh 'kubectl create -f loadbalancer.yml'
		sh 'kubectl get pods'
		sh 'kubectl get service/react-lb |  awk {'print $1" " $2 " " $4 " " $5'} | column -t'
            }
        }
    }
}
