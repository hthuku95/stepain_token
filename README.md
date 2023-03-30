# stepain_token
## BEP20 Token Contract for BSC. Includes Anti-Whale, Anti-Bot, Auto-Burn and Staking 
Created as a freelance project
## Prerequisites

Please install or have installed the following:

- [nodejs and npm](https://nodejs.org/en/download/)
- [python](https://www.python.org/downloads/)
## Installation

1. [Install Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html), if you haven't already. Here is a simple way to install brownie.

```bash
pip install eth-brownie
```
Or, if that doesn't work, via pipx
```bash
pip install --user pipx
pipx ensurepath
# restart your terminal
pipx install eth-brownie
```

2. [Install ganache-cli](https://www.npmjs.com/package/ganache-cli)

```bash
npm install -g ganache-cli
```

## Quickstart


1. Clone this repo

```bash
git clone https://github.com/hthuku95/stepain_token.git
```

2. Run a script

```
brownie run scripts/deploy_token.py
```

Interact with the contract on [bscscan](https://testnet.bscscan.com/address/0xF2d8A812aca84D69aDc8FE55E753A66d41d01534)
