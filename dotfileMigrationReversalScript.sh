#!/bin/bash
#
# Script to reverse the actions of the dotfiles migration script.
#
# IMPORTANT:
# - Run this script with caution. It will move files and modify
#   your configuration.
# - This script assumes you have NOT deleted the backup directory
#   created by the migration script.
# - Test this script in a safe environment first if possible.
# - This script assumes you are using bash or zsh.
#
# Variables
dotfiles_dir="$HOME/dotfiles"  # Directory where dotfiles were moved
# Use a pattern to find the backup directory, as the date might vary
# This finds the most recent backup directory matching the pattern
backup_dir=$(ls -td "$HOME"/dotfiles_backup_* 2>/dev/null | head -n 1)

config_files=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.config/nvim"
    "$HOME/.config/starship.toml"
    "$HOME/.config/alacritty"
    "$HOME/.config/ghostty"
    "$HOME/.config/hypr"
    "$HOME/.config/i3"
    "$HOME/.config/kitty"
    "$HOME/.config/mechabar"
    "$HOME/.config/picom"
    "$HOME/.config/polybar"
    "$HOME/.config/rofi"
    "$HOME/.config/screenlayout"
    "$HOME/.config/tmux"
    "$HOME/.config/waybar"
    "$HOME/.config/wofi"
    "$HOME/.config/xresources"
    "$HOME/.bash"
    "$HOME/.zsh" 
)
files_to_move=(
    ".bashrc"
    ".zshrc"
    ".config/nvim/"
    ".config/starship.toml"
    ".config/alacritty/"
    ".config/ghostty/"
    "3d-portfolio/"
    "backgrounds/"
    "bash/"
    ".config/hypr/"
    ".config/i3/"
    ".config/kitty/"
    ".config/mechabar/"
    ".config/picom/"
    ".config/polybar/"
    ".config/rofi/"
    ".config/screenlayout/"
    ".config/tmux/"
    ".config/waybar/"
    ".config/wofi/"
    ".config/xresources/"
    "zsh/"
)

# Function to move files and handle errors
move_file() {
    mv "$1" "$2"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to move file: $1 to $2"
        exit 1
    fi
}

# Function to edit files and handle errors
edit_file() {
    local file="$1"
    local search="$2"
    local replace="$3"

    # Use sed to replace the text
    # Using '#' as delimiter for sed to avoid conflict with paths
    sed -i "s#$search#$replace#g" "$file"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to edit file: $file"
        echo "  Search:  $search"
        echo "  Replace: $replace"
        exit 1
    fi
}

# Function to remove directories and handle errors
remove_dir() {
    rm -rf "$1"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to remove directory: $1"
        exit 1
    fi
}

# 1. Check if the backup directory exists
if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
    echo "Error: Backup directory not found matching pattern: $HOME/dotfiles_backup_*"
    echo "  Please ensure a backup directory exists and the name is correct."
    exit 1
fi
echo "Using backup directory: $backup_dir"

# 2. Move files back from the backup directory
echo "Moving files back from backup directory: $backup_dir"
for file in "${files_to_move[@]}"; do
    # Construct the original path
    original_path="$HOME/$file"
    # Construct the backup path
    backup_path="$backup_dir/$file"

    if [ -e "$backup_path" ]; then # Check if the backup file/directory exists
        if [ -d "$backup_path" ]; then
            # Handle directories
            # Ensure the parent directory exists before moving
            mkdir -p "$HOME/$(dirname "$file")"
            move_file "$backup_path" "$HOME/$(dirname "$file")"
            echo "  Moved $backup_path to $HOME/$(dirname "$file")"
        else
            # Handle files
            # Ensure the parent directory exists before moving
             mkdir -p "$HOME/$(dirname "$file")"
            move_file "$backup_path" "$original_path"
            echo "  Moved $backup_path to $original_path"
        fi
    else
        echo "  Warning: Backup file/directory not found for: $file. Skipping."
    fi
done

# 3. Remove the dotfiles directory
echo "Removing dotfiles directory: $dotfiles_dir"
remove_dir "$dotfiles_dir"

# 4. Restore configuration files (remove added lines, restore original source lines)
echo "Restoring configuration files..."
for config_file in "${config_files[@]}"; do
    if [ -e "$config_file" ]; then
        echo "  Editing $config_file"
        # Remove the appended 'source' lines for all files_to_move
        for file in "${files_to_move[@]}"; do
             # Escape forward slashes in the file path for sed
            escaped_dotfile_path=$(echo "$dotfiles_dir/$file" | sed 's/\//\\\//g')
            sed -i "/source \"$escaped_dotfile_path\"/d" "$config_file"
        done


        # Restore original 'source' lines (if they existed in the backup)
         if [ -e "$backup_dir/$config_file" ]; then #check if a backup of the config file exists
            echo "  Checking backup config file: $backup_dir/$config_file for original source lines."
            # Iterate through original config file lines in backup
            while IFS= read -r line; do
                # Check if the line in the backup starts with 'source ' and contains a path that matches one of the files_to_move
                # This is a heuristic and might need adjustment based on your actual source lines
                for file in "${files_to_move[@]}"; do
                     # Construct the expected original path format
                    original_path_pattern="$HOME/$(echo "$file" | sed 's/\//\\\//g')"
                    if [[ "$line" =~ ^[[:space:]]*source[[:space:]]+[\"\']?${original_path_pattern}[\"\']? ]]; then
                         # Check if this source line is NOT currently in the restored config file
                         if ! grep -q "$line" "$config_file"; then
                             echo "  Restoring original source line in $config_file: $line"
                             # Append the original source line back to the config file
                             echo "$line" >> "$config_file"
                         fi
                         break # Found a match for this line, move to the next line in the backup
                    fi
                done
            done < "$backup_dir/$config_file"
        else
            echo "  No backup found for config file: $config_file. Cannot restore original source lines."
        fi
    else
        echo "  Warning: Configuration file not found: $config_file. Skipping."
    fi
done

echo "Dotfiles migration reversed."
echo "  - Dotfiles have been moved back to their original locations."
echo "  - Configuration files have been restored (appended source lines removed, original source lines from backup restored)."
echo "  - Dotfiles directory: $dotfiles_dir has been removed."
echo "  - Please review the changes made to your configuration files."
echo "  - You may need to restart your shell or applications for the changes to take effect."

