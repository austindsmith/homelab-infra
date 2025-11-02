# Homelab Infrastructure
- Terraform
- Ansible

It is recommended to use a virtual environment with this stack to keep Python packages clean. Use requirements.txt for the installation of the relevant Python packages.

The Ansible scripts are pushing things to /var/lib... right now. This isn't best practice, and was instead just used to demo out some ideas. A todo will be to have ArgoCD manage everything. Another todo will be to test destroying the entire cluster and rebuilding from scratch.