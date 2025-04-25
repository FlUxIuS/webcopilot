#!/bin/bash

#Colors Output
NORMAL="\e[0m"
BOLD="\033[01;01m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
LCYAN="\033[1;36m"

# Error handling function
error_exit() {
    echo -e "${RED}[ERROR]${NORMAL} $1" >&2
    exit 1
}

# Debug logging function
debug_log() {
    echo -e "${YELLOW}[DEBUG]${NORMAL} $1"
}

# Check if the script is running as root or not
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[*]${NORMAL} This script must be run as root" 1>&2
    echo -e "${YELLOW}[*]${NORMAL} Make sure you're root before installing the tools"
    echo -e "${LCYAN}[*]${NORMAL} Exiting..."
    exit 1
fi

# Set script to exit on error
set -e
trap 'error_exit "Script failed at line $LINENO"' ERR

clear
cd

# Create Directories
dirs(){
    debug_log "Creating directories..."
    echo -e "${LCYAN}[*]${NORMAL} Creating Directories"
    mkdir -p ~/tools || error_exit "Failed to create ~/tools"
    mkdir -p ~/.gf || error_exit "Failed to create ~/.gf"
    mkdir -p ~/wordlists || error_exit "Failed to create ~/wordlists"
    mkdir -p ~/wordlists/payloads/ || error_exit "Failed to create ~/wordlists/payloads"
    debug_log "Directories created successfully"
}

# Update and Upgrade System
update_system() {
    debug_log "Updating system..."
    echo -e "${LCYAN}[*]${NORMAL} Updating and Upgrading System"
    sudo apt-get update -y || error_exit "Failed to update system"
    debug_log "System updated successfully"
}

# Install Dependencies
dependencies(){
    debug_log "Installing dependencies..."
    echo -e "${LCYAN}[*]${NORMAL} Installing Dependencies and Checking is Installed or Not"
    
    # Git
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} git could not be found ${LCYAN}[*]${NORMAL} Installing git"
        sudo apt install git -y || error_exit "Failed to install git"
        if command -v git &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} git is installed successfully"
        else
            error_exit "git installation failed"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} git is already installed"
    fi

    # Python3
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} python3 could not be found ${LCYAN}[*]${NORMAL} Installing python3"
        sudo apt install python3 -y || error_exit "Failed to install python3"
        if command -v python3 &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} python3 is installed successfully"
        else
            error_exit "python3 installation failed"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} python3 is already installed"
    fi

    # Pip3
    if ! command -v pip3 &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} pip3 could not be found ${LCYAN}[*]${NORMAL} Installing python3-pip"
        sudo apt install python3-pip -y || error_exit "Failed to install python3-pip"
        if command -v pip3 &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} python3-pip is installed successfully"
        else
            error_exit "python3-pip installation failed"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} python3-pip is already installed"
    fi

    # Ruby
    if ! command -v ruby &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} ruby could not be found ${LCYAN}[*]${NORMAL} Installing ruby"
        sudo apt install ruby -y || error_exit "Failed to install ruby"
        if command -v ruby &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} ruby is installed successfully"
        else
            error_exit "ruby installation failed"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} ruby is already installed"
    fi

    # Go
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} golang-go could not be found ${LCYAN}[*]${NORMAL} Installing golang-go"
        debug_log "Downloading Go..."
        # Detect architecture
        ARCH=$(uname -m)
        GO_VERSION="1.24.2"
        GO_ARCH=""
        
        case "$ARCH" in
            "x86_64") GO_ARCH="amd64" ;;
            "aarch64"|"arm64") GO_ARCH="arm64" ;;
            *) error_exit "Unsupported architecture: $ARCH" ;;
        esac
        
        debug_log "Architecture detected: $ARCH, using Go arch: $GO_ARCH"
        
        wget "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" || error_exit "Failed to download Go"
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" || error_exit "Failed to extract Go"
        
        # Remove existing Go configurations from bashrc if they exist
        sed -i '/\/usr\/local\/go\/bin/d' ~/.bashrc
        sed -i '/GOROOT=/d' ~/.bashrc
        sed -i '/GOPATH=/d' ~/.bashrc
        
        # Add Go environment variables
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
        
        # Remove downloaded archive
        rm -f "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
        
        # Set environment variables for current session
        export PATH=$PATH:/usr/local/go/bin
        export GOROOT=/usr/local/go
        export GOPATH=$HOME/go
        export PATH=$PATH:$GOPATH/bin
        
        # Create Go directories
        mkdir -p $GOPATH/{src,pkg,bin}
        
        # Source bashrc to update current session
        source ~/.bashrc
        
        if command -v go &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} golang-go is installed successfully"
            debug_log "Go version: $(go version)"
        else
            error_exit "golang-go installation failed"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} golang-go is already installed"
        # Ensure GOPATH and PATH are set correctly even if Go is already installed
        export GOPATH=$HOME/go
        export PATH=$PATH:$GOPATH/bin
        mkdir -p $GOPATH/{src,pkg,bin}
    fi

    # Snap
    if ! command -v snap &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} snapd could not be found ${LCYAN}[*]${NORMAL} Installing snapd"
        sudo apt install snapd -y || error_exit "Failed to install snapd"
        # Wait for snapd to be ready
        sleep 3
        if command -v snap &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} snapd is installed successfully"
        else
            echo -e "${YELLOW}[*]${NORMAL} snapd may require system restart"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} snapd is already installed"
    fi

    # Other dependencies
    local deps=(cmake jq gobuster parallel unzip)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${YELLOW}[*]${NORMAL} $dep could not be found ${LCYAN}[*]${NORMAL} Installing $dep"
            sudo apt install "$dep" -y || error_exit "Failed to install $dep"
            if command -v "$dep" &> /dev/null; then
                echo -e "${GREEN}[*]${NORMAL} $dep is installed successfully"
            else
                error_exit "$dep installation failed"
            fi
        else
            echo -e "${GREEN}[*]${NORMAL} $dep is already installed"
        fi
    done

    # Chromium (via snap)
    if ! command -v chromium &> /dev/null && ! snap list chromium &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} chromium could not be found ${LCYAN}[*]${NORMAL} Installing chromium"
        if command -v snap &> /dev/null; then
            sudo snap install chromium || echo -e "${YELLOW}[*]${NORMAL} Chromium installation via snap failed - non-critical"
        else
            echo -e "${YELLOW}[*]${NORMAL} Snap not available, skipping chromium installation"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} chromium is already installed"
    fi
}

