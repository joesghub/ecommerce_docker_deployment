#!/bin/bash

####        BACKEND SERVER          #####
kura_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSkMc19m28614Rb3sGEXQUN+hk4xGiufU9NYbVXWGVrF1bq6dEnAD/VtwM6kDc8DnmYD7GJQVvXlDzvlWxdpBaJEzKziJ+PPzNVMPgPhd01cBWPv82+/Wu6MNKWZmi74TpgV3kktvfBecMl+jpSUMnwApdA8Tgy8eB0qELElFBu6cRz+f6Bo06GURXP6eAUbxjteaq3Jy8mV25AMnIrNziSyQ7JOUJ/CEvvOYkLFMWCF6eas8bCQ5SpF6wHoYo/iavMP4ChZaXF754OJ5jEIwhuMetBFXfnHmwkrEIInaF3APIBBCQWL5RC4sJA36yljZCGtzOi5Y2jq81GbnBXN3Dsjvo5h9ZblG4uWfEzA2Uyn0OQNDcrecH3liIpowtGAoq8NUQf89gGwuOvRzzILkeXQ8DKHtWBee5Oi/z7j9DGfv7hTjDBQkh28LbSu9RdtPRwcCweHwTLp4X3CYLwqsxrIP8tlGmrVoZZDhMfyy/bGslZp5Bod2wnOMlvGktkHs="
echo "$kura_key"  >> /home/ubuntu/.ssh/authorized_keys

#1. Clone the repository from GitHub
cd /home/ubuntu/
git clone https://github.com/joesghub/ecommerce_terraform_deployment.git

#2. Change directory into the cloned repository
cd /home/ubuntu/ecommerce_terraform_deployment/backend/

# The Deadsnakes PPA is a popular repository for installing newer or multiple versions of Python on Debian-based distributions like Ubuntu. 
# This repository is maintained by the community and typically includes various Python versions that aren’t available in the official Ubuntu repositories.
# When to Use the Deadsnakes PPA
# The Deadsnakes PPA is commonly used when:
# You need a version of Python not available in your OS’s official repositories.
# You want to install multiple versions of Python side by side for testing or development.
# After adding this PPA, update your package lists

#3. Add Python PPA for Python 3.9 and install Python
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update -y 

####In the "Backend" EC2 (Django) clone your source code repository and install "python3.9", "python3.9-venv", and "python3.9-dev"

#python3.9: Installs Python 3.9.
#python3.9-venv: Provides the venv module for creating virtual environments with Python 3.9.
#python3-dev: Installs development libraries and header files needed for building Python modules, useful if you need to install certain packages that require compilation.
#python3-pip: pip is a package management system for Python. It allows you to install and manage additional libraries and dependencies that are not included in the Python standard library. 
#Essentially, it’s the default tool for installing Python packages from the Python Package Index (PyPI).
#Using pip, you can install, upgrade, and uninstall Python packages in different environments (e.g., global Python environment or virtual environments).

#4. Install Python 3.9, Python 3.9 venv, pip, dev
sudo apt install -y python3.9 python3.9-venv python3-dev python3-pip

#5. Create and activate a python virtual environment with
#python3.9 -m venv venv uses Python 3.9's venv module to create a virtual environment in a directory named venv
#Your shell will use the Python and pip inside the venv folder instead of the system-wide versions.
python3.9 -m venv venv && source venv/bin/activate

#6. Change directory into the location of the Backend requirements.txt file in the repository
#Use real path to generate the absolute file path
cd /home/ubuntu/ecommerce_terraform_deployment/backend/
# "ubuntu@---~/ecommerce_terraform_deployment/backend$" realpath requirements.txt 

#7. Install the dependencies from the "requirements.txt" file
#-r: Tells pip to install all packages listed in the specified requirements file
pip install -r /home/ubuntu/ecommerce_terraform_deployment/backend/requirements.txt

#8. Modify "settings.py" in the "my_project" directory and update "ALLOWED_HOSTS" to include the private IP of the backend EC2.
#nano /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py

cd /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/
PRIVATE_IP=$(hostname -I | awk '{print $1}')
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['$PRIVATE_IP'\]/" settings.py && cat settings.py

####         Issue 2: Modifying script to pull private IP associated with virtual machine. In bash it is a simple code: private_ip=$(hostname -I)
# In python it requires a module socket to pull the machine host name then look up the host name's IPs


#9. Navigate to the folder containig the manage.py file and start the Django server by running:

# Start Django Server
mkdir /home/ubuntu/logs && touch /home/ubuntu/logs/backend.log
cd /home/ubuntu/ecommerce_terraform_deployment/backend/
python manage.py runserver 0.0.0.0:8000 > /home/ubuntu/logs/backend.log 2>&1 &


# The manage.py file is a crucial component of any Django project, providing a command-line interface for performing various administrative tasks. 
# It ensures that the correct Django settings are used and facilitates interaction with the Django framework through command-line commands. 
# This structure allows for efficient management and development of Django applications.

