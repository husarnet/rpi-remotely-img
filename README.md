
# Raspberry Pi Available Over the Internet on 1st Boot

This boilerplate project allows you to build your own image based on official Ubuntu 20.04 Server for Raspberry Pi in an easy way.

The project utilises [Hashicorp Packer](https://www.packer.io/) and [packer-builder-arm](https://github.com/mkaczanowski/packer-builder-arm) plugin.

Additional software/configuration for Ubuntu 20.04 Server introduced by this template:
- Wi-Fi configuration based on [Netplan](https://netplan.io/) - enabled on 1st boot.
- [Husarnet VPN Client](https://husarnet.com) for over the Internet access with a systemd service for VPN connection setup on 1st boot.
- Docker & Docker-Compose

> You can install your own packets or change the system configuration as well! See `ubuntu_server_20.04_arm64.pkr.hcl` for details.

## Using the template

### [ Locally ] Docker-Compose and `*.pkrvars.hcl` File

Clone this repo, rename a `configs.pkrvars.hcl.template` file to `configs.pkrvars.hcl` and place your Wi-Fi and Husarnet credentials there.

Then execute:

```bash
docker-compose up --build
```

### [ Locally ] Docker and Environment Variables

Clone this repo, and set Wi-Fi and Husarnet credentials as environment variables. Then build and run the container:

```bash
export MY_SSID="place-your-wifi-ssid-here"
export MY_PASS="place-your-wifi-pass-here"
export MY_HOSTNAME="place-a-hostname-for-your-pi-here"
export MY_JOINCODE="place-your-husarnet-join-code-here"

docker build -t "rpi-image-builder" .

docker run --rm --privileged \
-v /dev:/dev \
-v ${PWD}/packer_cache:/build/packer_cache \
-v ${PWD}/output:/build/output \
rpi-image-builder \
build -var "wifi_ssid=${MY_SSID}" -var "wifi_pass=${MY_PASS}" -var "husarnet_hostname=${MY_HOSTNAME}" -var "husarnet_joincode=${MY_JOINCODE}" .
```

### [ Remotely ] GitHub Actions and Build Artifacts

Create a fork of this repo and define the following secrets for the clonned repo (repo Settings -> Secrets tab):

```
HUSARNET_HOSTNAME
HUSARNET_JOINCODE
WIFI_PASS
WIFI_SSID
```

After triggering the workflow (eg. on `git push`) you should see `rpi-ubuntu-20.04-server-<timestamp>.img.tar.gz` in your workflow artifacts ( repo -> Actions -> (choosen workflow) -> Artifacts ).

### [ Remotely ] GitHub Actions and S3 Server

Create a fork of this repo and define the following secrets for the clonned repo (repo Settings -> Secrets tab):

```
AWS_ACCESS_KEY_ID
AWS_S3_BUCKET
AWS_SECRET_ACCESS_KEY
HUSARNET_HOSTNAME
HUSARNET_JOINCODE
WIFI_PASS
WIFI_SSID
```

After triggering the workflow (eg. on `git push`) you should see:
- `rpi-ubuntu-20.04-server-<timestamp>.img` 
- `rpi-ubuntu-20.04-server-<timestamp>.img.tar.gz`
- `rpi-ubuntu-20.04-server-<timestamp>-sha256.checksum`
files in your S3 bucket.

## Flashing on SD card

1. download file from Amazon S3 (or build locally)
2. format SD card (`Ext4`)
3. extract `*.img.tar.gz` to `*.img`, eg.:

    ```bash
    sudo tar -xf rpi-ubuntu-20.04-server-<timestamp>.img.tar.gz
    ```

4. Now burn that `rpi-ubuntu-20.04-server-<timestamp>.img` image file on SD card using tools like [Etcher](https://www.balena.io/etcher/) or [Raspberry Pi Imager (rpi-imager)](https://www.raspberrypi.org/software/).


## Booting & Accessing your Raspberry Pi

Place SD card in the SD slot of your Pi and power it up. After a while you should see your Raspberry Pi available in your Husarnet VPN network at https://app.husarnet.com.

You can now access your Raspberry Pi over the internet from a level of any device that is in the same Husarnet network by using:

```bash
ssh ubuntu@my-remote-rpi
```