# Install Python Tools
python_tools(){
    debug_log "Installing Python tools..."
    echo -e "${LCYAN}[*]${NORMAL} Installing Python Tools"
    
    # SUBLIST3R
    if [ ! -d ~/tools/SUBLIST3R_V2.0 ]; then
        echo -e "${YELLOW}[*]${NORMAL} Sublist3r could not be found ${LCYAN}[*]${NORMAL} Installing Sublist3r"
        cd && git clone https://github.com/hxlxmjxbbxs/SUBLIST3R_V2.0 ~/tools/SUBLIST3R_V2.0 || error_exit "Failed to clone SUBLIST3R"
        cd ~/tools/SUBLIST3R_V2.0 && sudo pip3 install -r requirements.txt || echo -e "${YELLOW}[*]${NORMAL} Some SUBLIST3R requirements failed to install"
        if [ -d ~/tools/SUBLIST3R_V2.0 ]; then
            echo -e "${GREEN}[*]${NORMAL} Sublist3r is installed successfully"
        else
            echo -e "${RED}[*]${NORMAL} Sublist3r is not installed successfully, Please install it manually"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} Sublist3r is already installed"
    fi
    
    # Other Python tools
    local python_tool_list=(
        "sqlmap https://github.com/sqlmapproject/sqlmap.git"
        "urldedupe https://github.com/ameenmaali/urldedupe.git"
        "openredirex https://github.com/devanshbatham/openredirex"
        "waymore https://github.com/xnl-h4ck3r/waymore.git"
    )
    
    for tool_info in "${python_tool_list[@]}"; do
        IFS=' ' read -r tool_name tool_url <<< "$tool_info"
        if [ ! -d ~/tools/"$tool_name" ]; then
            echo -e "${YELLOW}[*]${NORMAL} $tool_name could not be found ${LCYAN}[*]${NORMAL} Installing $tool_name"
            cd && git clone "$tool_url" ~/tools/"$tool_name" || echo -e "${YELLOW}[*]${NORMAL} Failed to clone $tool_name"
            
            # Special handling for urldedupe
            if [ "$tool_name" == "urldedupe" ] && [ -d ~/tools/urldedupe ]; then
                cd ~/tools/urldedupe && cmake CMakeLists.txt && make && sudo mv urldedupe /usr/bin/ || echo -e "${YELLOW}[*]${NORMAL} Failed to build urldedupe"
            fi
            
            # Special handling for openredirex
            if [ "$tool_name" == "openredirex" ] && [ -d ~/tools/openredirex ]; then
                cd ~/tools/openredirex && sudo chmod +x setup.sh && ./setup.sh || echo -e "${YELLOW}[*]${NORMAL} Failed to setup openredirex"
            fi
            
            if [ -d ~/tools/"$tool_name" ]; then
                echo -e "${GREEN}[*]${NORMAL} $tool_name is installed successfully"
            else
                echo -e "${RED}[*]${NORMAL} $tool_name is not installed successfully, Please install it manually"
            fi
        else
            echo -e "${GREEN}[*]${NORMAL} $tool_name is already installed"
        fi
    done

    # Findomain
    if ! command -v findomain &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} findomain could not be found ${LCYAN}[*]${NORMAL} Installing findomain"
        cd ~/tools/ && wget https://github.com/Findomain/Findomain/releases/download/9.0.4/findomain-linux.zip || echo -e "${YELLOW}[*]${NORMAL} Failed to download findomain"
        if [ -f findomain-linux.zip ]; then
            unzip findomain-linux.zip && chmod +x findomain && sudo mv findomain /usr/bin/ || echo -e "${YELLOW}[*]${NORMAL} Failed to install findomain"
        fi
        if command -v findomain &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} findomain is installed successfully"
        else
            echo -e "${RED}[*]${NORMAL} findomain is not installed successfully, Please install it manually"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} findomain is already installed"
    fi

    # Uro
    if ! command -v uro &> /dev/null; then
        echo -e "${YELLOW}[*]${NORMAL} uro could not be found ${LCYAN}[*]${NORMAL} Installing uro"
        pip3 install uro || echo -e "${YELLOW}[*]${NORMAL} Failed to install uro"
        if command -v uro &> /dev/null; then
            echo -e "${GREEN}[*]${NORMAL} uro is installed successfully"
        else
            echo -e "${RED}[*]${NORMAL} uro is not installed successfully, Please install it manually"
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} uro is already installed"
    fi
}

