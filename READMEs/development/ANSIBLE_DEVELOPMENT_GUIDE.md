# Ansible Development Best Practices Guide

## Development Philosophy

### Think in Layers
1. **Infrastructure Layer**: System preparation, packages, configuration
2. **Platform Layer**: K3s installation, networking, storage
3. **Application Layer**: Application-specific configurations
4. **Security Layer**: RBAC, secrets, certificates

### Ansible Best Practices Mindset

#### 1. Idempotency First
Every task should be safe to run multiple times without side effects.

```yaml
# BAD: Not idempotent
- name: Install package
  shell: apt install -y docker.io

# GOOD: Idempotent
- name: Install Docker
  apt:
    name: docker.io
    state: present
    update_cache: yes
```

#### 2. Fail Fast and Clear
Make failures obvious and actionable.

```yaml
# BAD: Silent failure
- name: Download file
  get_url:
    url: "{{ download_url }}"
    dest: /tmp/file
  ignore_errors: yes

# GOOD: Clear failure handling
- name: Download installation file
  get_url:
    url: "{{ download_url }}"
    dest: /tmp/file
    timeout: 30
  register: download_result
  retries: 3
  delay: 5
  until: download_result is succeeded
```

#### 3. Use Variables Effectively
Create a clear variable hierarchy and naming convention.

```yaml
# group_vars/all.yml - Global defaults
k3s_version: "v1.28.5+k3s1"
k3s_install_dir: "/usr/local/bin"

# group_vars/k3s_servers.yml - Role-specific
k3s_server_args: "--disable=traefik --disable=servicelb"

# host_vars/lab-k8s-1.yml - Host-specific
k3s_node_ip: "192.168.50.15"
```

## Directory Structure Best Practices

### Recommended Layout
```
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory.ini              # Static inventory
├── site.yml                   # Main playbook
├── group_vars/
│   ├── all.yml               # Global variables
│   ├── k3s.yml               # K3s cluster variables
│   ├── k3s_servers.yml       # Server-specific variables
│   └── k3s_agents.yml        # Agent-specific variables
├── host_vars/
│   ├── lab-k8s-1.yml         # Host-specific variables
│   └── lab-k8s-2.yml
├── roles/                     # Custom roles
│   ├── system-prep/
│   ├── k3s-server/
│   └── k3s-agent/
├── playbooks/                 # Organized playbooks
│   ├── 00-system-prep.yml
│   ├── 01-install-k3s.yml
│   └── 02-configure-apps.yml
├── templates/                 # Jinja2 templates
├── files/                     # Static files
└── vault/                     # Encrypted secrets
    └── secrets.yml
```

## Variable Management Strategy

### 1. Variable Hierarchy (Lowest to Highest Priority)
```
1. group_vars/all.yml          (lowest priority)
2. group_vars/group_name.yml
3. host_vars/hostname.yml
4. playbook vars
5. command line vars           (highest priority)
```

### 2. Naming Conventions
```yaml
# Prefix variables by component/role
k3s_version: "v1.28.5+k3s1"
k3s_token: "my-secret-token"
k3s_server_args: "--disable=traefik"

# Use descriptive names
node_memory_gb: 4
cluster_domain: "cluster.local"
external_dns_provider: "cloudflare"

# Boolean variables should be clear
enable_monitoring: true
skip_system_update: false
```

### 3. Environment-Specific Variables
```yaml
# group_vars/all.yml
environments:
  dev:
    k3s_version: "v1.28.5+k3s1"
    resource_limits: false
  prod:
    k3s_version: "v1.27.8+k3s2"  # Stable version
    resource_limits: true

current_env: "{{ env | default('dev') }}"
k3s_config: "{{ environments[current_env] }}"
```

## Task Development Patterns

### 1. System Preparation Tasks
```yaml
- name: System preparation block
  block:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install required packages
      apt:
        name: "{{ required_packages }}"
        state: present
      vars:
        required_packages:
          - curl
          - wget
          - git
          - nfs-common

    - name: Configure system settings
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
      loop:
        - { name: "net.ipv4.ip_forward", value: "1" }
        - { name: "net.bridge.bridge-nf-call-iptables", value: "1" }

  rescue:
    - name: System preparation failed
      fail:
        msg: "System preparation failed. Check package repositories and network connectivity."
```

