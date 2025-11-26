# NixOS Development Setup for Homelab Infrastructure

## Overview
Complete NixOS configuration to work on your homelab infrastructure from your laptop, including all tools for Terraform, Ansible, Kubernetes, and data lakehouse development.

## Quick Setup (Copy-Paste Ready)

### 1. Essential Development Environment

Create your development configuration:

```nix
# /etc/nixos/configuration.nix or ~/.config/nixpkgs/home.nix
{ config, pkgs, ... }:

{
  # Enable flakes (modern Nix)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Development packages
  environment.systemPackages = with pkgs; [
    # Core development tools
    git
    vim
    neovim
    curl
    wget
    jq
    yq
    tree
    htop
    btop
    
    # Infrastructure as Code
    terraform
    terraform-ls
    tflint
    tfsec
    ansible
    ansible-lint
    
    # Kubernetes tools
    kubectl
    kubectx
    kubens
    k9s
    helm
    argocd
    kustomize
    
    # Container tools
    docker-compose
    dive  # Docker image explorer
    
    # Cloud tools
    awscli2
    
    # Data tools
    duckdb
    sqlite
    
    # Network tools
    nmap
    netcat
    dig
    
    # File management
    rsync
    rclone
    
    # Development environments
    python3
    python3Packages.pip
    python3Packages.virtualenv
    nodejs
    yarn
    
    # Text processing
    ripgrep
    fd
    bat
    fzf
    
    # Monitoring
    prometheus
    grafana
    
    # SSH and security
    openssh
    gnupg
    age
    sops
    
    # Syncthing for file sync
    syncthing
  ];
  
  # Enable Docker (if you want local containers)
  virtualisation.docker.enable = true;
  
  # Add your user to docker group
  users.users.yourusername.extraGroups = [ "docker" ];
  
  # Enable SSH
  services.openssh.enable = true;
  
  # Enable Syncthing
  services.syncthing = {
    enable = true;
    user = "yourusername";
    dataDir = "/home/yourusername/Sync";
  };
}
```

### 2. Apply the Configuration

```bash
# If using system-wide configuration
sudo nixos-rebuild switch

# If using home-manager (recommended for development)
# First install home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# Then create ~/.config/nixpkgs/home.nix with the packages above
home-manager switch
```

## Detailed Development Setup

### 3. Home Manager Configuration (Recommended)

Create `~/.config/nixpkgs/home.nix`:

```nix
{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
  
  # Home Manager needs a bit of information about you and the
  # paths it should manage
  home.username = "yourusername";
  home.homeDirectory = "/home/yourusername";
  
  # Packages to install
  home.packages = with pkgs; [
    # Infrastructure tools
    terraform
    terraform-ls
    tflint
    tfsec
    ansible
    ansible-lint
    
    # Kubernetes ecosystem
    kubectl
    kubectx
    kubens
    k9s
    helm
    argocd
    kustomize
    stern  # Multi-pod log tailing
    
    # Development tools
    git
    neovim
    tmux
    zsh
    oh-my-zsh
    
    # File tools
    ripgrep
    fd
    bat
    fzf
    tree
    
    # Network tools
    curl
    wget
    jq
    yq
    
    # Python ecosystem
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.jupyter
    python3Packages.pandas
    python3Packages.numpy
    
    # Node.js ecosystem
    nodejs
    yarn
    
    # Container tools
    docker-compose
    dive
    
    # Cloud tools
    awscli2
    
    # Monitoring
    prometheus
    grafana
    
    # Data tools
    duckdb
    sqlite
    
    # Security tools
    gnupg
    age
    sops
  ];
  
  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@domain.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
  
  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      k = "kubectl";
      tf = "terraform";
      ans = "ansible";
      ap = "ansible-playbook";
    };
    
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "kubectl" "terraform" "ansible" ];
      theme = "robbyrussell";
    };
  };
  
  # Tmux configuration
  programs.tmux = {
    enable = true;
    shortcut = "a";
    keyMode = "vi";
    extraConfig = ''
      set -g mouse on
      set -g default-terminal "screen-256color"
    '';
  };
  
  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-terraform
      vim-ansible
      vim-kubernetes
      fzf-vim
      nerdtree
      vim-airline
    ];
    
    extraConfig = ''
      set number
      set relativenumber
      set tabstop=2
      set shiftwidth=2
      set expandtab
      syntax on
    '';
  };
  
  # This value determines the Home Manager release that your
  # configuration is compatible with
  home.stateVersion = "23.11";
}
```

