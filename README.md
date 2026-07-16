# Install Fedora <!-- omit in toc -->

## Table of content <!-- omit in toc -->

* [1. Introduction](#1-introduction)
* [2. PC specifcations](#2-pc-specifcations)
* [3. Project structure](#3-project-structure)
* [4. Files to create](#4-files-to-create)
* [5. Author](#5-author)

## 1. Introduction

Install Fedora is a set of scripts and files to automate the installation of a Fedora workstation through a kickstart and a post-installation script.

***DISCLAIMER:*** This is the way I install my workstation, therefore the app selection and the way it is installed may not suit you. Feel free to adapt the project to your will.

## 2. PC specifcations

The project is used on my laptop. Here are its specifications:

* CPU: Intel® Core™ i7-10750H × 12
* GPU: NVIDIA GeForce GTX 1650 / Intel® UHD Graphics (CML GT2)
* RAM: 32,0 Gio
* ROM:
  * System: Samsung SSD 970 EVO Plus 250GB
  * Data: Seagate BarraCuda HDD 7200 RPM 1TB

## 3. Project structure

```text
install-fedora/
|
+-- configure/               => Configuration script template to allow the user to automate their account configuration
+-- files/                   => Files used throughout the post installation process
|
+-- .gitignore               => Files ignored from Git
+-- fedora.dist.cfg          => Fedora workstation kickstart
+-- LICENCE                  => MIT licence
+-- postinstall-fedora.sh    => Post installation script to prepare a user account after first login
+-- README.md                => Project introduction
```

## 4. Files to create

The project is not working as is. In order to use it, you must copy, fill and adapt the following files:

* fedora.dist.cfg => fedora.cfg

Make sure to replace the following strings in `fedora.cfg`:

* ENCRYPTED_MAIN_USER_PASSWORD
* ENCRYPTED_ROOT_PASSWORD
* HOSTNAME
* MAIN_USER_DISPLAY_NAME
* MAIN_USER_LOGIN

## 5. Author

* Lilian POULIQUEN: [Github – @lilian-pouliquen](https://github.com/lilian-pouliquen)