### 2. Service Installation Pattern
```yaml
- name: Install and configure K3s
  block:
    - name: Check if K3s is already installed
      stat:
        path: "{{ k3s_install_dir }}/k3s"
      register: k3s_binary

    - name: Download K3s installer
      get_url:
        url: https://get.k3s.io
        dest: /tmp/k3s-install.sh
        mode: '0755'
        timeout: 30
      when: not k3s_binary.stat.exists

    - name: Install K3s server
      shell: |
        INSTALL_K3S_VERSION={{ k3s_version }} \
        K3S_TOKEN={{ k3s_token }} \
        /tmp/k3s-install.sh server {{ k3s_server_args }}
      environment:
        K3S_KUBECONFIG_MODE: "{{ k3s_kubeconfig_mode }}"
      when: not k3s_binary.stat.exists
      register: k3s_install

    - name: Wait for K3s API server
      uri:
        url: "https://{{ ansible_host }}:6443/readyz"
        validate_certs: no
        timeout: 5
      register: api_check
      retries: 30
      delay: 10
      until: api_check.status == 200

  rescue:
    - name: K3s installation failed
      debug:
        msg: "K3s installation failed. Check logs with: journalctl -u k3s"
      
    - name: Show K3s service status
      shell: systemctl status k3s
      register: k3s_status
      ignore_errors: yes
      
    - name: Display service status
      debug:
        var: k3s_status.stdout_lines
        
    - name: Fail the play
      fail:
        msg: "K3s installation failed. See debug output above."
```

### 3. Configuration Management Pattern
```yaml
- name: Configure application
  block:
    - name: Create configuration directory
      file:
        path: "{{ app_config_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0755'

    - name: Template configuration file
      template:
        src: "{{ app_name }}.conf.j2"
        dest: "{{ app_config_dir }}/{{ app_name }}.conf"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0644'
        backup: yes
      notify: restart {{ app_name }}

    - name: Validate configuration
      shell: "{{ app_binary }} --test-config {{ app_config_dir }}/{{ app_name }}.conf"
      register: config_test
      changed_when: false

  rescue:
    - name: Configuration validation failed
      fail:
        msg: "Configuration validation failed: {{ config_test.stderr }}"
```

## Error Handling and Debugging

### 1. Comprehensive Error Handling
```yaml
- name: Complex operation with error handling
  block:
    - name: Attempt primary operation
      shell: "{{ primary_command }}"
      register: primary_result

  rescue:
    - name: Log the error
      debug:
        msg: "Primary operation failed: {{ primary_result.stderr | default('Unknown error') }}"

    - name: Attempt fallback operation
      shell: "{{ fallback_command }}"
      register: fallback_result

    - name: Fail if both operations failed
      fail:
        msg: "Both primary and fallback operations failed"
      when: fallback_result is failed

  always:
    - name: Cleanup temporary files
      file:
        path: "{{ temp_file }}"
        state: absent
      ignore_errors: yes
```

### 2. Debugging Helpers
```yaml
# Add debug tasks for troubleshooting
- name: Debug - Show system information
  debug:
    msg:
      - "Hostname: {{ ansible_hostname }}"
      - "IP Address: {{ ansible_default_ipv4.address }}"
      - "Memory: {{ ansible_memtotal_mb }}MB"
      - "CPU Cores: {{ ansible_processor_vcpus }}"
  when: debug_mode | default(false)

- name: Debug - Show variable values
  debug:
    var: k3s_config
  when: debug_mode | default(false)
```

### 3. Validation Tasks
```yaml
- name: Validate cluster state
  block:
    - name: Check all nodes are ready
      shell: kubectl get nodes --no-headers | grep -v Ready | wc -l
      register: unready_nodes
      changed_when: false

    - name: Fail if nodes are not ready
      fail:
        msg: "{{ unready_nodes.stdout }} nodes are not ready"
      when: unready_nodes.stdout | int > 0

    - name: Check critical pods
      shell: kubectl get pods -n kube-system --no-headers | grep -v Running | wc -l
      register: failed_pods
      changed_when: false

    - name: Fail if critical pods are failing
      fail:
        msg: "{{ failed_pods.stdout }} critical pods are not running"
      when: failed_pods.stdout | int > 0
```

