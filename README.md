
CANGALLO (https://canga.io)

Cangallo (pronounced canga-io) is a command-line tool written in ruby, that uses `qemu-img` and `libguestfs` to manage, create and organize qcow2 images. Its repository holds images and deltas of derived images in a similar way as Docker but in a block level instead of file level.
It should work nicely on any `Linux` flavor but, we recommend `Ubuntu` or `CentOS`.

**WARNING**: Beware, still in early stages, expect crashes, data loss and incompatible changes. Working on the OSX port with no ETA: (unmet dependencies like `libguestfs` and `mkisofs`)

## Requirements before using cangallo
Before using cangallo, you will need to have some tools up and running:

* Ruby >= 1.9.3
* qemu-img >= 2.4.0
* libguestfs >= 1.28 (copy command needs at least 1.30)
* keybase, for index sign and verify functionality

## Ruby dependencies
After installing ruby you'll need to install a couple of packages by typing:

```
$ gem install bundle
$ bundle install
```

## Package dependencies

You can find instructions for different Linux distros at [Installation](/install).

## How to install

Just type:
```
$ gem install cangallo
```
Then type
```
$ canga
```
The output should be:
```
$ canga
Commands:
  canga --version, -V        # show version
  canga add FILE [REPO]      # add a new file to the repository
  canga build CANGAFILE      # create a new image using a Cangafile
  canga create FILE [SIZE]   # create a new qcow2 image
  canga del IMAGE            # delete an image from the repository
  canga deltag TAGNAME       # delete a tag
  canga export IMAGE OUTPUT  # export an image to a file
  canga fetch [REPO]         # download the index of the repository
  canga help [COMMAND]       # Describe available commands or one specific command
  canga import IMAGE [REPO]  # import an image from a remote repository
  canga list [REPO]          # list images
  canga overlay IMAGE FILE   # create a new image based on another one
  canga pull NAME            # download an image from a remote repository
  canga show IMAGE           # show information about an image
  canga sign [REPO]          # sign the index file with keybase
  canga tag TAGNAME IMAGE    # add a tag name to an existing image
  canga verify [REPO]        # verify index signature with keybase
```

## Usage and parameters

Syntax: ```canga [PARAM] [COMMAND]```

### version
--version or -V prints out the version number
### add
The add parameter, adds a file to the canga repository
If using the ```--copy``` parameter, the original image is copied instead
of converting it. With this command the sha256 hash of
the file does not change. This is useful to import images
prepared by Linux distros. Check the "Adding an image to a repository" example below
### build
Create a new image using a Cangafile config. Check the "Create a derived image" example below.
### create
Create a new qcow2 image. Check the "Creating a qcow2 image" example below.
### del
Delete an image from the repo
### deltag
Delete a tag. Check the "Tag an image" example below
### export
Export an image to a file
### fetch
Download the index of the repository. Check the "Download a repo" example below
### help
Describe available commands or one specific command
### import
Import an image from a remote repository
### list
List and visualize images (tagged or not). Check the "Listing images in a repository" example below
### overlay
Create a new image based on another one
### pull
Download an image from another repo. Check the "Pull images from a remote repository" example below
### show
Show info about an image
### sign
Sign the index file with keybase. Check the "Sign index" example below
### tag
Add a tag name to an existing image
### verify
Verify index signature with keybase. Check the "Verify index signature" example below
## Examples and scenarios

### Creating a qcow2 image
creating test.qcow2 1GB image

```
$ canga create test.qcow2 1G
test.qcow2
1G
qemu-img create -f qcow2 test.qcow2 1G

$ qemu-img info test.qcow2
image: test.qcow2
file format: qcow2
virtual size: 1.0G (1073741824 bytes)
disk size: 196K
cluster_size: 65536
Format specific information:
    compat: 1.1
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
```

### Adding an image to a repository
Adding test.qcow2 to the repo

```
$ canga add test.qcow2 --tag test_image
Calculating image sha256 with libguestfs (it will take some time)
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ --:--
Image SHA256: 49bc20df15e412a64472421e13fe86ff1c5165e18b2afccf160d4dc19fe68a14
Copying file to repository
qemu-img convert -p -O qcow2 -c test.qcow2 /home/jfontan/.cangallo/default/49bc20df15e412a64472421e13fe86ff1c5165e18b2afccf160d4dc19fe68a14.qcow2
qemu-img info --output=json /home/jfontan/.cangallo/default/49bc20df15e412a64472421e13fe86ff1c5165e18b2afccf160d4dc19fe68a14.qcow2
```

### Listing images in a repository

```
$ canga list
NAME                                                      SIZE DAYS_AGO
  default:zentyal                                    1221.1 Mb    123.1
^ default:zentyal/one                                   2.8 Mb    123.1
    Zentyal with context packages
  default:alpine                                       76.6 Mb    117.3
  default:centos7                                     370.2 Mb     35.4
  default:debian8                                     455.8 Mb     35.4
  default:ubuntu1404                                  247.6 Mb     35.4
  default:ubuntu1604                                  290.1 Mb     35.4
^ default:centos7/one                                  47.7 Mb     35.2
    OpenNebula Compatible CentOS 7
^ default:debian8/one                                  60.1 Mb     35.2
    OpenNebula Compatible Debian 8
^ default:ubuntu1404/one                               51.0 Mb     35.2
    OpenNebula Compatible Ubuntu 14.04
^ default:ubuntu1604/one                               78.0 Mb     35.2
    OpenNebula Compatible Ubuntu 16.04
^ default:alpine/test                                   0.4 Mb     16.9
    test image
  default:centos7-1503                                150.1 Mb      4.2
  default:centos7-1606                                354.2 Mb      2.5
 *remote:zentyal                                     1221.1 Mb    123.1
^*remote:zentyal/one                                    2.8 Mb    123.1
    Zentyal with context packages
  remote:centos72                                     372.9 Mb    119.1
^ remote:473d40cc50278446                              60.6 Mb    119.1
    OpenNebula Compatible CentOS 7.2
 *remote:alpine                                        76.6 Mb    117.3
^*remote:e7033e957c559fb0                               0.4 Mb    117.3
    test image
  local:ubuntu1404                                    270.4 Mb     88.1
  test_remote:ubuntu1404                              270.4 Mb     88.1
```

* `^`: has a parent
* `*`: image was still not downloaded

### Creating a derived image

To create a derived image a "Cangafile" is used. It's a yaml file like this one:

```yaml
---
description: OpenNebula Compatible CentOS 7
os: CentOS 7
parent: centos7
tag: centos7/example
tasks:
  - copy: context /
  - run:
    - rpm -Uvh /context/one-context*rpm
    - yum remove -y NetworkManager cloud-init
    - yum install -y epel-release cloud-utils-growpart ruby --nogpgcheck
    - yum upgrade -y util-linux --nogpgcheck
  - delete: /context
  - password:
      user: root
      password: opennebula
```

* `files` is an array with files and directories to be copied into the image.
* `run` is also an array wih the commands to be executed

Example:

```
$ canga build centos7.canga
copy-in context:/
run-command rpm -Uvh /context/one-context*rpm
run-command yum remove -y NetworkManager cloud-init
run-command yum install -y epel-release cloud-utils-growpart ruby --nogpgcheck
run-command yum upgrade -y util-linux --nogpgcheck
run-command rm -rf /context
qemu-img create -f qcow2 -o backing_file=/home/jfontan/projects/cangallo/repo/ba34b3fce37bc452a2ce51b67b03e94982a6eb27f4eac9584bd78dada9b4d34c.qcow2 /home/jfontan/projects/cangallo/repo/centos7.canga20160714-15977-101cte7.qcow2
[   0.0] Examining the guest ...
[   8.6] Setting a random seed
[   8.6] Copying: context to /
[   8.6] Running: rpm -Uvh /context/one-context*rpm
[   9.3] Running: yum remove -y NetworkManager cloud-init
[  12.8] Running: yum install -y epel-release cloud-utils-growpart ruby --nogpgcheck
[  28.9] Running: yum upgrade -y util-linux --nogpgcheck
[  34.7] Running: rm -rf /context
[  34.7] Setting passwords
[  37.5] Finishing off
[   4.7] Trimming /dev/sda1
[   5.1] Sparsify in-place operation completed with no errors
Calculating image sha256 with libguestfs (it will take some time)
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ --:--
Image SHA256: 88591321d6630bd03ed6b845f556534bb37e2deb83a951966a91e6adf412d3f4
Copying file to repository
qemu-img convert -p -O qcow2 -c -o backing_file=/home/jfontan/projects/cangallo/repo/ba34b3fce37bc452a2ce51b67b03e94982a6eb27f4eac9584bd78dada9b4d34c.qcow2 /home/jfontan/projects/cangallo/repo/centos7.canga20160714-15977-101cte7.qcow2 /home/jfontan/projects/cangallo/repo/88591321d6630bd03ed6b845f556534bb37e2deb83a951966a91e6adf412d3f4.qcow2
qemu-img info --output=json /home/jfontan/projects/cangallo/repo/88591321d6630bd03ed6b845f556534bb37e2deb83a951966a91e6adf412d3f4.qcow2
qemu-img rebase -u -b ba34b3fce37bc452a2ce51b67b03e94982a6eb27f4eac9584bd78dada9b4d34c.qcow2 /home/jfontan/projects/cangallo/repo/88591321d6630bd03ed6b845f556534bb37e2deb83a951966a91e6adf412d3f4.qcow2
Deleting temporary image
```

The image generated is a compressed delta to the parent image. The new image (`centos7/example`) is a delta image and only contains differences with its parent (`centos7`):

```
$ canga list default
NAME                                                      SIZE DAYS_AGO
  default:centos7                                     370.2 Mb     35.4
^ default:centos7/example                              50.3 Mb      0.0
    OpenNebula Compatible CentOS 7
```

### Tag an image

```
$ canga list
NAME                                                      SIZE DAYS_AGO
  default:49bc20df15e412a6                              0.2 Mb      0.0

$ canga tag test_image default:49bc20df15e412a6

$ canga list
NAME                                                      SIZE DAYS_AGO
  default:test_image                                    0.2 Mb      0.0
```

### Sign index

```
$ canga sign default
[enter passphrase]

$ ls -l ~/.cangallo/default/index.yaml.sig
-rw-r--r-- 1 jfontan jfontan 801 Jul 14 22:13 /home/jfontan/.cangallo/default/index.yaml.sig
```

### Verify index signature

```
$ canga verify default
Signature verified. Signed by jfontan 26 seconds ago (2016-07-14 22:15:28 +0200 CEST).
PGP Fingerprint: d21c933397d1dea76ab4035a5255eb6cbbceb6b3.
```

### Share a repository

Cangallo repositories consist of a set of qcow2 image, an index file and optionaly a signature file. By default the repositories reside in `~/.cangallo`. For example for the `default` repostory the path is `~/.cangallo/default`:

```
$ ls -l ~/.cangallo/default/
total 4153760
[...]
2b64e459108e6bcad50db87.qcow2
-rw-r--r-- 1 jfontan jfontan    3014656 Mar 13 18:29 ede6706563e709cd3ee76119113627a62a9cdad3d6f3223a60fe7dd3f311d55d.qcow2
-rw-r--r-- 1 jfontan jfontan 1283999744 Mar 13 18:27 f9c30346359d1a0c80ad9bafdada11decadeaf2b8e3118ba2bae4831319c3342.qcow2
-rw-r--r-- 1 jfontan jfontan   83623936 Jul 21 12:45 fe2c457f66a75856c5aa7f2c5b5b73edc060a60de4fb67f20b5afa5a63ed7f0a.qcow2
-rw-r--r-- 1 jfontan jfontan      18773 Jul 21 12:45 index.yaml
-rw-r--r-- 1 jfontan jfontan        801 Jul 14 22:15 index.yaml.sig
```

To share this repository you can just make it available using an http server. For example, using python to test:

```
$ python2 -mSimpleHTTPServer
Serving HTTP on 0.0.0.0 port 8000 ...
```

To share on external server rsync is recommended.


### Add a remote repo

```
$ cat ~/.cangallo/config
default_repo: default
repos:
    default:
      type: local
      path: ~/.cangallo/default
    remote:
      type: remote
      path: ~/.cangallo/remote
      url: http://localhost:8000
```

### Download a repo index

```
$ bin/canga fetch remote
```

### Pull images from a remote repository

```
$ canga list remote
NAME                                                      SIZE DAYS_AGO
 *remote:ubuntu1404                                   270.4 Mb     88.1

$ canga pull remote:ubuntu1404
Downloading remote:ubuntu1404

$ canga list remote
NAME                                                      SIZE DAYS_AGO
  remote:ubuntu1404                                   270.4 Mb     88.1
```

## Testing

```
sudo env PATH=$PATH rake
```

## License

Cangallo is licensed under the Apache License, Version 2.0.

Author:
  * Javier Fontan Muiños

Contributors:

  * Dan Kelleher
  * Diego Nieto Caride

