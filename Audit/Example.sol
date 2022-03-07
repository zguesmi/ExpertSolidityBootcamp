	// SPDX-License-Identifier: MIT
	pragma solidity ^0.8.4;
	import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

	contract DogCoinGame is ERC20 {
		
        uint public currentPrize;
        uint256 public numberPlayers;
        address payable [] public players;
        address payable [] public winners;
        

        event startPayout();

       constructor() ERC20("DogCoin", "DOG") {

       }

         function addPlayer (address payable _player) payable public {
             if(msg.value==1){
                players.push(_player);
             }
             numberPlayers++;
             if(numberPlayers > 200 ) {
                emit startPayout();
             }
         } 

        function addWinner(address payable _winner) public {
            winners.push(_winner);
        }

        function payout() public {
            if(address(this).balance == 100) {
                uint amountToPay = winners.length / 100;
                payWinners(amountToPay);
            }
        }

        function payWinners(uint _amount) public {
            for (uint i = 0;i <= winners.length; i++ ){
                winners[i].send(_amount);
            }

        }

	}