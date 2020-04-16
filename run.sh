terraform apply -var="enable_route53=0"
aws eks --region us-east-1 update-kubeconfig --name cluster
sleep 5
kubectl delete -f deployment.yml
kubectl apply -f deployment.yml
sleep 5
kubectl delete -f loadbalancer.yml
kubectl apply -f loadbalancer.yml
sleep 5
kubectl get pods
kubectl get svc
lb_dns=$( kubectl get svc |  awk 'NR == 3 {print $4}' )
echo $lb_dns |  cut -d "-" -f "1"
lb_name=$( echo $lb_dns |  cut -d "-" -f "1" )
terraform import aws_elb.bar $lb_name
protocol=$( kubectl get svc | awk 'NR == 3 {print $5}' | cut -d ":" -f "2" | cut -d "/" -f "1")
echo "protocol " $protocol
terraform apply -var="protocol=$protocol" -var="enable_route53=1"
echo "FINISH "

