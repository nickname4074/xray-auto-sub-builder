<div align="center">

# xray-auto-sub-builder

**Simple Bash script for easy automatic updates of an Xray subscription on your server using custom sources.**

*By nickname4074*

*Based on [xray-knife](https://github.com/lilendian0x00/xray-knife)*

</div>

## Description

**What does this script do?**

Visually:
```bash
while true; do
    # 1) fetch source lists
    # 2) extract share links
    # 3) check them using xray-knife
    # 4) write working nodes to a static output file
    # 5) sleep ...
done
```

In short:

This script fetches source lists, extracts share links, checks them using xray-knife, and writes working nodes to an output file. All of this runs in an infinite loop *(this can run once or continuously depending on the check interval)*

### What is this for?

This script is primarily designed to simplify the creation of Xray subscriptions on VPS servers.

Basically, you just need to set the source URLs, the output file and the check interval. *(check the usage section)*

## Installation

```bash
# xray-auto-sub-builder
mkdir xray-auto-sub-builder
cd xray-auto-sub-builder
curl -L 'https://github.com/nickname4074/xray-auto-sub-builder/archive/refs/heads/main.tar.gz' | tar xz --strip-components=1

# xray-knife binary
mkdir xray-knife
wget -O xray-knife-linux-amd64.zip 'https://github.com/lilendian0x00/xray-knife/releases/download/v10.0.0/Xray-knife-linux-64.zip' # change url if your system architecture is not linux-amd64
unzip xray-knife-linux-amd64.zip -d ./xray-knife
rm -f xray-knife-linux-amd64.zip
```

## Usage

Add your source URLs to `files/sources.txt`, one URL per line:
```text
https://example.com/source1.txt
https://example.com/source2.txt
https://not.example.com/source69.txt
```

Edit `config.env` *(There are comments there!)*

Run the script:

```bash
./xray-auto-sub-builder.sh
```

The script will fetch source lists, check nodes using [xray-knife](https://github.com/lilendian0x00/xray-knife), and write working share links to the output file defined in `OUT_FILE` *(files/out.txt by default)*

# Credits

**This project is based on [xray-knife](https://github.com/lilendian0x00/xray-knife)**

I think they deserve your star! ;)

# Feel free to leave some feedback!
