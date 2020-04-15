terraform apply
aws eks --region us-east-1 update-kubeconfig --name cluster
sleep 5
kubectl apply -f deployment.yml
sleep 5
kubectl apply -f loadbalancer.yml
sleep 5
kubectl get pods
sleep 5
kubectl get svc
