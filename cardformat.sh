#!/bin/sh

# Function to check for missing dependencies and offer to install them
check_and_prompt_dependencies() {
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Command not found: $cmd"
            echo "Would you like to install $cmd? (yes/no)"
            read answer
            if [ "$answer" = "yes" ]; then
                echo "Attempting to install $cmd..."
                opkg update && opkg install "$cmd"
                
                # Check again if the command is available after attempting installation
                if ! command -v "$cmd" >/dev/null 2>&1; then
                    echo "Failed to install $cmd. Please install it manually."
                    exit 1
                else
                    echo "$cmd installed successfully."
                fi
            else
                echo "User chose not to install $cmd. Exiting."
                exit 1
            fi
        fi
    done
}

# List of required commands
required_commands="lsblk parted mkfs.ext4 mkswap grep awk cut fdisk blockdev"

# Check for all required commands and prompt the user for installation if any are missing
check_and_prompt_dependencies $required_commands

echo "Detecting devices with fdisk..."
fdisk -l 2>/dev/null | grep '^Disk /dev/' | cut -d ' ' -f 2 | tr -d ':'

echo "WARNING: This list includes all detected disks, including your system drive(s). Please select carefully to avoid data loss."
echo "Enter the device path to work with (e.g., /dev/sdb):"
read selected_device

# Verify device exists
if [ ! -b "$selected_device" ]; then
    echo "Device $selected_device does not exist or is not a block device. Please select a valid device."
    exit 1
fi

echo "Select formatting option:"
echo "1) Entire device as EXT4"
echo "2) 70% EXT4 and 30% as swap"
read formatting_option

case $formatting_option in
    1)
        echo "Creating one large EXT4 partition..."
        parted $selected_device --script -- mkpart primary ext4 1MiB 100%
        echo "Formatting partition..."
        partprobe $selected_device 2>/dev/null || sleep 2
        mkfs.ext4 ${selected_device}1
        ;;
    2)
        device_size=$(blockdev --getsize64 $selected_device)
        device_size_mb=$((device_size / 1024 / 1024))
        part1_size_mb=$((device_size_mb * 70 / 100))
        swap_size_mb=$((device_size_mb - part1_size_mb))

        if [ "$swap_size_mb" -lt 1024 ]; then
            echo "The swap partition size is less than 1GB."
            echo "Do you want to proceed anyway? Type 'yes' to continue, or 'no' to abort:"
            read proceed_swap

            if [ "$proceed_swap" != "yes" ]; then
                echo "Operation aborted by the user."
                exit 1
            fi
        fi

        echo "Creating partitions..."
        parted $selected_device --script -- mkpart primary ext4 1MiB ${part1_size_mb}MB
        parted $selected_device --script -- mkpart primary linux-swap ${part1_size_mb}MB 100%
        echo "Formatting partitions..."
        partprobe $selected_device 2>/dev/null || sleep 2
        mkfs.ext4 ${selected_device}1
        mkswap ${selected_device}2
        ;;
    *)
        echo "Invalid option selected. Exiting."
        exit 1
        ;;
esac

echo "Operation completed successfully."
