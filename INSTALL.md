# Installing the Personal HTCondor Open OnDemand Apps

This guide is for Open OnDemand (OOD) administrators. It covers installing the two interactive apps in this
repository on an OOD host. For end-user instructions, see [README.md](README.md).

| App directory        | OOD app name                | Purpose                                                              |
|----------------------|-----------------------------|----------------------------------------------------------------------|
| `ood/personal_ap`    | Create Personal HTCondor    | Launches a multi-node Slurm job: one HTCondor AP plus a set of EPs.  |
| `ood/personal_ep`    | Extend Personal HTCondor    | Launches additional EPs, attached to a user's already-running AP.    |

Run all installation steps on the OOD host.

## Prerequisites

* An Open OnDemand host connected to your Slurm cluster.

* `git` installed on your Open OnDemand Host.

* Interactive Apps [enabled](https://osc.github.io/ood-documentation/latest/how-tos/app-development/interactive/setup.html#app-development-interactive-setup)
  in your Open OnDemand instance.

* Networking enabled among your Slurm worker nodes.
  * Execution Points must be able to initiate a TCP connection to the AP’s listening service (on port 9618 by default),
    and the AP must be able to accept that inbound connection. 
  
* A shared filesystem among your Slurm login node and worker nodes.
  * Interaction with your HTCondor cluster is accomplished via HTCondor command line tools run on your Slurm cluster's login node.
    You must be able to access the HTCondor configuration files provisioned by your AP job from the login node.


## Prepare the Repository

The "Create" and "Extend" Cluster apps share source files. Stage the apps' source in your home directory
prior to installing into the OOD system-level directories. The root `install.sh` copies the shared files 
into both apps' template directories, and must be run before installing into the system-level Open OnDemand
directories. Ensure that `install.sh` is run after each `git clone` or `pull`.

```
git clone git@github.com:mwestphall/personal-slurm-ap.git ~/personal-slurm-ap
cd ~/personal-slurm-ap
./install.sh
```

## System Installation (all users)

1. Copy the two app directories into OOD's system apps directory.

    ```
    sudo cp -r /opt/personal-slurm-ap/ood/personal_ap /var/www/ood/apps/sys/personal_ap
    sudo cp -r /opt/personal-slurm-ap/ood/personal_ep /var/www/ood/apps/sys/personal_ep
    ```

1. Set permissions. Use `755` to share with all users, or `750` plus a group to restrict access:

    ```
    # All users
    sudo chmod -R 755 /var/www/ood/apps/sys/personal_ap /var/www/ood/apps/sys/personal_ep

    # A specific group only
    sudo chgrp -R <group_name> /var/www/ood/apps/sys/personal_ap /var/www/ood/apps/sys/personal_ep
    sudo chmod -R 750 /var/www/ood/apps/sys/personal_ap /var/www/ood/apps/sys/personal_ep
    ```

### Updating

```
cd ~/personal-slurm-ap
git pull
./install.sh
sudo rsync -a --delete ood/personal_ap/ /var/www/ood/apps/sys/personal_ap/
sudo rsync -a --delete ood/personal_ep/ /var/www/ood/apps/sys/personal_ep/
```

Re-check ownership and permissions afterward, as in the previous section.

## Personal (Sandbox) Installation

OOD has no official way for users to install their own interactive apps. This method uses OOD's app development
feature. It lets a user run any app they choose, so it carries a security risk; enable it only for users you trust.

### Administrator steps

Repeat for each user who needs access to the interactive apps:

```
sudo mkdir -p /var/www/ood/apps/dev/<user>
cd /var/www/ood/apps/dev/<user>
sudo ln -s /home/<user>/ondemand/dev gateway
```

### User steps

```
mkdir -p ~/ondemand/dev
git clone git@github.com:mwestphall/personal-slurm-ap.git ~/personal-slurm-ap
cd ~/personal-slurm-ap && ./install.sh
cp -r ood/personal_ap ~/ondemand/dev/personal_ap
cp -r ood/personal_ep ~/ondemand/dev/personal_ep
```

Then restart the web server if needed and open **</> Develop > My Sandbox Apps (Development)** .

## Site Customization

You may update the default resource requests (node count, cpu count, memory, time limit) by editing `form.yml.erb` and `form.yml`
in `ood/personal_ap` and `ood/personal_ep`, respectively. The app installs its HTCondor daemons' working directories into your 
cluster's shared filesystem at `/scratch/$USER` by default. Update `BASE_DIR` in `ood/personal_ap/template/script.sh.erb`
to set the default to a different location. Users may also override the default location via the interactive apps' submission form.

## Verifying the Installation

1. As a test user, open **Interactive Apps > Create Personal HTCondor**, keep the defaults, and launch it.
1. Wait for the session to reach **Running**. The session card should report connected EPs after a short time.
1. Follow "Submit your first HTCondor Job" in [README.md](README.md) to confirm that the sample job runs on an EP.

If a session fails, check the job's `output.log` in OOD's session output directory.
