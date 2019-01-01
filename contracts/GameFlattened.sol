pragma solidity ^0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/IColor.sol

interface Color {
    function totalSupply() external view returns (uint);
    function ownerOf(uint _tokenId) external view returns (address);
}

// File: contracts/Roles.sol

contract Roles is Ownable {
    
    mapping(address => bool) public isAdmin;
    
    constructor() internal {
        isAdmin[msg.sender] = true;
    }
    
    function addAdmin(address _new) external onlyOwner {
        isAdmin[_new] = true;
    }
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "You don't have admin privilegues");
        _;
    }
    
    function removeAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = false;
    }

    function renounceAdmin() external onlyAdmin {
        isAdmin[msg.sender] = false;
    }
}

// File: contracts/DividendsDistributor.sol

contract DividendsDistributor is Roles {
    
    using SafeMath for uint;
    
    // Color color = Color(0x7899946bc29f3ab7443903bcc03e8a38407bb44a);
    
    mapping (uint => address) public ownerOfColor;
    
    constructor() {

        // for (uint i = 1; i < color.totalSupply(); i++) {
        //     ownerOfColor[i] = color.ownerOf(i);
        // }0xbF0e4036BF968dD007F9B4A1BFdA4e54C042F612

        for (uint i = 1; i <= 8; i++) {
            ownerOfColor[i] = 0xbF0e4036BF968dD007F9B4A1BFdA4e54C042F612;
        }
    }
    
    //балансы доступные для вывода (накопленный пассивный доход за все раунды)
    mapping (address => uint) public withdrawalBalances; 
    
    //время последнего вывода пассивного дохода для адреса для любого раунда (адрес => время)
    mapping (address => uint) addressToLastWithdrawalTime; 
    
    //банк пассивных доходов
    uint public dividendsBank;
    
    event DividendsWithdrawn(address indexed withdrawer, uint indexed claimId, uint indexed amount);
    event DividendsClaimed(address indexed claimer, uint indexed claimId, uint indexed currentTime);

    struct Claim {
        uint id;
        address claimer;
        bool isResolved;
        uint timestamp;
    }

    uint public claimId;
    Claim[] public claims;
  
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

     // захардкоженные адреса для тестирования функции claimDividens()
    // в продакшене это будут адреса бенефециариев Цветов и Пикселей : withdrawalBalances[ownerOf(_pixel)], withdrawalBalances[ownerOf(_color)]
    //address public ownerOfColor = 0xf106a93c5ca900bfae6345b61fcfae9d75cb031d;
    address public ownerOfPixel = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    address public founders = 0x3e4d187df7d8a0820eaf4174d17b160157610912;
   
    //функция распределения дивидендов (пассивных доходов) - будет работать после подключения инстансов контрактов Цвета и Пикселя
    function _distributeDividends(uint _color) internal {
        
        //require(ownerOfColor[_color] != address(0), "There is no such color");

        //25% дивидендов распределяем организаторам (может быть смарт контракт)
        withdrawalBalances[founders] = withdrawalBalances[founders].add(dividendsBank.mul(25).div(100)); 
    
        //25% дивидендов распределяем бенефециарию цвета
        withdrawalBalances[ownerOfColor[_color]] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем бенефециарию пикселя
        withdrawalBalances[ownerOfPixel] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем реферреру, если он есть
        // withdrawalBalances[referrer] += dividendsBank.mul(25).div(100);
    }
}

// File: contracts/Storage.sol

