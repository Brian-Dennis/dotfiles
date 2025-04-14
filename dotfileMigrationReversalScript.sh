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
backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d)" # Directory where original dotfiles are backed up.
config_files=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.config/nvim"
    "$HOME/.config/starship.toml"
    "$HOME/.config/alacritty"
    "$HOME/.config/ghostty"
    # Add more config files here as needed.  MUST match the original script.
)
files_to_move=(
    ".bashrc"
    ".zshrc"
    ".vimrc"
    ".config/nvim/"
    ".config/starship.toml"
    ".config/alacritty/"
    ".config/ghostty/"
    # Add more dotfiles to move.  MUST match the original script.
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
    sed -i "s@$search@$replace@g" "$file"
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
if [ ! -d "$backup_dir" ]; then
    echo "Error: Backup directory not found: $backup_dir"
    echo "  Please ensure the backup directory exists and the name is correct."
    exit 1
fi

# 2. Move files back from the backup directory
echo "Moving files back from backup directory: $backup_dir"
for file in "${files_to_move[@]}"; do
    # Extract the filename
    filename=$(basename "$file")
    # Construct the original path
    original_path="$HOME/$file"
    # Construct the backup path
    backup_path="$backup_dir/$file"

     if [ -d "$backup_path" ]; then
        # Handle directories
        move_file "$backup_path" "$HOME/$(dirname "$file")"
        echo "  Moved $backup_path to $HOME/$(dirname "$file")"
    else
        # Handle files
        move_file "$backup_path" "$original_path"
        echo "  Moved $backup_path to $original_path"
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
        for file in "${files_to_move[@]}"; do
            # Extract the filename
            filename=$(basename "$file")
            original_path="$HOME/$filename"
            dotfile_path="$dotfiles_dir/$file"

            # Remove the appended 'source' lines
            sed -i "/source \"$dotfiles_dir\/$file\"/d" "$config_file"

            # Restore original 'source' lines (if they existed)
             if [ -e "$backup_dir/$config_file" ]; then #check if a backup of the config file exists
                original_config_content=$(cat "$backup_dir/$config_file")
                if grep -q "source $original_path" <<< "$original_config_content"; then
                    search_pattern=".*source $original_path"
                    replace_pattern="source $original_path"
                    edit_file "$config_file" "$search_pattern" "$replace_pattern"
                    echo "   Restored original source line for $original_path in $config_file"
                fi
            fi
        done
    else
        echo "  Warning: Configuration file not found: $config_file"
    fi
done

echo "Dotfiles migration reversed."
echo "  - Dotfiles have been moved back to their original locations."
echo "  - Configuration files have been restored."
echo "  - Dotfiles directory: $dotfiles_dir has been removed."
echo "  - Please review the changes made to your configuration files."
echo "  - You may need to restart your shell or applications for the changes to take effect."