# Install Wordlists
wordlists(){
    debug_log "Installing wordlists..."
    echo -e "${LCYAN}[*]${NORMAL} Installing Wordlists and Payloads"
    local base_url="https://raw.githubusercontent.com"
    cd ~/wordlists/

    # Define an associative array for files and URLs
    declare -A files=(
        ["big.txt"]="${base_url}/danielmiessler/SecLists/master/Discovery/Web-Content/big.txt"
        ["dicc.txt"]="https://gist.githubusercontent.com/Lopseg/33106eb13372a72a31154e0bbab2d2b3/raw/a79331799a70d0ae0ea906f2b143996d85f71de5/dicc.txt"
        ["dns.txt"]="${base_url}/danielmiessler/SecLists/master/Discovery/DNS/dns-Jhaddix.txt"
        ["subdomains.txt"]="${base_url}/danielmiessler/SecLists/master/Discovery/DNS/deepmagic.com-prefixes-top50000.txt"
        ["resolvers.txt"]="${base_url}//janmasarik/resolvers/master/resolvers.txt"
        ["fuzz.txt"]="${base_url}//Bo0oM/fuzz.txt/master/fuzz.txt"
        ["payloads/lfi.txt"]="${base_url}//R0X4R/Garud/master/.github/payloads/lfi.txt"
    )

    # Iterate over the associative array
    for file in "${!files[@]}"; do
        if [ ! -f "$file" ]; then
            echo -e "${YELLOW}[*]${NORMAL} Downloading $file..."
            wget -q -O "$file" "${files[$file]}" || echo -e "${YELLOW}[*]${NORMAL} Failed to download $file"
        else
            echo -e "${GREEN}[*]${NORMAL} Skipping $file, already exists."
        fi
    done
}