contract Storage {

    //цвет клетки в раунде (pаунд => пиксель => цвет)
    mapping (uint => mapping (uint => uint)) public pixelToColorForRound; 

    //предыдущий цвет клетки в раунде (pаунд => пиксель => цвет)
    mapping (uint => mapping (uint => uint)) public pixelToOldColorForRound; 

    //маппинг цвета на количество клеток закрашенных этим цветом за раунд (раунд => цвет => количество пикселей)
    mapping (uint => mapping (uint => uint)) public colorToPaintedPixelsAmountForRound; 

    //банк цвета за раунд (раунд => банк цвета)
    mapping (uint => uint) public colorBankForRound; 

    //банк цвета для отдельного цвета за раунд (раунд => цвет => банк цвета)
    mapping (uint => mapping (uint => uint)) public colorBankToColorForRound; 

    //банк времени за раунд (раунд => банк времени)
    mapping (uint => uint) public timeBankForRound; 
    
    //время самого последнего закрашивания игрового поля за раунд (раунд => таймстэмп)
    mapping (uint => uint) public lastPaintTimeForRound; 

    //последний закрасивший любой пиксель пользователь за раунд (раунд => адрес)
    mapping (uint => address) public lastPainterForRound; 

    //последний разукрашенный пиксель за раунд
    mapping (uint => uint) public lastPaintedPixelForRound;

    //цвет который выиграл (которым заполнились все пиксели) за раунд (раунд => цвет) 
    mapping (uint => uint) public winnerColorForRound; 

    //значение общего количества разукрашиваний данным цветом за весь раунд (раунд => цвет => количество разукрашиваний)
    mapping (uint => mapping (uint => uint)) public colorToTotalPaintsForRound; 

    //победитель раунда (раунд => адрес)
    mapping (uint => address) public winnerOfRound; 

    //банк который был разыгран в раунде (раунд => разыгранный банк) (1 = банк времени, 2 = банк цвета)
    mapping (uint => uint) public winnerBankForRound; 

    //время закрашивания для каждого пикселя за раунд (0 = не закрашено)
    mapping (uint => mapping (uint => uint)) public pixelToPaintTimeForRound;

    //текущий раунд
    uint public currentRound;

    //сколько всего было разукрашиваний в этом раунде любым цветом
    mapping (uint => uint) public totalPaintsForRound;
        
     //поколение краски на ее количество
    mapping (uint => mapping (uint => uint)) public paintGenToAmountForColor;
    
    //время когда краска определенного поколения добавилась в пул
    mapping (uint => mapping (uint => uint)) public paintGenToStartTimeForColor;
    
    //время когда краска определенного поколения закончилась в пуле
    mapping (uint => mapping (uint => uint)) public paintGenToEndTimeForColor;
    
    //булевое значение - о том что, поколение краски началось
    mapping (uint => mapping (uint => bool)) public paintGenStartedForColor;

    //текущее поколение краски которое расходуется в данный момент
    mapping (uint => uint) public currentPaintGenForColor;
    
    //стоимость вызова функции paint
    mapping (uint => uint) public callPriceForColor;
    
    //стоимость следующего вызова функции paint
    mapping (uint => uint) public nextCallPriceForColor;
    
    //количество единиц краски в общем пуле (10000)
    uint public maxPaintsInPool;



    uint public tbIteration;
    uint public cbIteration;
    uint public paintsCounter; //счетчик закрашиваний любым цветом за все время
    //Time Bank Iteration => Painter => Painter's Share in Time Team
    mapping (uint => mapping (address => uint)) public timeBankShare;
    //Color Bank Iteration => Color => Painter => Painter's Share in Time Team
    mapping (uint => mapping (uint => mapping (address => uint))) public colorBankShare;
    mapping (uint => uint) public paintsCounterForColor; //счетчик закрашиваний конкретным цветом за все время
    mapping (uint => address[]) public cbTeam; //for cbIteration
    mapping (uint => address[]) public tbTeam; //for tbIteration
    mapping (uint => address) public counterToPainter; //cчетчик => пользователь
    mapping (uint => mapping (uint => address)) public counterToPainterForColor; //цвет => cчетчик => пользователь    
    mapping (uint => mapping (address => bool)) public isInCBT; //for cbIteration !should not be public
    mapping (uint => mapping (address => bool)) public isInTBT; //for tbIteration !should not be public
    mapping (uint => mapping (address => uint)) public painterToCBP; //cbIteration => painter => color bank prize
    mapping (uint => mapping (address => uint)) public painterToTBP; //tbIteration => painter => time bank prize

    mapping (uint => bool) public isCBPTransfered;
    mapping (uint => bool) public isTBPTransfered;

}

// File: contracts/GameStateController.sol

contract GameStateController is Roles {

    bool public isGamePaused;

    modifier isLiveGame() {
        require(isGamePaused == false, "Game is paused");
        _;
    }

    function pauseGame() external onlyAdmin {
        require (isGamePaused == false, "Game is already paused");
        isGamePaused = true;
    }

    function resumeGame() external onlyAdmin {
        require (isGamePaused == true, "Game is already live");
        isGamePaused = false;
    }
}

// File: contracts/TimeTeam.sol

