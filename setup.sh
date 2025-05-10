#!/bin/bash
# Script to set up a Linux environment with fuzzy finding, improved terminal, and Neovim.
# Target: Ubuntu 22.04.5 LTS with XFCE

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to print messages in green
echo_green() {
    echo -e "\033[0;32m$1\033[0m"
}

echo_green "Starting Linux environment setup..."

# -----------------------------------------------------------------------------
# 1. SYSTEM UPDATE AND ESSENTIAL TOOLS
# -----------------------------------------------------------------------------
echo_green "Updating package lists and upgrading existing packages..."
sudo apt update && sudo apt upgrade -y

echo_green "Installing essential tools: git, curl, build-essential, software-properties-common, unzip..."
# software-properties-common is for add-apt-repository
# build-essential is for compiling software (e.g., some Neovim plugins)
# unzip is generally useful
sudo apt install -y git curl build-essential software-properties-common unzip

# -----------------------------------------------------------------------------
# 2. FUZZY FINDER (fzf)
# -----------------------------------------------------------------------------
echo_green "Installing fzf (fuzzy finder)..."
sudo apt install -y fzf

# -----------------------------------------------------------------------------
# 3. EXA (modern ls replacement)
# -----------------------------------------------------------------------------
echo_green "Installing exa (modern ls replacement)..."
sudo apt install -y exa

# -----------------------------------------------------------------------------
# 4. ZOXIDE (smarter cd command)
# -----------------------------------------------------------------------------
echo_green "Installing zoxide (smarter cd command)..."
# The install script will attempt to update your .bashrc or similar shell config.
# It typically installs zoxide to ~/.local/bin
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
    echo_green "zoxide already appears to be installed."
fi


# -----------------------------------------------------------------------------
# 5. STARSHIP (cross-shell prompt)
# -----------------------------------------------------------------------------
echo_green "Installing Starship (cross-shell prompt)..."
# The -y flag makes it non-interactive. The script attempts to update .bashrc.
# It typically installs starship to /usr/local/bin or ~/.local/bin
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo_green "Starship already appears to be installed."
fi

echo_green "Ensuring Starship configuration directory exists..."
mkdir -p ~/.config

echo_green "Creating a default starship.toml configuration if it doesn't exist..."
if [ ! -f ~/.config/starship.toml ]; then
    cat <<EOF > ~/.config/starship.toml
# ~/.config/starship.toml
# Visit https://starship.rs/config/ for more configuration options.

# Inserts a blank line between shell prompts
add_newline = true

# Change command timeout from 500 to 1000 ms
command_timeout = 1000

# Format for the prompt character
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vicmd_symbol = "[❮](bold green)"

# Directory configuration
[directory]
style = "bold blue"
truncation_length = 5
truncate_to_repo = true # Truncate path to repository root if in a Git repo

# Git branch display
[git_branch]
symbol = "Branch: " # Nerd Font character for branch
style = "bold yellow"
format = "on [\$symbol\$branch](\$style) "

# Git status display
[git_status]
style = "bold red"
stashed = " " # Nerd Font character for stashed
ahead = "⇡\${count}"
behind = "⇣\${count}"
diverged = "⇕⇡\${ahead_count}⇣\${behind_count}"
conflicted = " " # Nerd Font character for conflicted
deleted = "✘ "
renamed = "» "
modified = "! "
staged = "+ "
untracked = "? "
format = "[\$all_status\$ahead_behind](\$style) "

# Hostname display (useful for SSH)
[hostname]
ssh_only = true # Show only when connected via SSH
style = "bold green"
template = " <[$hostname](bold green)>" # Removed surrounding brackets
disabled = false

# Command duration display
[cmd_duration]
min_time = 1_000  # Show command duration if it takes more than 1 second
style = "bold yellow"
show_milliseconds = false
disabled = false
format = "took [\$duration](\$style)"

# Time display
[time]
disabled = false
style = "bold white"
format = '🕙[\[ %T \]](\$style)' # %T is HH:MM:SS in 24h format. Use %r for 12h AM/PM.
use_12hr = true # if you prefer 12 hour format

# Node.js version
[nodejs]
symbol = "󰎙 " # Nerd Font character for Node.js
format = "via [\$symbol(\$version)](bold green) "
disabled = true # Enable if you work with Node.js projects

# Python version
[python]
symbol = "󰌠 " # Nerd Font character for Python
pyenv_version_name = true
format = "via [\$symbol(\$version)(\$virtualenv)](bold yellow) "
disabled = true # Enable if you work with Python projects

EOF
    echo_green "Default starship.toml created. You may need a Nerd Font for all icons to display correctly."
else
    echo_green "Starship configuration file already exists at ~/.config/starship.toml."
fi

