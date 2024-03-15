#!/bin/sh

# Function to check for missing dependencies and prompt the user to install them
check_and_prompt_dependencies() {
    local missing_counter=0
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Command not found: $cmd"
            missing_counter=$((missing_counter + 1))
            echo "Would you like to install $cmd? (yes/no)"
            read answer
            if [ "$answer" = "yes" ]; then
                echo "Attempting to install $cmd..."
                sudo opkg update && sudo opkg install "$cmd"
                
                # Check again if the command is available after attempting installation
                if ! command -v "$cmd" >/dev/null 2>&1; then
                    echo "Failed to install $cmd. Please install it manually."
                else
                    echo "$cmd installed successfully."
                    missing_counter=$((missing_counter - 1))
                fi
            else
                echo "User chose not to install $cmd."
            fi
        fi
    done
    
    if [ "$missing_counter" -ne 0 ]; then
        echo "There are still missing required commands. Please resolve these issues before running the script again."
        exit 1
    fi
}

# List of required commands
required_commands="lsblk parted mkfs.ext4 mkswap grep awk cut sudo fdisk"

# Check for all required commands and prompt the user for installation if any are missing
check_and_prompt_dependencies $required_commands

echo "Detecting devices with fdisk..."
sudo fdisk -l 2>/dev/null | grep '^Disk /dev/' | cut -d ' ' -f 2 | tr -d ':'

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
        sudo parted /dev/$selected_device --script -- mkpart primary ext4 1MiB 100%
        echo "Formatting partition..."
        part1=$(ls /dev/${selected_device}* | grep -E "${selected_device}p?1$")
        sudo mkfs.ext4 $part1
        ;;
    2)
        device_size=$(sudo blockdev --getsize64 /dev/$selected_device)
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
        sudo parted /dev/$selected_device --script -- mkpart primary ext4 1MiB ${part1_size_mb}MB
        sudo parted /dev/$selected_device --script -- mkpart primary linux-swap ${part1_size_mb}MB 100%
        echo "Formatting partitions..."
        sudo partprobe /dev/$selected_device 2>/dev/null || sleep 2
        part1=$(ls /dev/${selected_device}* | grep -E "${selected_device}p?1$")
        part2=$(ls /dev/${selected_device}* | grep -E "${selected_device}p?2$")
        sudo mkfs.ext4 $part1
        sudo mkswap $part2
        ;;
    *)
        echo "Invalid option selected. Exiting."
        exit 1
        ;;
esac

echo "Operation completed successfully."