contract TimeTeam is Storage, GameStateController {

    using SafeMath for uint;
    event TBPDistributed(uint indexed round, uint indexed tbIteration, address winner);

    //функция формирующая команду времени из последних 100 участников любым цветом
    function formTimeTeam() private returns (uint) {
        
        for (uint i = paintsCounter; i > 0; i--) {
            uint teamMembersCounter;
            if (isInTBT[tbIteration][counterToPainter[i]] == false) {
                
                if (paintsCounter > 100) {
                    if (teamMembersCounter >= 100)   
                        break;
                }
            
                else {
                    if (teamMembersCounter >= paintsCounter)
                        break;
                }
                
                tbTeam[tbIteration].push(counterToPainter[i]);
                teamMembersCounter = teamMembersCounter.add(1);
                isInTBT[tbIteration][counterToPainter[i]] = true;
            }
        }
        return tbTeam[tbIteration].length;
    }
    
    function calculateTBP() private {

        uint length = formTimeTeam();
        address painter;
        uint totalPaintsForTeam; 

        for (uint i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            totalPaintsForTeam += timeBankShare[tbIteration][painter];
        }

        for (i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            painterToTBP[tbIteration][painter] = (timeBankShare[tbIteration][painter].mul(timeBankForRound[currentRound])).div(totalPaintsForTeam);
        }

    }

    function distributeTBP() external onlyAdmin isLiveGame {
        require(isTBPTransfered[tbIteration] == false, "Time Bank Prizes already transferred for this tbIteration");
        address painter;
        calculateTBP();
        uint length = tbTeam[tbIteration].length;
        for (uint i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            if(painterToTBP[tbIteration][painter] != 0)
                painter.transfer(painterToTBP[tbIteration][painter]);
        }
        isTBPTransfered[tbIteration] = true;
        emit TBPDistributed(currentRound, tbIteration, winnerOfRound[currentRound]);
        currentRound = currentRound.add(1); //следующий раунд 
        tbIteration = tbIteration.add(1); //инкрементируем итерацию для банка цвета
    }
}

//TODO по прошествию 20 минут распределить банки времени и цвета для этого и след раундов
//написать тесты
//прокси, логика, бд

// File: contracts/ColorTeam.sol

contract ColorTeam is Storage, GameStateController {

    using SafeMath for uint;
    event CBPDistributed(uint indexed round, uint indexed cbIteration, address winner);

    //функция формирующая команду цвета из последних 100 участников выигрывшим цветом
    function formColorTeam(uint _winnerColor) private returns (uint) {
        
        for (uint i = paintsCounterForColor[_winnerColor]; i > 0; i--) {
            uint teamMembersCounter;
            if (isInCBT[cbIteration][counterToPainterForColor[_winnerColor][i]] == false) {
                
                if (paintsCounterForColor[_winnerColor] > 100) {
                    if (teamMembersCounter >= 100)   
                        break;
                }
            
                else {
                    if (teamMembersCounter >= paintsCounterForColor[_winnerColor])
                        break;
                }
                
                cbTeam[cbIteration].push(counterToPainterForColor[_winnerColor][i]);
                teamMembersCounter = teamMembersCounter.add(1);
                isInCBT[cbIteration][counterToPainterForColor[_winnerColor][i]] = true;
            }
        }
        return cbTeam[cbIteration].length;
    }
    
    function calculateCBP(uint _winnerColor) private {

        uint length = formColorTeam(_winnerColor);
        address painter;
        uint totalPaintsForTeam; //засунуть в функцию calculateCBP

        for (uint i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            totalPaintsForTeam += colorBankShare[cbIteration][_winnerColor][painter];
        }

        for (i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            painterToCBP[cbIteration][painter] = (colorBankShare[cbIteration][_winnerColor][painter].mul(colorBankForRound[currentRound])).div(totalPaintsForTeam);
        }

    }

    function distributeCBP() external onlyAdmin isLiveGame {
        require(isCBPTransfered[cbIteration] == false, "Color Bank Prizes already transferred for this cbIteration");
        address painter;
        calculateCBP(winnerColorForRound[currentRound]);
        uint length = cbTeam[cbIteration].length;
        for (uint i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            if(painterToCBP[cbIteration][painter] != 0)
                painter.transfer(painterToCBP[cbIteration][painter]);
        }
        isCBPTransfered[cbIteration] = true;
        emit CBPDistributed(currentRound, cbIteration, winnerOfRound[currentRound]);
        currentRound = currentRound.add(1); //следующий раунд 
        cbIteration = cbIteration.add(1); //инкрементируем итерацию для банка цвета
    }
}