# -----------------------------------------------------------------------------
# 6. NEOVIM (from PPA for stable, up-to-date version)
# -----------------------------------------------------------------------------
echo_green "Installing Neovim (stable PPA)..."
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo apt update
sudo apt install -y neovim

# -----------------------------------------------------------------------------
# 7. CONFIGURE .bashrc
# -----------------------------------------------------------------------------
echo_green "Configuring .bashrc..."

# Ensure .bashrc exists
touch ~/.bashrc

BASHRC_ADDITIONS_TAG_START="# --- Custom additions by setup script START ---"
BASHRC_ADDITIONS_TAG_END="# --- Custom additions by setup script END ---"

# Check if the block already exists
if grep -qF "$BASHRC_ADDITIONS_TAG_START" ~/.bashrc; then
    echo_green "~/.bashrc already contains the custom additions block. Skipping structural appends to avoid duplication."
    echo_green "If you need to re-apply settings, please remove the block between '$BASHRC_ADDITIONS_TAG_START' and '$BASHRC_ADDITIONS_TAG_END' from your .bashrc and re-run."
else
    echo_green "Adding custom configurations to ~/.bashrc..."
    # Using a temporary file for the additions
    TMP_BASHRC_ADDITIONS=$(mktemp)

    cat <<EOF > "$TMP_BASHRC_ADDITIONS"

$BASHRC_ADDITIONS_TAG_START

# Add ~/.local/bin to PATH if it exists and is not already in PATH
# This is where zoxide and potentially starship (if user-installed) might be.
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi

# Initialize Starship prompt
# The Starship installer should add this, but this is a fallback.
if command -v starship &> /dev/null; then
  if ! grep -q 'eval "\$(starship init bash)"' ~/.bashrc; then
    echo 'eval "\$(starship init bash)"' >> ~/.bashrc # Appends outside the heredoc block initially, then it will be part of the block on next run if this logic is inside the heredoc.
                                                    # For robustness, this specific check and append should be outside the main cat <<EOF >> ~/.bashrc block or handled carefully.
                                                    # For simplicity here, we assume the installer handles it. If not, this line should be added.
                                                    # The installer for starship is generally reliable.
  fi
else
  echo "Starship command not found. Skipping starship init in .bashrc."
fi
# The starship installer (curl ... | sh -s -- -y) typically adds: eval "\$(starship init bash)"

# Initialize zoxide
# The zoxide installer script typically adds: eval "\$(~/.local/bin/zoxide init bash)" or similar.
if command -v zoxide &> /dev/null; then
  if ! grep -q 'eval "\$(zoxide init bash)"' ~/.bashrc && ! grep -q 'eval ".*zoxide init bash"' ~/.bashrc ; then # Check for generic and specific path
     # This assumes zoxide is in the PATH after the .local/bin addition.
     # The zoxide installer is generally reliable.
     echo 'eval "\$(zoxide init bash)"' >> ~/.bashrc
  fi
else
  echo "Zoxide command not found. Skipping zoxide init in .bashrc."
fi


# Custom Aliases for exa
alias ls='exa --icons --color=always --group-directories-first'
alias la='exa -a --icons --color=always --group-directories-first' # -a includes dotfiles
alias ll='exa -alh --icons --color=always --group-directories-first --header' # -l for long, -h for human-readable, --header
alias l.='exa -a --icons --color=always --group-directories-first .[^.]* ..?*' # List only dotfiles/dotdirs
alias tree='exa --tree --icons --level=3' # Tree view, 3 levels deep

# fzf keybindings and fuzzy completion
# The fzf package for Ubuntu (>= 18.04) should install files that enable this.
# Key bindings (Ctrl-T, Ctrl-R, Alt-C) are typically enabled by sourcing a script.
FZF_KEYBINDINGS_PATH="/usr/share/doc/fzf/examples/key-bindings.bash"
if [ -f "\$FZF_KEYBINDINGS_PATH" ]; then
    if ! grep -q "source \$FZF_KEYBINDINGS_PATH" ~/.bashrc && ! grep -q "key-bindings.bash" ~/.bashrc; then
        echo "source \$FZF_KEYBINDINGS_PATH"
    fi
else
    echo "fzf keybindings script not found at \$FZF_KEYBINDINGS_PATH."
fi

# fzf completion for bash should be automatically enabled if bash-completion is installed
# and the fzf package places a file in /usr/share/bash-completion/completions/
# If not, you might need to source /usr/share/doc/fzf/examples/completion.bash
FZF_COMPLETION_PATH="/usr/share/doc/fzf/examples/completion.bash"
FZF_SYSTEM_COMPLETION="/usr/share/bash-completion/completions/fzf"
if [ -f "\$FZF_COMPLETION_PATH" ] && [ ! -f "\$FZF_SYSTEM_COMPLETION" ]; then
    if ! grep -q "source \$FZF_COMPLETION_PATH" ~/.bashrc && ! grep -q "completion.bash" ~/.bashrc; then
        echo "source \$FZF_COMPLETION_PATH"
    fi
