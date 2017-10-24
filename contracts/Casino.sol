pragma solidity ^0.4.11;
// A casino like application where users are able to bet money for a number between 1 and 10 and if they’re correct, 
// they win a portion of all the ether money staked after 100 bets.
contract Casino {
    address owner;

    uint minimumBet;
    uint totalBet;
    uint numberOfBets;
    uint maxAmountOfBets = 100;
    mapping (address => Player) playerInfo;

    // We want to have a array of players to know who is playing the game
    address[] players;

    function Casino(uint _minimumBet) {
        owner = msg.sender;
        // Define the minimum bet for the game;
        if(_minimumBet != 0) minimumBet = _minimumBet;
    }

    // The player struct has an address, the amountBet and the number selected.
    struct Player {
        uint amountBet;
        uint numberSelected;
    }

    // To bet for a number between 1 and 10 both inclusive
    // in order to execute this function you must pay ether.
    function bet(uint _number) payable {
        // Abort execution and revert state changes if any condition is false
        assert(checkPlayerExists(msg.sender) == false);
        assert(_number >= 1 && _number <= 10);
        assert(msg.value >= minimumBet);

        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].numberSelected = _number;
        numberOfBets += 1;
        players.push(msg.sender);
        totalBet += msg.value;
        if(numberOfBets >= maxAmountOfBets) generateNumberWinner();
    }

    function checkPlayerExists(address _player) constant returns (bool) {
        for(uint i = 0; i < players.length; i++){
            if(players[i] == _player) return true;
        }
        return false;
    }

    // This function generates a number between 1 and 10 to decide the winner
    function generateNumberWinner(){
        uint numberGenerated = block.number % 10 + 1;
        distributePrizes(numberGenerated);
    }

    // Sends the corresponding ether to eac winner depending on the total bets
    function distributePrizes(uint numberWinner) {
        address[100] memory winners; // We have to create a temporary in memory array with fixed size
        // The count for the array of winners
        uint count = 0;
        for(uint i = 0; i < players.length; i++){
            address playerAddress = players[i];
            if(playerInfo[playerAddress].numberSelected == numberWinner) {
                winners[count] = playerAddress;
                count++;
            }
            // Delete all the players array
            delete playerInfo[playerAddress];
        }
        players.length = 0; // Delete all the players array

        // How much each winner gets
        uint winnerEtherAmount = totalBet / winners.length;

        for(uint j = 0; j < count; j++) {
            if(winners[j] != address(0)) // Check that the address in this fixed array is not empty
                winners[j].transfer(winnerEtherAmount);
        }
        resetData();
    }

    function resetData(){
        players.length = 0; // Delete all the players array
        totalBet = 0;
        numberOfBets = 0;
    }

    function kill() {
        if(msg.sender == owner)
            selfdestruct(owner);
    }

    // Fallback function in case someone sends ether to the contract so it doesn't get lost
    function() payable {}
}