#!/bin/bash

# Check if script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root user privileges."
    echo "Please try using 'sudo -i' command to switch to root user and run this script again."
    exit 1
fi


function install_node() {

# Update the system and install necessary packages
echo "Update system packages..."
sudo apt update && sudo apt upgrade -y
echo "Install necessary tools and dependencies..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

# Install Rust and Cargo
echo "Installing Rust and Cargo..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# Install Solana CLI
echo "Installing Solana CLI..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

# Check if solana-keygen is in PATH
if ! command -v solana-keygen &> /dev/null; then
    echo "Add Solana CLI to PATH"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    export PATH="$HOME/.cargo/bin:$PATH"
    

fi

# Create a Solana key pair
echo "Creating Solana key pair..."
solana-keygen new --derivation-path m/44'/501'/0'/0' --force | tee solana-keygen-output.txt

# Display a prompt message asking the user to confirm that the backup has been made
echo "Please make sure you have backed up the mnemonic phrase and private key information shown above."
echo "Please recharge sol assets to pubkey to use for mining gas costs."

echo "Once the backup is complete, enter 'yes' to continue："

read -p "" user_confirmation

if [[ "$user_confirmation" == "yes" ]]; then
    echo "Confirm backup. Continue executing the script..."
else
    echo "The script terminates. Please make sure to back up your information before running the script."
    exit 1
fi

# Install Ore CLI
echo "Installing Ore CLI..."
cargo install ore-cli

# Check and add Solana's path to .bashrc if it hasn't been added yet
grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# Check and add Cargo's path to .bashrc if it hasn't been added yet
grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# Make changes effective
source ~/.bashrc

# Get the RPC address entered by the user or use the default address
read -p "Please enter a custom RPC address. It is recommended to use the free Quicknode or alchemy SOL rpc (the default setting is https://api.mainnet-beta.solana.com): " custom_rpc
RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

# Get the number of threads entered by the user or use the default value
read -p "Please enter the number of threads to use when mining (default setting 4): " custom_threads
THREADS=${custom_threads:-4}

# Get the priority fee entered by the user or use the default value
read -p "Please enter a priority fee for the transaction (default setting 1): " custom_priority_fee
PRIORITY_FEE=${custom_priority_fee:-1}

# Start mining using screen and Ore CLI
session_name="ore"
echo "Start mining, the session name is $session_name ..."

start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'The process exited abnormally and is waiting to be restarted.' >&2; sleep 1; done"
screen -dmS "$session_name" bash -c "$start"

echo "Mining Running in $session_name of screen Started in the background during a session."
echo "Use 'screen -r $session_name' command to reconnect to this session."

}

# Check node synchronization status
# Restore Solana wallet and start mining
function export_wallet() {
    # 更新系统和安装必要的包
    echo "Update system packages..."
    sudo apt update && sudo apt upgrade -y
    echo "Install necessary tools and dependencies..."
    sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
    check_and_install_dependencies
    
    echo "Restoring Solana wallet..."
    # Prompt user to enter mnemonic phrase
    echo "Please paste/enter your mnemonic words below, separated by spaces. Braille will not be displayed."

    # Restore wallet using mnemonic phrase
    solana-keygen recover 'prompt:?key=0/0' --force

    echo "Wallet has been restored."
    echo "Please make sure your wallet address has sufficient SOL for transaction fees."

# Check and add Solana's path to .bashrc if it hasn't been added yet
grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# Check and add Cargo's path to .bashrc if it hasn't been added yet
grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# Make changes effective
source ~/.bashrc


    # Get the RPC address entered by the user or use the default address
    read -p "Please enter a custom RPC address. It is recommended to use the free Quicknode or alchemy SOL rpc (the default setting is https://api.mainnet-beta.solana.com): " custom_rpc
    RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

    # Get the number of threads entered by the user or use the default value
    read -p "Please enter the number of threads to use when mining (default setting 4): " custom_threads
    THREADS=${custom_threads:-4}

    # Get the priority fee entered by the user or use the default value
    read -p "Please enter a priority fee for the transaction (default setting 1): " custom_priority_fee
    PRIORITY_FEE=${custom_priority_fee:-1}

    # Start mining using screen and Ore CLI
    session_name="ore"
    echo "Start mining, the session name is $session_name ..."

    start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'The process exited abnormally and is waiting to be restarted.' >&2; sleep 1; done"
    screen -dmS "$session_name" bash -c "$start"

    echo "Mining Running in $session_name of screen Started in the background during a session."
    echo "Use 'screen -r $session_name' command to reconnect to this session."
}

function check_and_install_dependencies() {
    # Check if Rust and Cargo are installed
    if ! command -v cargo &> /dev/null; then
        echo "Rust and Cargo are not installed, installing..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source $HOME/.cargo/env
    else
        echo "Rust and Cargo are installed."
    fi

    # Check if Solana CLI is installed
    if ! command -v solana-keygen &> /dev/null; then
        echo "Solana CLI is not installed, installing..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    else
        echo "Solana CLI are installed."
    fi

    # Check if it is installed Ore CLI
if ! ore -V &> /dev/null; then
    echo "Ore CLI Not installed, installing..."
    cargo install ore-cli
else
    echo "Ore CLI Installed."
fi

        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
}