// File: contracts/PaintsPool.sol

contract PaintsPool is Storage {
    
    using SafeMath for uint;
    
    event CallPriceUpdated(uint indexed newCallPrice);

    //функция обновления цены вызова функции закрашивания (paint)
    function _updateCallPrice(uint _color) private {
        
        //увеличиваем цену вызова на 5% (используем для отображения на фронте)
        nextCallPriceForColor[_color] = callPriceForColor[_color].mul(105).div(100);
        
        //вызываем ивент о том, что цена вызова функции paint обновлена
        emit CallPriceUpdated(callPriceForColor[_color]);
    }
    
    //функция пополнения пула краски
    function _fillPaintsPool(uint _color) internal {
        
        //каждые полторы минуты пул дополняется новой краской
        if (now - paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] >= 1.5 minutes) { 
            
            //сколько краски остается в поколении
            uint paintsRemain = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]]; 
            
            //следующее поколение краски
            uint nextPaintGen = currentPaintGenForColor[_color].add(1); 
            
            //если прошло полторы минуты и след. поколение краски все еще не создано     
            if (paintGenStartedForColor[_color][nextPaintGen] == false) {
                
                //создаем новое поколение краски на недостающее количество единиц
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool.sub(paintsRemain); 
                
                //новое поколение создалось сейчас
                paintGenToStartTimeForColor[_color][nextPaintGen] = now; 

                paintGenStartedForColor[_color][nextPaintGen] = true;
            }
            
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 1) {
                
                //обновляем цену вызова закрашивания краской следующего поколения
                _updateCallPrice(_color);
                
                //краска текущего поколения закончилась сейчас
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color]] = now;
            }
               
            //как только не осталось краски текущего поколения
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
                
                //цена вызова закрашивания краской текущего поколения
                callPriceForColor[_color] = nextCallPriceForColor[_color];

                //переходим на использование следующего поколения краски
                currentPaintGenForColor[_color] = nextPaintGen;
            }
        }
    }
}

// File: contracts/PaintDiscount.sol

contract PaintDiscount  {
    
    using SafeMath for uint;
    
    //общее количество денег потраченных пользователем на покупку краски данного цвета
    mapping (uint => mapping (address => uint)) public moneySpentByUserForColor;
    
    //маппинг хранящий булевое значение о том, имеет ли пользователь какую либо скидку на покупку краски определенного цвета
    mapping (uint => mapping (address => bool)) public hasPaintDiscountForColor;
    
    //скидка пользователя на покупку краски определенного цвета (в процентах)
    mapping (uint => mapping (address => uint)) public usersPaintDiscountForColor;
    
    //функция сохраняющая скидку на покупку краски определенного цвета для пользователя
    function _setUsersPaintDiscountForColor(uint _color) internal {
        
        //за каждый потраченный 1 ETH даем скидку 1%
        usersPaintDiscountForColor[_color][msg.sender] = moneySpentByUserForColor[_color][msg.sender] / 1 ether;
        
        //максимальная скидка может равняться 10%
        if (moneySpentByUserForColor[_color][msg.sender] >= 10 ether)
            usersPaintDiscountForColor[_color][msg.sender] = 10;
        
    }
    
    //функция сохраняющая общюю сумму потраченную пользователем на покупку краски определенного цвета за все время
    function _setMoneySpentByUserForColor(uint _color) internal {
        
        moneySpentByUserForColor[_color][msg.sender] += msg.value;

        if (moneySpentByUserForColor[_color][msg.sender] >= 1 ether)
            hasPaintDiscountForColor[_color][msg.sender] = true;
    }
    

    
}

// File: contracts/Game.sol

