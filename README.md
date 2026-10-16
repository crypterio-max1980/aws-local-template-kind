<img width="1048" height="581" alt="image" src="https://github.com/user-attachments/assets/fe4aef9b-afcf-493e-bb16-fe036e70d330" />

## AWS | Local-Template
A reference blueprint for end-to-end automation of infrastructure and AI application deployment using GitLab, Terraform, AWS, Kubernetes (kind), and an LLM-based RAG stack.
Designed primarily for local development, rapid prototyping, and demo environments, this model ensures fast iteration, reproducibility, and a seamless developer experience. 🐳🤖


⭐  Architecture
```
✔️ Source Control (GitLab)
✔️ Infrastructure Orchestration Layer (Terraform Core)
✔️ Cloud Execution Layer → (AWS EC2)
✔️ Kubernetes Orchestration Layer (kind Cluster)
✔️ AI/ML Runtime Layer (LLM + Vector DB Stack) 
```

🚀 
```
terraform init
terraform validate
terraform plan -var-file="template.tfvars"
terraform apply -var-file="template.tfvars" -auto-approve
```

🧩 Config 
```
scp -i ~/.ssh/<your pem file> <your pem file> ec2-user@<terraform instance public ip>:/home/ec2-user
chmod 400 <your pem file>
```


