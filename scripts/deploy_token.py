from brownie import Stepain, network, config
from scripts.helpful_scripts import get_account
from web3 import Web3

def main():
    account = get_account()
    stepain_token = Stepain.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False)
    )
    print(stepain_token.name())