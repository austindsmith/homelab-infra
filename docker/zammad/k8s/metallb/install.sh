kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

kubectl create -f k8s/metallb/ipaddresses.yaml

kubectl create -f k8s/metallb/layer2.yaml

kubectl create -f k8s/metallb/configmap.yaml


#Little test of nginx to make sure everything is working so far

kubectl create deploy nginx --image nginx:latest 

kubectl get all

kubectl expose deploy nginx --port 80 --type LoadBalancer

# See what port has been exposed
kubectl get svc