function start() {
# Get the RPC address entered by the user or use the default address
read -p "Please enter a custom RPC address. It is recommended to use the free Quicknode or alchemy SOL rpc (the default setting is https://api.mainnet-beta.solana.com): " custom_rpc
RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

# Get the number of threads entered by the user or use the default value
read -p "Please enter the number of threads to use when mining (default setting 4): " custom_threads
THREADS=${custom_threads:-4}

# Get the priority fee entered by the user or use the default value
read -p "Please enter a priority fee for the transaction (default setting 1): " custom_priority_fee
PRIORITY_FEE=${custom_priority_fee:-1}

# Start mining using screen and Ore CLI
session_name="ore"
echo "Start mining, the session name is $session_name ..."

start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo '进程异常退出，等待重启' >&2; sleep 1; done"
screen -dmS "$session_name" bash -c "$start"

echo "Mining Running in $session_name of screen Started in the background during a session."
echo "Use 'screen -r $session_name' command to reconnect to this session."

}


# 查询奖励
function view_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json rewards
}

# 领取奖励
function claim_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json claim
}


function check_logs() {
    screen -r ore
}


function multiple() {
#!/bin/bash

echo "Update system packages..."
sudo apt update && sudo apt upgrade -y
echo "Install necessary tools and dependencies..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
check_and_install_dependencies
    

# Prompts user for RPC configuration address
read -p "Please enter the RPC configuration address: " rpc_address

# User enters the number of wallet profiles to generate
read -p "Please enter the number of wallets you want to run: " count

# Base session name
session_base_name="ore"

# Start the command template and use variables to replace the rpc address
start_command_template="while true; do ore --rpc $rpc_address --keypair ~/.config/solana/ore/idX.json --priority-fee 20000000 mine --threads 4; echo 'The process exited abnormally and is waiting to be restarted.' >&2; sleep 1; done"

# Make sure the .solana directory exists
mkdir -p ~/.config/solana

# Loop through creating configuration files and starting the mining process
for (( i=1; i<=count; i++ ))
do
    # Prompt user for private key
    echo "for id${i}.json Enter the private key (format is a JSON array of 64 numbers):"
    read -p "Private key: " private_key

    # Generate configuration file path
    config_file=~/.config/solana/ore/id${i}.json

    # Directly write the private key to the configuration file
    echo $private_key > $config_file

    # Check whether the configuration file is successfully created
    if [ ! -f $config_file ]; then
        echo "create id${i}.json Failed, please check if the private key is correct and try again."
        exit 1
    fi

    # Generate session name
    session_name="${session_base_name}_${i}"

    # Replace the configuration file name and RPC address in the startup command
    start_command=${start_command_template//idX/id${i}}

    # Print start information
    echo "Start mining, the session name is $session_name ..."

    # Use screen to start the mining process in the background
    screen -dmS "$session_name" bash -c "$start_command"

    # Print mining process startup information
    echo "Mining Running in $session_name of screen Started in the background during a session."
    echo "Use 'screen -r $session_name' command to reconnect to this session."
done

}

function check_multiple() {
# 提示用户同时输入起始和结束编号，用空格分隔
echo -n "Silakan masukkan angka awal dan akhir, dipisahkan dengan spasi. Misalnya, jika Anda menjalankan 10 alamat dompet, masukkan 1 10:"
read -a range

# 获取起始和结束编号
start=${range[0]}
end=${range[1]}

# Execute loop
for i in $(seq $start $end); do
  ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id$i.json --priority-fee 1 rewards
done

}

# main menu
function main_menu() {
    while true; do
        clear
        echo "Untuk keluar dari script, silahkan tekan ctrl c pada keyboard untuk keluar."
        echo "Silakan pilih tindakan yang akan dilakukan:"
        echo "1. Install a new node (there is a bug in the new wallet derivation of solanakeygen, so it is not highly recommended. The priority is to use function 7 to import the private key)"
        echo "2. Impor dompet dan jalankan"
        echo "3. Mulai dan jalankan sendiri"
        echo "4. Check Mining Rewards"
        echo "5. Claim Mining Rewards"
        echo "6. Periksa status node"
        echo "7. Untuk membuka banyak dompet di satu komputer, Anda perlu menyiapkan sendiri kunci pribadi json."
        echo "8. Buka beberapa dompet di satu mesin untuk melihat hadiah"
        read -p "Silakan masukkan opsi (1-7): " OPTION

        case $OPTION in
        1) install_node ;;
        2) export_wallet ;;
        3) start ;;
        4) view_rewards ;;
        5) claim_rewards ;;
        6) check_logs ;;
        7) multiple ;; 
        8) check_multiple ;; 
        esac
        echo "Pencet tombol apa saja untuk kembali..."
        read -n 1
    done
}

# Show main menu
main_menu