fi

# Set Neovim as default editor
export EDITOR=nvim
export VISUAL=nvim

$BASHRC_ADDITIONS_TAG_END
EOF

    # Append the collected additions to .bashrc
    # The starship and zoxide init lines are best handled by their installers.
    # The `echo 'eval ...'` lines above for starship/zoxide are more of a double check
    # and should ideally be integrated into this heredoc if they are to be managed by this script block.
    # For now, relying on installers for their specific init lines, and this block for aliases etc.

    # Refined approach: let installers do their job for init lines.
    # This script will add aliases, PATH, editor vars, and fzf sourcing.

    (grep -q 'eval "$(starship init bash)"' ~/.bashrc || (command -v starship &>/dev/null && echo 'eval "$(starship init bash)"' >> ~/.bashrc))
    (grep -q 'eval "$(zoxide init bash)"' ~/.bashrc || (command -v zoxide &>/dev/null && echo 'eval "$(zoxide init bash)"' >> ~/.bashrc))


    # Re-generating the content for the block without starship/zoxide init lines,
    # as those are added above if missing, or by installers.
    cat <<EOF > "$TMP_BASHRC_ADDITIONS"

$BASHRC_ADDITIONS_TAG_START

# Add ~/.local/bin to PATH if it exists and is not already in PATH
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi

# Custom Aliases for exa
alias ls='exa --icons --color=always --group-directories-first'
alias la='exa -a --icons --color=always --group-directories-first'
alias ll='exa -alh --icons --color=always --group-directories-first --header'
alias l.='exa -aD --icons --color=always --group-directories-first .[^.]* ..?*' # List only dotfiles/dotdirs (D for dirs-on-top)
alias tree='exa --tree --icons --level=3'

# fzf keybindings
FZF_KEYBINDINGS_PATH="/usr/share/doc/fzf/examples/key-bindings.bash"
if [ -f "\$FZF_KEYBINDINGS_PATH" ]; then
    if ! grep -q "key-bindings.bash" ~/.bashrc; then # Simpler grep
        echo "source \$FZF_KEYBINDINGS_PATH"
    fi
fi

# fzf completion (usually handled by bash-completion system-wide)
# FZF_COMPLETION_PATH="/usr/share/doc/fzf/examples/completion.bash"
# FZF_SYSTEM_COMPLETION="/usr/share/bash-completion/completions/fzf"
# if [ -f "\$FZF_COMPLETION_PATH" ] && [ ! -f "\$FZF_SYSTEM_COMPLETION" ]; then
#    if ! grep -q "completion.bash" ~/.bashrc; then # Simpler grep
#        echo "source \$FZF_COMPLETION_PATH"
#    fi
# fi

# Set Neovim as default editor
export EDITOR=nvim
export VISUAL=nvim

$BASHRC_ADDITIONS_TAG_END
EOF
    # Now append the content of TMP_BASHRC_ADDITIONS to ~/.bashrc
    cat "$TMP_BASHRC_ADDITIONS" >> ~/.bashrc
    rm "$TMP_BASHRC_ADDITIONS"
    echo_green "Custom configurations appended to ~/.bashrc."
fi


# -----------------------------------------------------------------------------
# 8. FINAL INSTRUCTIONS
# -----------------------------------------------------------------------------
echo_green "------------------------------------------------------------------"
echo_green "Setup script finished!"
echo_green "------------------------------------------------------------------"
echo_green "IMPORTANT: You need to source your .bashrc or open a new terminal for changes to take effect:"
echo_green "  source ~/.bashrc"
echo_green ""
echo_green "Notes:"
echo_green "- Starship & Exa Icons: For the best visual experience with icons in Starship and Exa, consider installing a Nerd Font (e.g., FiraCode Nerd Font, JetBrainsMono Nerd Font)."
echo_green "  You can find Nerd Fonts at: https://www.nerdfonts.com/"
echo_green "  After installing a Nerd Font, set it as your terminal font in XFCE Terminal:"
echo_green "    Terminal > Edit > Preferences > Appearance > Font."
echo_green "- Starship Config: Customize your prompt further by editing ~/.config/starship.toml"
echo_green "- Neovim: You can now start Neovim by typing 'nvim'. Consider creating a Neovim config at ~/.config/nvim/init.vim or ~/.config/nvim/init.lua."
echo_green "- Zoxide: Start navigating directories with 'z'. For example, 'z myproject'."
echo_green "------------------------------------------------------------------"