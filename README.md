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
done
```

In short:

This script fetches source lists, extracts share links, checks them using xray-knife, and writes working nodes to an output file. All of this runs in an infinite loop *(this can run once or continuously depending on the check interval)*

### What is this for?

This script is primarily designed to simplify the creation of Xray subscriptions on VPS servers.

Basically, you just need to set the source URLs, the output file and the check interval. *(check the usage section)*

## Installation

Download the latest release archive for your system from the Releases page

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
