from brownie import Staking, network, config
from scripts.helpful_scripts import get_account
from web3 import Web3

def main():
    account = get_account()
    staking_contract = Staking.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False)
    )
    print(staking_contract.name())