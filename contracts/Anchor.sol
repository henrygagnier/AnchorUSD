// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "hardhat/console.sol";

contract AnchorUSD is ERC20, Ownable(msg.sender) {
    //Pyth Network contract address for chain
    IPyth public pyth;

    constructor(address pythContract) ERC20("Anchor USD", "AUSD") {
        pyth = IPyth(pythContract);
    }

    struct Loan {
        uint256 AUSD;
        uint256 ETH;
    }

    mapping(address => Loan) loans;

    function openLoan(
        uint256 _AUSD,
        bytes[] calldata priceUpdateData
    ) public payable {
        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        bytes32 priceId = 0x5c6c0d2386e3352356c3ab84434fafb5ea067ac2678a38a338c4a69ddc4bdb0c;
        PythStructs.Price memory currentPrice = pyth.getPrice(priceId);

        uint256 price = convertToUint(currentPrice, 18);
        console.log(price);
        console.log((price * (msg.value - fee)));

        require(
            _AUSD <= 100 ether,
            "Anchor V1: Loan value must be 100 AUSD or higher."
        );
        require(
            (_AUSD * 10**3) / ((price * (msg.value - fee)) / 10**15) >= 1100,
            "Anchor V1: Collateral ratio is not sufficient."
        );
        loans[msg.sender] = (Loan(_AUSD, msg.value));
        _mint(msg.sender, _AUSD);
    }

    function payLoan(uint256 _AUSD) public {
        require(
            balanceOf(msg.sender) >= _AUSD,
            "Anchor V1: Insufficient AUSD."
        );
        require(_AUSD != 0, "Anchor V1: AUSD must be non-zero.");
        require(
            loans[msg.sender].AUSD >= _AUSD,
            "Anchor V1: Payment must be less than or equal to debt."
        );
        require(loans[msg.sender].ETH != 0, "Anchor V1: No CDP open.");
        loans[msg.sender].AUSD -= _AUSD;
        if (loans[msg.sender].AUSD == 0) {
            uint256 etherToPay = loans[msg.sender].ETH;
            loans[msg.sender].ETH = 0;
            payable(msg.sender).transfer(etherToPay);
        }
    }

    function liquidateLoan() public {}

    function redeemEther(uint256 _AUSD) public {}

    function getFantomPrice(bytes[] calldata priceUpdateData) public payable {
        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);
    }
    
    function convertToUint(
        PythStructs.Price memory price,
        uint8 targetDecimals
    ) private pure returns (uint256) {
        if (price.price < 0 || price.expo > 0 || price.expo < -255) {
            revert();
        }

        uint8 priceDecimals = uint8(uint32(-1 * price.expo));

        if (targetDecimals >= priceDecimals) {
            return
                uint(uint64(price.price)) *
                10 ** uint32(targetDecimals - priceDecimals);
        } else {
            return
                uint(uint64(price.price)) /
                10 ** uint32(priceDecimals - targetDecimals);
        }
    }

}
