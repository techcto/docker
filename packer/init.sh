


apt install -y unzip
wget https://releases.hashicorp.com/packer/1.11.0/packer_1.11.0_linux_amd64.zip
unzip packer_1.11.0_linux_amd64.zip
chmod +x packer
mv packer /usr/bin/packer
packer version

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

packer -v