# Install Go Tools
go_tools(){
    debug_log "Installing Go tools..."
    echo -e "${LCYAN}[*]${NORMAL} Installing Go Tools"
    
    # Ensure Go environment is set up
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin
    export GOPROXY=https://proxy.golang.org,direct
    export GOSUMDB=off  # Disable GOSUMDB to avoid verification issues
    export GO111MODULE=on
    export GOBIN=$GOPATH/bin
    
    # Create Go directories if they don't exist
    mkdir -p $GOPATH/{src,pkg,bin}
    
    debug_log "Go environment: GOPATH=$GOPATH, GOBIN=$GOBIN"
    
    # List of Go tools to install
    local go_tools_list=(
        "anew github.com/tomnomnom/anew@latest"
        "gf github.com/tomnomnom/gf@latest"
        "assetfinder github.com/tomnomnom/assetfinder@latest"
        "gau github.com/lc/gau/v2/cmd/gau@latest"
        "waybackurls github.com/tomnomnom/waybackurls@latest"
        "httpx github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "amass github.com/owasp-amass/amass/v4/...@master"
        "kxss github.com/Emoe/kxss@latest"
        "subjack github.com/haccer/subjack@latest"
        "qsreplace github.com/tomnomnom/qsreplace@latest"
        "dnsx github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        "dalfox github.com/hahwul/dalfox/v2@latest"
        "crlfuzz github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest"
        "nuclei github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    )
    
    for tool_info in "${go_tools_list[@]}"; do
        IFS=' ' read -r tool_name tool_path <<< "$tool_info"
        if ! command -v "$tool_name" &> /dev/null && [ ! -f ~/go/bin/"$tool_name" ]; then
            echo -e "${YELLOW}[*]${NORMAL} $tool_name could not be found ${LCYAN}[*]${NORMAL} Installing $tool_name"
            debug_log "Installing: go install $tool_path"
            go install "$tool_path" || echo -e "${YELLOW}[*]${NORMAL} Failed to install $tool_name"
            if [ -f ~/go/bin/"$tool_name" ]; then
                echo -e "${GREEN}[*]${NORMAL} $tool_name is installed successfully"
            else
                echo -e "${RED}[*]${NORMAL} $tool_name is not installed successfully, Please install it manually"
            fi
        else
            echo -e "${GREEN}[*]${NORMAL} $tool_name is already installed"
        fi
    done
    
    # Special handling for aquatone
    if ! command -v aquatone &> /dev/null && [ ! -f ~/go/bin/aquatone ]; then
        echo -e "${YELLOW}[*]${NORMAL} aquatone could not be found ${LCYAN}[*]${NORMAL} Installing aquatone"
        # Download pre-built binary instead of compiling from source
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip -O aquatone.zip
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_arm64_1.7.0.zip -O aquatone.zip
        else
            echo -e "${RED}[*]${NORMAL} Unsupported architecture for aquatone: $ARCH"
        fi
        
        if [ -f aquatone.zip ]; then
            unzip aquatone.zip && chmod +x aquatone && mv aquatone $GOPATH/bin/ && rm aquatone.zip
            if [ -f ~/go/bin/aquatone ]; then
                echo -e "${GREEN}[*]${NORMAL} aquatone is installed successfully"
            else
                echo -e "${RED}[*]${NORMAL} aquatone is not installed successfully, Please install it manually"
            fi
        fi
    else
        echo -e "${GREEN}[*]${NORMAL} aquatone is already installed"
    fi
}

# Configure Tools and Setup Environment
configs(){
    debug_log "Configuring tools..."
    echo -e "${LCYAN}[*]${NORMAL} Configuring Tools and Setting Up Environment"
    
    # Ensure .gf directory exists
    mkdir -p ~/.gf
    mkdir -p ~/go/src/github.com/tomnomnom

    # Clone gf if not already cloned
    if [ ! -d "$HOME/go/src/github.com/tomnomnom/gf" ]; then
        git clone https://github.com/tomnomnom/gf.git $HOME/go/src/github.com/tomnomnom/gf || echo -e "${YELLOW}[*]${NORMAL} Failed to clone gf"
    fi

    # Copy gf examples if they exist
    if [ -d "$HOME/go/src/github.com/tomnomnom/gf/examples" ]; then
        cp -r $HOME/go/src/github.com/tomnomnom/gf/examples/* ~/.gf/ || echo -e "${YELLOW}[*]${NORMAL} Failed to copy gf examples"
    fi

    # Add gf completion to bashrc if it's not already there
    if ! grep -q 'gf-completion.bash' ~/.bashrc; then
        if [ -f "$HOME/go/src/github.com/tomnomnom/gf/gf-completion.bash" ]; then
            echo "source $HOME/go/src/github.com/tomnomnom/gf/gf-completion.bash" >> ~/.bashrc
        fi
    fi

    # Add GOPATH/bin to PATH in bashrc if it's not already there
    if ! grep -q 'GOPATH/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
    fi

    # Clone Gf-Patterns and move json files if not already done
    if [ ! -f ~/.gf/redirect.json ]; then
        git clone https://github.com/1ndianl33t/Gf-Patterns ~/Gf-Patterns || echo -e "${YELLOW}[*]${NORMAL} Failed to clone Gf-Patterns"
        if [ -d ~/Gf-Patterns ]; then
            cp ~/Gf-Patterns/*.json ~/.gf/ || echo -e "${YELLOW}[*]${NORMAL} Failed to copy Gf-Patterns"
            rm -rf ~/Gf-Patterns
        fi
    fi

    # Clone Garud, move payloads, and clean up if not already done
    if [ ! -f ~/.gf/cors.json ]; then
        git clone https://github.com/R0X4R/Garud.git ~/Garud || echo -e "${YELLOW}[*]${NORMAL} Failed to clone Garud"
        if [ -d ~/Garud/.github/payloads/patterns ]; then
            cp ~/Garud/.github/payloads/patterns/*.json ~/.gf/ || echo -e "${YELLOW}[*]${NORMAL} Failed to copy Garud patterns"
            rm -rf ~/Garud
        fi
    fi

    # Ensure all binaries from go/bin are in /usr/bin if they aren't already there
    if [ -d ~/go/bin ]; then
        sudo cp ~/go/bin/* /usr/bin/ 2>/dev/null || echo -e "${YELLOW}[*]${NORMAL} Some go binaries failed to copy to /usr/bin"
    fi

    # Update nuclei templates
    if command -v nuclei &> /dev/null; then
        nuclei -update-templates &> /dev/null || echo -e "${YELLOW}[*]${NORMAL} Failed to update nuclei templates"
    fi
}

# Install Tools
main(){
    debug_log "Starting installation..."
    
    # Create a log file
    LOG_FILE="/tmp/webcopilot_install_$(date +%Y%m%d_%H%M%S).log"
    exec 1> >(tee -a "$LOG_FILE") 2>&1
    
    echo -e "${LCYAN}[*]${NORMAL} Installing Tools"
    echo -e "${LCYAN}[*]${NORMAL} Log file: $LOG_FILE"
    
    dirs
    
    # Temporarily disable exit on error for these commands
    set +e
    
    update_system
    dependencies
    python_tools
    wordlists
    go_tools
    configs
    
    # Re-enable exit on error
    set -e
    
    echo -e "${GREEN}[*]${NORMAL} All Tools are installed successfully"
    echo -e "${LCYAN}[*]${NORMAL} Installation log saved to: $LOG_FILE"
    
    # Try to run webcopilot -h but don't fail if it's not found
    webcopilot -h 2> /dev/null || echo -e "${YELLOW}[*]${NORMAL} webcopilot command not found, you may need to restart your shell"
}

# Check if we're being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
    exit 0
fi
