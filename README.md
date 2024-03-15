# OpenWRT Disk Formatting Utility

This utility provides a simple, interactive shell script designed to facilitate disk formatting on OpenWRT devices. It allows users to detect connected storage devices, choose a device, and format it either entirely as EXT4 or partition it into a primary EXT4 partition and a secondary swap partition.

## Features

- **Interactive Device Detection:** Lists all connected storage devices, excluding the primary system disk to prevent accidental formatting.
- **Flexible Formatting Options:** Supports formatting the entire device as EXT4 or creating a dual partition setup with EXT4 and swap.
- **Dependency Management:** Checks for necessary command-line utilities and offers to install missing ones via `opkg`.
- **Safety Checks:** Includes confirmation prompts to help prevent unintended data loss.

## Requirements

- An OpenWRT device with `opkg` package manager access.
- Root or sufficient permissions to install packages and perform disk operations.
- Internet access for installing missing dependencies.

## Installation

1. **Download the Script:**
   - Use `wget` or `curl` to download the script directly to your OpenWRT device, or
   - Transfer the script to your device using `scp` or a similar file transfer method.

2. **Make the Script Executable:**
   ```sh
   chmod +x cardformat.sh
   ```

## Usage

Run the script with root privileges:

```sh
sudo ./cardformat.sh
```

Follow the interactive prompts to select a device and formatting option.

**Warning:** Be very careful when selecting the device to format. This utility will erase all data on the selected device.

## Contributing

Contributions to improve the utility or address issues are welcome. Please feel free to submit pull requests or open issues for discussion.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

### Additional Notes for README

- **Customization:** You may want to add sections on how to contribute, report issues, or specific configurations and considerations related to OpenWRT devices.
- **License:** I've assumed an MIT License for this example. Ensure you choose a license that suits your project's needs. GitHub offers a [guide to licensing](https://help.github.com/articles/licensing-a-repository/) that might be helpful.
- **Formatting:** Markdown formatting allows you to make the README more readable and organized. Utilize headings, lists, code blocks, and links to improve clarity.

Remember, a good README is key to engaging the community and encouraging use and contribution to your project.
