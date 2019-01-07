pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";
import "./Utils.sol";

contract Referral is Modifiers {
    using SafeMath for uint;
    
    //функция для покупки реферальной ссылки для пользователя (длина в диапазоне от 4 до 8 символов)
    function buyRefLink(string _refLink) isValidRefLink (_refLink) external payable {
        require(msg.value == 0.1 ether, "Setting referral link costs 0.1 ETH");
        require(hasRefLink[msg.sender] == false, "You have already generated your ref link");
        bytes32 refLink = Utils.toBytes32(_refLink);
        require(refLinkExists[refLink] != true, "This referral link already exists, try different one");
        hasRefLink[msg.sender] = true;
        userToRefLink[msg.sender] = _refLink;
        refLinkExists[refLink] = true;
        refLinkToUser[refLink] = msg.sender;
    }
}