pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract StorageV0 is Ownable {

    // maps functions to the delegate contracts that execute the functions
    // funcId => delegate contract
    mapping(bytes4 => address) internal delegates;

    // array of function signatures supported by the contract
    bytes[] internal funcSignatures;

    // maps each function signature to its position in the funcSignatures array.
    // signature => index+1
    mapping(bytes => uint256) internal funcSignatureToIndex;

}