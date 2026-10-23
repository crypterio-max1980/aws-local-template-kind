<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/938478c6-1dfd-4687-b4b5-4d2d33205d91" />


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


