
# Hashview

This is the Puppet module for the Hashview web interface for Hashcat.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with hashview](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with hashview](#beginning-with-hashview)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)

## Description

Hashview is a web interface that works with the hashcat CLI tool. It brings some cool features likes multiple users, queueing of jobs, wordlist managment and more.

This puppet module sets up (almost) everything you need. *(except a nginx and a firewall)*

## Setup

### Setup Requirements

If you're going to run hashcat on a CPU or GPU, you will still need to make sure that the chip supports OpenCL 1.2 or above.

## Usage

To install the class you will have to use it in another module, like so:

`modules/setup-cracking-machine/manifests/init.pp`:
```
class { 'hashview':
   port => 1337,
   hostname => '127.0.0.1',
   hashview_install_path => '/opt/hashview/',
   db_password => 'hunter2',
}

...setup nginx and firewall
```

## Limitations

The web interface limits your hashcat functionality to what has been implemented in Hashview, if you miss a feature you could always contribute to the project.

## License

The project is licensed under an MIT license.
