yum install -y zip python3-pip python3 python3-setuptools openssl unzip docker
curl -qL -o jq https://stedolan.github.io/jq/download/linux64/jq && chmod +x ./jq
pip3 install docker-compose boto3

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
aws --version