### 4. SSH Configuration

Create `~/.ssh/config`:

```bash
# Homelab servers
Host lab-k8s-*
    User root
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host proxmox
    HostName proxmox.theblacklodge.org
    User root
    Port 22

# Quick access to your servers
Host k8s-1
    HostName 192.168.50.15
    User root

Host k8s-2
    HostName 192.168.50.16
    User root

Host k8s-3
    HostName 192.168.50.17
    User root

Host k8s-4
    HostName 192.168.50.18
    User root

Host k8s-5
    HostName 192.168.50.19
    User root
```

### 5. Generate SSH Keys

```bash
# Generate SSH key for homelab access
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Copy to your servers (after they're running)
for i in {15..19}; do
    ssh-copy-id root@192.168.50.$i
done
```

## Development Environment Setup

### 6. Kubernetes Configuration

```bash
# Create kubeconfig directory
mkdir -p ~/.kube

# Copy kubeconfig from your cluster (after it's running)
scp root@192.168.50.15:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Update server IP in kubeconfig
sed -i 's/127.0.0.1/192.168.50.15/g' ~/.kube/config

# Test connection
kubectl get nodes
```

### 7. Terraform Setup

```bash
# Navigate to your synced project
cd ~/Sync/homelab/infra  # or wherever syncthing syncs to

# Initialize Terraform
cd terraform
terraform init

# Validate configuration
terraform validate
terraform plan
```

### 8. Ansible Setup

```bash
# Test Ansible connectivity
cd ~/Sync/homelab/infra/ansible
ansible all -m ping

# Run playbooks
ansible-playbook site.yml
```

### 9. Python Development Environment

```bash
# Create virtual environment for data projects
python -m venv ~/venvs/datalake
source ~/venvs/datalake/bin/activate

# Install data science packages
pip install \
    jupyter \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    plotly \
    scikit-learn \
    mlflow \
    dremio-client \
    boto3 \
    pyarrow \
    duckdb
```

## NAS Integration

### 10. Mount NAS Storage

```nix
# Add to your NixOS configuration
fileSystems."/mnt/nas" = {
  device = "//your-nas-ip/share";
  fsType = "cifs";
  options = [ 
    "username=your-username"
    "password=your-password"
    "uid=1000"
    "gid=100"
    "iocharset=utf8"
  ];
};
```

Or mount manually:
```bash
# Create mount point
sudo mkdir -p /mnt/nas

# Mount NAS
sudo mount -t cifs //your-nas-ip/share /mnt/nas \
    -o username=your-username,password=your-password,uid=1000,gid=100

# Add to fstab for permanent mounting
echo "//your-nas-ip/share /mnt/nas cifs username=your-username,password=your-password,uid=1000,gid=100 0 0" | sudo tee -a /etc/fstab
```

### 11. Syncthing Configuration

```bash
# Start Syncthing
systemctl --user start syncthing

# Access web UI
firefox http://localhost:8384

# Add your homelab folder for syncing
# Point it to ~/Sync/homelab or similar
```

## Development Workflow

### 12. Daily Development Commands

```bash
# Start development session
tmux new-session -d -s homelab

# Navigate to project
cd ~/Sync/homelab/infra

# Check cluster status
kubectl get nodes
kubectl get pods -A

# Work on Terraform
cd terraform
terraform plan

# Work on Ansible
cd ../ansible
ansible-playbook --check site.yml

# Work on Kubernetes manifests
cd ../k8s
helm lint */

# Monitor cluster
k9s
```

### 13. Useful Aliases and Functions

Add to your `~/.zshrc` or shell config:

