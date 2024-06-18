# Local Development Environment Setup with Vagrant, VirtualBox, and Ansible

This repository contains a Vagrant setup for creating a local development environment using VirtualBox as the provider and Ansible for provisioning.

## Prerequisites

Before you begin, ensure you have the following installed on your machine:

- [Vagrant](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)

## Getting Started

To set up the development environment, follow these steps:

git clone https://gitlab.com/pcmt/pcmt-akeneov6.git

    cd pcmt-akeneov6/deploy/vagrant


Open terminal on on this folder and run

    ansible-galaxy install geerlingguy.pip geerlingguy.docker 
    
    vagrant up

    vagrant ssh
