#!/bin/bash
#
# Script to organize dotfiles into a central repository and update
# configuration files to reflect the new location.
#
# IMPORTANT:
# - Run this script with caution. It will move files and modify
#   your configuration.
# - BACKUP YOUR DOTFILES BEFORE RUNNING THIS SCRIPT.
# - Test this script in a safe environment first if possible.
# - This script assumes you are using bash or zsh.  Adjust the
#   `config_files` array if needed for other shells.
#
# Variables
dotfiles_dir="$HOME/dotfiles"  # Directory to store dotfiles
backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d)" # Backup directory - CHANGED to %Y%m%d
config_files=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.config/nvim"
    "$HOME/.config/starship.toml"
    "$HOME/.config/alacritty"
    "$HOME/.config/ghostty"
    # Add more config files here as needed.  Be VERY careful with this list.
)
files_to_move=(
    ".bashrc"
    ".zshrc"
    ".vimrc"
    ".config/nvim/"
    ".config/starship.toml"
    ".config/alacritty/"
    ".config/ghostty/"
    # Add more dotfiles to move.  Use relative paths from $HOME
    #  and be VERY careful you don't move directories you shouldn't.
)

# Function to create directories and handle errors
create_dir() {
    mkdir -p "$1"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory: $1"
        exit 1
    fi
}

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

# 1. Create the dotfiles directory
echo "Creating dotfiles directory: $dotfiles_dir"
create_dir "$dotfiles_dir"

# 2. Create a backup of existing dotfiles
echo "Creating backup directory: $backup_dir"
create_dir "$backup_dir"

echo "Backing up existing dotfiles..."
for file in "${files_to_move[@]}"; do
    if [ -e "$HOME/$file" ]; then
        # Determine the full backup path
        backup_path="$backup_dir/$file"
        if [ -d "$HOME/$file" ]; then
            # Handle directories
             create_dir "$backup_path" # Create the directory in the backup
            cp -r "$HOME/$file" "$backup_path"
             if [ $? -eq 0 ]; then
                echo "  Backed up $HOME/$file to $backup_dir/$file"
            else
                echo "  Failed to backup $HOME/$file"
            fi
        else
            # Handle files
            create_dir "$(dirname "$backup_path")" #create dir for file
            mv "$HOME/$file" "$backup_path"
            if [ $? -eq 0 ]; then
              echo "  Backed up $HOME/$file to $backup_path"
            else
              echo "  Failed to backup $HOME/$file"
            fi
        fi
    fi
done

# 3. Move dotfiles to the dotfiles directory
echo "Moving dotfiles to $dotfiles_dir"
for file in "${files_to_move[@]}"; do
    # Extract the filename for use in the move command
    filename=$(basename "$file")
    dirname=$(dirname "$file") #gets the directory
    create_dir "$dotfiles_dir/$dirname" #create the directory inside the dotfiles dir

     if [ -d "$backup_dir/$file" ]; then
        # Handle directories
        move_file "$backup_dir/$file" "$dotfiles_dir/$file"
        echo "  Moved $backup_dir/$file to $dotfiles_dir/$file"
     else
        # Handle files
        move_file "$backup_dir/$file" "$dotfiles_dir/$dirname/$filename" #include dirname in destination
        echo "  Moved $backup_dir/$file to $dotfiles_dir/$dirname/$filename"
     fi
done

# 4. Edit configuration files to source from the dotfiles directory
echo "Editing configuration files..."
for config_file in "${config_files[@]}"; do
    if [ -e "$config_file" ]; then
        echo "  Editing $config_file"
        for file in "${files_to_move[@]}"; do
            # Extract the filename
            filename=$(basename "$file")
            # Construct the path relative to the home directory
            relative_path="$HOME/$filename"
            dotfile_path="$dotfiles_dir/$file"
            # Check if the config_file is the file we are moving, if so, skip it.
            if [[ "$config_file" == "$HOME/$filename" ]]; then
                echo "   Skipping editing of $config_file as it is the same as the dotfile"
                continue
            fi

            # Use a more robust search pattern to avoid accidental replacements
            search_pattern="source $relative_path" #old path
            replace_pattern="source $dotfiles_dir/$file" #new path

            # Check if the search pattern exists before attempting to replace it.
            if grep -q "$search_pattern" "$config_file"; then
                edit_file "$config_file" "$search_pattern" "$replace_pattern"
                echo "    Replaced '$search_pattern' with '$replace_pattern' in $config_file"
            else
                # Append to the file if the source line doesn't exist
                echo "source \"$dotfiles_dir/$file\"" >> "$config_file"
                echo "    Appended 'source $dotfiles_dir/$file' to $config_file"
            fi
        done
    else
        echo "  Warning: Configuration file not found: $config_file"
    fi
done

echo "Dotfiles migration complete."
echo "  - Dotfiles are now in: $dotfiles_dir"
echo "  - Original dotfiles are backed up in: $backup_dir"
echo "  - Please review the changes made to your configuration files."
echo "  - You may need to restart your shell or applications for the changes to take effect."
