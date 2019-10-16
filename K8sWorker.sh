#Set Path
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#Disable SELinux & setup firewall rules
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10250/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8080/tcp
systemctl restart firewalld
systemctl reload firewalld

#Run the command below to enable the br_netfilter kernel module.

modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

#Disable SWAP for kubernetes installation by running the following commands.
swapoff -a
#add comment to a file
#And then edit the '/etc/fstab' file.
#Comment the swap line UUID as below.

#Install the latest version of Docker-ce from the docker repository.
#Install the package dependencies for docker-ce.
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce docker-ce-cli containerd.io
systemctl enable docker.service
systemctl start docker

#curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl
#chmod +x ./kubectl
#sudo mv ./kubectl /usr/local/bin/kubectl
#kubectl version

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

#yum install -y kubectl
#yum install -y --disableexcludes=kubernetes kubelet kubeadm kubectl
yum install -y --disableexcludes=kubernetes kubelet-1.15.3 kubectl-1.15.3 kubeadm-1.15.3

setenforce 0


#start the service kubelet kubeadm kubectl

systemctl enable kubelet && systemctl start kubelet
 #export role='Master'

if [ $role == "Master" ]; then
    #On master node
    kubeadm init --pod-network-cidr=10.244.0.0/16

    #Update your own user .kube config so that you can use kubectl from your own user in the future
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    sudo cp /etc/kubernetes/admin.conf $HOME/
    sudo chown $(id -u):$(id -g) $HOME/admin.conf
    export KUBECONFIG=$HOME/admin.conf    


    #Setup Flannel virtual network:

    sudo sysctl net.bridge.bridge-nf-call-iptables=1
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml


    #Setup the Nodes
    #Run the following for networking to be correctly setup on each node:
    sudo sysctl net.bridge.bridge-nf-call-iptables=1

    #We need join token to connect each node to master. We can retrieved it from by running following command on master node.

    joinnode=$(sudo kubeadm token create --print-join-command)
    sudo cp /etc/kubernetes/admin.conf $HOME/
	sudo chown $(id -u):$(id -g) $HOME/admin.conf
	export KUBECONFIG=$HOME/admin.conf
    kubectl get nodes
    export kubever=$(kubectl version | base64 | tr -d '\n')
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
	export joinnode
    echo $joinnode
	else
    echo $njoinnode
    $njoinnode
	echo "else statemanet working"
	fi