contract Game is Ownable, TimeTeam, ColorTeam, PaintsPool, PaintDiscount, DividendsDistributor {

    using SafeMath for uint;
    
    //последний раунд в котором пользователь принимал участие (аgit дрес => раунд)
    mapping (address => uint) public lastPlayedRound; 

    //общее количество уникальных пользователей
    uint public uniqueUsers;

    //маппинг на булевое значение о том, что пользователь зарегистрирован в системе (принимал участие в игре)
    mapping (address => bool) public isRegistered;
    
    //ивенты
    event Paint(uint indexed pixelId, uint colorId, address indexed painter, uint indexed round, uint timestamp);
    event ColorBankPlayed(address winner, uint indexed round);
    event TimeBankPlayed(address winner, uint indexed round);
   
    //конструктор, задающий изначальные значения переменных
    constructor() public payable { 
        
        maxPaintsInPool = 10000; //10000 in production
        currentRound = 1;
        cbIteration = 1;
        tbIteration = 1;
        
        for (uint i = 1; i <= 3; i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 0.01 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
            paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
            
            //если ни одна единица краски еще не потрачена
            if (totalPaintsForRound[currentRound] == 0) {
                paintGenToEndTimeForColor[i][currentPaintGenForColor[i] - 1] = now;
            }
            
            paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
        }
        
    }
    
    function hardCode() external {
        timeBankForRound[currentRound] = 1 ether;
        colorBankForRound[currentRound] = 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = 9998; 
    }
    
    //возвращает цвет пикселя в этом раунде
    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }
    
    modifier isRegisteredUser() {
        //если пользоваель ни разу не принимал участие в игре, инкрементируем значение уникальных пользователй
        if (isRegistered[msg.sender] == false) {
            isRegistered[msg.sender] = true;
            uniqueUsers = uniqueUsers.add(1);
        }
        _;
    }        
    
    //функция оценивающая сколько будет стоить функция закрашивания
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint) {
        
        uint price;
        uint discount;
        uint discountCallPrice;
        uint moneySpent;
        uint totalCallPrice;
        bool hasDiscount;
        

        moneySpent = moneySpentByUserForColor[_color][msg.sender];
        hasDiscount = hasPaintDiscountForColor[_color][msg.sender];
        discount = usersPaintDiscountForColor[_color][msg.sender];
       
        
        for (uint i = 0; i < _pixels.length; i++) {
            
            discountCallPrice = (nextCallPriceForColor[_color].mul(100 - discount)).div(100);
            
            if (hasDiscount == true) 
                price = discountCallPrice;
            else
                price = nextCallPriceForColor[_color]; 

            totalCallPrice += price;
            moneySpent += price;

            if (moneySpent >= 1 ether) {
                
                hasDiscount = true;
                discount = moneySpent / 1 ether;
                
                if (moneySpent >= 10 ether)
                    discount = 10;
            }
            
        }   
        
        return totalCallPrice;
    }
    

    function paint(uint[] _pixels, uint _color) external payable isRegisteredUser isLiveGame {

        require(msg.value == estimateCallPrice(_pixels, _color), "Wrong call price");

        //проверяем не прошло ли 20 минут с последней раскраски для розыгрыша банка времени
        if (now - lastPaintTimeForRound[currentRound] > 20 minutes && lastPaintTimeForRound[currentRound] != 0) {

            //распределяем банк времени команде раунда
            //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];

            painterToTBP[tbIteration][winnerOfRound[currentRound]] += timeBankForRound[currentRound].mul(45).div(100); 
            
            //разыгранный банк этого раунда = банк времени (1)
            winnerBankForRound[currentRound] = 1; 
            //10% банка времени переходит в следующий раунд
            timeBankForRound[currentRound + 1] = timeBankForRound[currentRound].div(10); 
            //45% банка времени распределится между всей командой участников раунда
            timeBankForRound[currentRound] = timeBankForRound[currentRound].mul(45).div(100); 
            //банк цвета переносится на следующий раунд
            colorBankForRound[currentRound + 1] = colorBankForRound[currentRound]; 
            //в этом раунде банк цвета обнуляется
            colorBankForRound[currentRound] = 0; 
            //ивент - был разыгран банк времени (победитель, раунд)
            emit TimeBankPlayed(winnerOfRound[currentRound], currentRound);
        }
        
        //закрашиваем пиксели
        for(uint i = 0; i < _pixels.length; i++) {
            _paint(_pixels[i], _color);
        }
        
         //распределяем ставку по банкам
        _setBanks(_color);
            
        //распределяем дивиденды (пассивный доход) бенефециариам
        _distributeDividends(_color);
    
         //сохраняем значение потраченных пользователем денег на покупку краски данного цвета
        _setMoneySpentByUserForColor(_color); 
        
        //сохраняем значение скидки на покупку краски данного цвета для пользователя
        _setUsersPaintDiscountForColor(_color);

        paintsCounter++; //счетчик закрашивания любым цветом
        paintsCounterForColor[_color] ++; //счетчик закрашивания конкретным цветом
        counterToPainter[paintsCounter] = msg.sender; //счетчик закрашивания => пользователь
        counterToPainterForColor[_color][paintsCounterForColor[_color]] = msg.sender; //счетчик закрашивания конкретным цветом => пользователь

    }   

    //функция закрашивания пикселя цветом
    function _paint(uint _pixel, uint _color) internal {

        //устанавливаем значения для краски в пуле и цену вызова функции paint
        _fillPaintsPool(_color);

        require(_pixel != 0, "The pixel with id = 0 does not exist...");
        require(_color != 0, "You cannot paint to transparent color...");
        require(pixelToColorForRound[currentRound][_pixel] != _color, "This pixel is already of this color...");

        //paint    
        //берем предыдущий цвет данного пикселя
        uint oldColor = pixelToColorForRound[currentRound][_pixel];
    
        //перекрашиваем в новый цвет
        pixelToColorForRound[currentRound][_pixel] = _color; 
            
        //cохраняем предыдущий цвет в маппинге
        pixelToOldColorForRound[currentRound][_pixel] = oldColor; 
                
        //время последнего закрашивания во всем игровом поле в этом раунде
        lastPaintTimeForRound[currentRound] = now; 
    
        //самый последний разукрасивший пользователь на всем игровом поле в этом раунде
        lastPainterForRound[currentRound] = msg.sender;
                
        //если счетчик старого цвета положительный, уменьшаем его значение
        if (colorToPaintedPixelsAmountForRound[currentRound][oldColor] > 0) 
            colorToPaintedPixelsAmountForRound[currentRound][oldColor] = colorToPaintedPixelsAmountForRound[currentRound][oldColor].sub(1); 
    
        //при каждой раскраске пикселя, увеличиваем счетчик цвета
        colorToPaintedPixelsAmountForRound[currentRound][_color] = colorToPaintedPixelsAmountForRound[currentRound][_color].add(1); 
    
        //увеличиваем значение общего количества разукрашиваний любым цветом для всего раунда
        totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(1); 

        pixelToPaintTimeForRound[currentRound][_pixel] = now;

        timeBankShare[tbIteration][msg.sender]++;
        colorBankShare[cbIteration][_color][msg.sender]++;
                
        //с каждым закрашиванием декреминтируем на 1 ед краски
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);
        
        //сохраняем значени поседнего закрашенного пикселя за раунд
        lastPaintedPixelForRound[currentRound] = _pixel;
        
        //ивент - закрашивание пикселя (пиксель, цвет, закрасивший пользователь)
        emit Paint(_pixel, _color, msg.sender, currentRound, now);    

        //устанавливаем значение последнего сыгранного раунда для пользователя равным текущему раунду
        lastPlayedRound[msg.sender] = currentRound;
            
        //проверяем не закрасилось ли все игровое поле данным цветом для розыгрыша банка цвета
        if (colorToPaintedPixelsAmountForRound[currentRound][_color] == 10000) {

            //цвет победивший в текущем раунде
            winnerColorForRound[currentRound] = _color;

            //распределяем банк цвета команде цвета
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];        
            painterToCBP[cbIteration][winnerOfRound[currentRound]] += colorBankForRound[currentRound].mul(50).div(100); 
            winnerBankForRound[currentRound] = 2;//разыгранный банк этого раунда = банк цвета (2)
            //50% банка цвета распределится между командой цвета раунда
            colorBankForRound[currentRound] = colorBankForRound[currentRound].mul(50).div(100); 
            timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];//банк времени переносится на следующий раунд
            timeBankForRound[currentRound] = 0;//банк времени в текущем раунде обнуляется      
            emit ColorBankPlayed(winnerOfRound[currentRound], currentRound);  
        }
    }

    //функция распределения ставки
    function _setBanks(uint _color) private {
        
        colorBankToColorForRound[currentRound][_color] = colorBankToColorForRound[currentRound][_color].add(msg.value.mul(40).div(100));

        //40% ставки идет в банк цвета
        colorBankForRound[currentRound] = colorBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //40% ставки идет в банк времени
        timeBankForRound[currentRound] = timeBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //20% ставки идет на пассивные доходы бенефециариев
        dividendsBank = dividendsBank.add(msg.value.mul(20).div(100)); 
    }
    
}
