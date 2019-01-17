pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./IColor.sol";
import "./Modifiers.sol";

contract DividendsDistributor is Modifiers {
    using SafeMath for uint;

    constructor() {

        // for (uint i = 1; i < color.totalSupply(); i++) {
        //     ownerOfColor[i] = color.ownerOf(i);
        // }0xbF0e4036BF968dD007F9B4A1BFdA4e54C042F612

        for (uint i = 1; i <= 8; i++) {
            ownerOfColor[i] = 0xbF0e4036BF968dD007F9B4A1BFdA4e54C042F612;
        }
    }
    
    function claimDividends() external {
        //функция не может быть вызвана, если баланс для вывода пользователя равен нулю
        require(withdrawalBalances[msg.sender] != 0, "Your withdrawal balance is zero...");
        claimId = claimId.add(1);
        Claim memory c;
        c.id = claimId;
        c.claimer = msg.sender;
        c.isResolved = false;
        c.timestamp = now;
        claims.push(c);
        emit DividendsClaimed(msg.sender, claimId, now);
    }

    function approveClaim(uint _claimId) public onlyAdmin() {
        
        Claim storage claim = claims[_claimId];
        
        require(!claim.isResolved);
        
        address claimer = claim.claimer;

        //Checks-Effects-Interactions pattern
        uint withdrawalAmount = withdrawalBalances[claimer];

        //обнуляем баланс для вывода для пользователя
        withdrawalBalances[claimer] = 0;

        //перевести пользователю баланс для вывода
        claimer.transfer(withdrawalAmount);
        
        //устанавливаем время последнего вывода средств для пользователя
        addressToLastWithdrawalTime[claimer] = now;
        emit DividendsWithdrawn(claimer, _claimId, withdrawalAmount);

        claim.isResolved = true;
    }

}