```bash
# Homelab aliases
alias hl='cd ~/Sync/homelab/infra'
alias k='kubectl'
alias tf='terraform'
alias ans='ansible'
alias ap='ansible-playbook'

# Quick cluster status
alias cluster-status='kubectl get nodes && kubectl get pods -A | grep -v Running'

# Quick deployment
alias deploy-all='cd ~/Sync/homelab/infra && ansible-playbook ansible/site.yml'

# Port forwarding shortcuts
alias pf-argo='kubectl port-forward svc/argocd-server -n argocd 8080:443'
alias pf-grafana='kubectl port-forward svc/grafana -n monitoring 3000:80'

# Functions for common tasks
klog() {
    kubectl logs -f deployment/$1 -n ${2:-default}
}

kdesc() {
    kubectl describe pod $1 -n ${2:-default}
}

kexec() {
    kubectl exec -it $1 -n ${2:-default} -- /bin/bash
}
```

## Data Lakehouse Development

### 14. Jupyter Setup for Data Work

```bash
# Start Jupyter for data lakehouse development
cd ~/Sync/homelab/infra
source ~/venvs/datalake/bin/activate
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser

# Or use the cluster JupyterHub
kubectl port-forward svc/jupyterhub -n datalake 8000:80
```

### 15. Connect to Data Services

```python
# Example Jupyter notebook cell for connecting to your data stack
import pandas as pd
import boto3
from sqlalchemy import create_engine

# MinIO connection
s3 = boto3.client(
    's3',
    endpoint_url='http://minio.theblacklodge.dev',
    aws_access_key_id='admin',
    aws_secret_access_key='minio123'
)

# Dremio connection (via port-forward)
# kubectl port-forward svc/dremio-coordinator -n datalake 9047:9047
engine = create_engine('dremio://admin:admin123@localhost:9047/dremio')

# Query data
df = pd.read_sql("SELECT * FROM nessie.datalake.iot_sensors LIMIT 100", engine)
```

## Troubleshooting

### 16. Common Issues and Solutions

```bash
# If packages aren't found
nix-channel --update
home-manager switch

# If kubectl can't connect
kubectl config view
kubectl config current-context

# If SSH keys don't work
ssh-add ~/.ssh/id_ed25519
ssh-agent

# If Syncthing isn't syncing
systemctl --user status syncthing
journalctl --user -u syncthing

# If NAS mount fails
sudo mount -a
dmesg | tail
```

### 17. Performance Optimization

```nix
# Add to your NixOS configuration for better performance
nix.settings = {
  max-jobs = "auto";
  cores = 0;  # Use all cores
  
  # Optimizations
  auto-optimise-store = true;
  
  # Substituters for faster downloads
  substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
  ];
};
```

## Quick Start Script

### 18. Automated Setup

```bash
#!/usr/bin/env bash
# setup-nixos-dev.sh

set -e

echo "🚀 Setting up NixOS development environment..."

# Install home-manager if not present
if ! command -v home-manager &> /dev/null; then
    echo "Installing home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
fi

# Create directories
mkdir -p ~/.config/nixpkgs
mkdir -p ~/.ssh
mkdir -p ~/Sync
mkdir -p ~/venvs

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

# Apply home-manager configuration
echo "Applying home-manager configuration..."
home-manager switch

# Create Python virtual environment
echo "Creating Python virtual environment..."
python -m venv ~/venvs/datalake
source ~/venvs/datalake/bin/activate
pip install --upgrade pip
pip install jupyter pandas numpy matplotlib seaborn plotly scikit-learn mlflow boto3 pyarrow duckdb

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure Syncthing: http://localhost:8384"
echo "2. Copy kubeconfig from your cluster"
echo "3. Test connectivity: kubectl get nodes"
echo "4. Start developing: cd ~/Sync/homelab/infra"
```

This comprehensive setup gives you everything you need to work on your homelab infrastructure from your couch on NixOS. The configuration is declarative and reproducible, so you can easily recreate this environment on any NixOS machine.

Run the setup script, configure Syncthing to sync your homelab folder, and you'll be ready to work on both your Kubernetes infrastructure and the exciting 5-day data lakehouse project! 🚀
