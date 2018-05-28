#!/bin/sh


yum install -y wget


echo 'add host yes/no?'
read host
if test $host = 'yes'
then
echo 'input master ip:'
read masterip
echo 'input node1 ip'
read node1ip
fi	


echo 'close firewall yes/no?'
read firewall
if test $firewall = 'yes'
then
	systemctl stop firewalld && systemctl disable firewalld
	setenforce 0
fi

echo 'swap off yes/no?'
read swap
if test $swap = 'yes'
then
	swapoff -a
	sed -i 's/.*swap.*/#&/' /etc/fstab
fi

echo 'add kubernetes repo yes/no?'
read k8s
if test $k8s = 'yes'
then
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
fi

echo 'add net.bridge yes/no?'
read bridge
if test $bridge = 'yes'
then
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
fi

echo 'install bzip2 yes/no?'
read bzip2
if test $bzip2 = 'yes'
then
	yum install -y bzip2
fi

echo 'install docker support yes/no?'
read docker
if test $docker = 'yes'
then
	yum -y localinstall docker-ce-*
	systemctl start docker && systemctl enable docker
	docker version
fi

echo 'load docker image yes/no?'
read dockerimage
if test $dockerimage = 'yes'
then
	cd docker_images
	for i in $(ls *.tar);do docker load < $i;done
	cd ..
fi

echo 'master load dashboard image yes/no?'
read dashboard
if test $dashboard = 'yes'
then
	docker load < kubernetes-dashboard_v1.8.1.tar
fi

echo 'install kube rpm yes/no?'
read kube
if test $kube = 'yes'
then
rpm -ivh socat-1.7.3.2-2.el7.x86_64.rpm
rpm -ivh kubernetes-cni-0.6.0-0.x86_64.rpm \
 kubelet-1.9.9-9.x86_64.rpm  \
kubectl-1.9.0-0.x86_64.rpm
rpm -ivh kubectl-1.9.0-0.x86_64.rpm
rpm -ivh kubeadm-1.9.0-0.x86_64.rpm
rpm -qa |grep kube
rpm -qa |grep socat
systemctl enable kubelet && systemctl start kubelet
sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
grep -i 'cgroupfs' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi


echo 'master install kubernetes master yes/no?'
read kubernetes
if test $kubernetes = 'yes'
then
	kubeadm init --kubernetes-version=v1.9.0 --pod-network-cidr=10.244.0.0/16
	mkdir -p $HOME/.kube
	cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	chown $(id -u):$(id -g) $HOME/.kube/config
	echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
	source  ~/.bash_profile
fi

echo 'master install flannel yes/no?'
read flannel
if test $flannel = 'yes'
then
wget https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
kubectl create -f kube-flannel.yml
fi


echo 'master install kube dashboard yes/no?'
read kubedashboard
if test $kubedashboard = 'yes'
then
	kubectl create -f kubernetes-dashboard.yaml
fi


echo 'add authfile yes/no?'
read authfile
if test $authfile = 'yes1'
then
	echo 'admin,admin,2' > /etc/kubernetes/pki/basic_auth_file
        grep 'auth' /etc/kubernetes/manifests/kube-apiserver.yaml
        kubectl apply -f /etc/kubernetes/manifests/kube-apiserver.yaml
kubectl create clusterrolebinding  \
login-on-dashboard-with-cluster-admin  \
--clusterrole=cluster-admin --user=admin
fi