## Security Best Practices

### 1. Secret Management
```yaml
# Use Ansible Vault for sensitive data
# ansible-vault create group_vars/all/vault.yml

# In vault.yml:
vault_k3s_token: "super-secret-token"
vault_cloudflare_api_token: "cloudflare-api-token"

# In regular variables:
k3s_token: "{{ vault_k3s_token }}"
cloudflare_api_token: "{{ vault_cloudflare_api_token }}"
```

### 2. File Permissions
```yaml
- name: Create secure configuration
  template:
    src: secret-config.j2
    dest: /etc/app/secret.conf
    owner: root
    group: app
    mode: '0640'  # Owner read/write, group read, no world access
  no_log: true    # Don't log sensitive content
```

### 3. User Management
```yaml
- name: Create service user
  user:
    name: "{{ app_user }}"
    system: yes
    shell: /bin/false
    home: "{{ app_home }}"
    create_home: no
```

## Testing and Validation

### 1. Molecule Testing (Advanced)
```yaml
# molecule/default/molecule.yml
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: ubuntu:20.04
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
```

### 2. Simple Validation Playbook
```yaml
# playbooks/validate.yml
---
- name: Validate cluster deployment
  hosts: k3s_servers[0]
  tasks:
    - name: Check K3s service status
      systemd:
        name: k3s
      register: k3s_service

    - name: Validate service is running
      assert:
        that:
          - k3s_service.status.ActiveState == "active"
        fail_msg: "K3s service is not active"

    - name: Check cluster nodes
      shell: kubectl get nodes --no-headers | wc -l
      register: node_count
      changed_when: false

    - name: Validate node count
      assert:
        that:
          - node_count.stdout | int == groups['k3s'] | length
        fail_msg: "Expected {{ groups['k3s'] | length }} nodes, found {{ node_count.stdout }}"
```

## Performance Optimization

### 1. Ansible Configuration
```ini
# ansible.cfg
[defaults]
gathering = smart
fact_caching = memory
host_key_checking = False
retry_files_enabled = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### 2. Task Optimization
```yaml
# Use loops efficiently
- name: Install multiple packages
  apt:
    name: "{{ packages }}"
    state: present
  vars:
    packages:
      - package1
      - package2
      - package3

# Instead of multiple tasks:
# - name: Install package1
#   apt: name=package1 state=present
# - name: Install package2
#   apt: name=package2 state=present
```

### 3. Parallel Execution
```yaml
# Use serial for controlled rollouts
- name: Rolling update
  hosts: k3s_servers
  serial: 1  # Update one server at a time
  tasks:
    - name: Update server
      # tasks here

# Use async for long-running tasks
- name: Long running task
  shell: /path/to/long/script.sh
  async: 300  # 5 minutes timeout
  poll: 10    # Check every 10 seconds
```

## Development Workflow

### 1. Development Cycle
```bash
# 1. Make changes to playbooks
vim playbooks/01-install-k3s.yml

# 2. Test syntax
ansible-playbook --syntax-check site.yml

# 3. Test on single host
ansible-playbook -l lab-k8s-1 site.yml --check

# 4. Run on single host
ansible-playbook -l lab-k8s-1 site.yml

# 5. Run on all hosts
ansible-playbook site.yml

# 6. Validate results
ansible-playbook playbooks/validate.yml
```

### 2. Debugging Workflow
```bash
# Increase verbosity
ansible-playbook site.yml -vvv

# Run specific tags
ansible-playbook site.yml --tags "k3s-install"

# Skip specific tags
ansible-playbook site.yml --skip-tags "system-update"

# Run in check mode (dry run)
ansible-playbook site.yml --check

# Step through tasks
ansible-playbook site.yml --step
```

This guide provides a solid foundation for developing maintainable, reliable Ansible playbooks for your infrastructure. Focus on idempotency, clear error handling, and proper variable management to create robust automation.
