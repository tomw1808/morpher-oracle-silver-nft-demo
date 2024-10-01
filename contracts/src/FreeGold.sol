// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface OracleEntrypoint {
    function consumeData(
        address _provider,
        bytes32 _dataKey
    ) external payable returns (bytes32);

    function prices(address _provider, bytes32 _dataKey) external view returns(uint256);
}

abstract contract DataDependent {
    struct DataRequirement {
        address provider;
        address requester;
        bytes32 dataKey;
    }
    struct ResponseWithExpenses {
        uint value;
        uint expenses;
    }

    function requirements(
        bytes4 _selector
    ) external virtual view returns (DataRequirement[] memory);

    function _invokeOracle(address oracle, address _provider, bytes32 _key) internal returns (ResponseWithExpenses memory) {
        uint expenses = OracleEntrypoint(oracle).prices(_provider, _key);
        // pay the oracle now, then get the funds later from sender as you wish (eg. deduct from msg.value)
        bytes32 response = OracleEntrypoint(oracle).consumeData{value: expenses}(_provider, _key);
        uint256 asUint = uint256(response);
        uint256 timestamp = asUint >> (26 * 8);
        // in this example we want the price to be fresh
        require(timestamp > 1000 * (block.timestamp - 30), "MorpherOracle-DataDependent: Timestamp too small, data too old, aborting!");
        uint8 decimals = uint8((asUint >> (25 * 8)) - timestamp * (2 ** 8));
        // in this example we expect a response with 18 decimals
        require(decimals == 18, "Oracle response with wrong decimals!");
        uint256 price = uint256(
            asUint - timestamp * (2 ** (26 * 8)) - decimals * (2 ** (25 * 8))
        );
        return ResponseWithExpenses(price, expenses);
    }
}


/// @custom:security-contact thomas @ morpher.com
contract GoldDemo is ERC721, Ownable, DataDependent {
    uint256 private _nextTokenId;
    mapping(uint => uint) tokenPriceInGold;


    address dataProvider = 0x1101184E85D4CAf7DE2357c66e4F052bbc552497; //get this from the Feed page
    address oracle = 0xd4f4baD1Fba15F8B136DBb9A44CE44caa3E92A5A;
    bytes32 MARKET_XAU = keccak256("MORPHER:COMMODITY_XAU");
    bytes32 MARKET_POL = keccak256("MORPHER:CRYPTO_POL");

    constructor(address initialOwner)
        ERC721("GoldDemo", "FXAU")
        Ownable(initialOwner)
    {}

    function safeMint(address to) public payable {
        
        ResponseWithExpenses memory response_xau = _invokeOracle(oracle, dataProvider, MARKET_XAU);
        ResponseWithExpenses memory response_pol = _invokeOracle(oracle, dataProvider, MARKET_POL);
        require(msg.value >= ((response_pol.expenses + response_xau.expenses)) + (response_xau.value * 1e18) / response_pol.value, "Not enough value to pay for XAU plus Oracle Data!");

        uint remainder = uint(msg.value - (((response_pol.expenses + response_xau.expenses)) + (response_xau.value * 1e18) / response_pol.value));
        
        payable(msg.sender).transfer(remainder);

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        //for demonstration purposes, send whatever is in this contract back too
        payable(msg.sender).transfer(address(this).balance);
        
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
         return string.concat(
                "data:application/json;utf8,", 
                '{"name":"Morpher Oracle GoldToken", "description":"Demo to mind one Ounce of Gold at current Prices", "attributes":[{"trait_type": "Purchase Price","value": ',Strings.toString(tokenPriceInGold[tokenId]),'}], "image":"https://oracle.morpher.com/images/gold-image.png", "external_url":"https://oracle.morpher.com"}'); 
    }

     function requirements(bytes4 _selector) external view override returns (DataRequirement[] memory) {
        //each function that needs data needs to be specified here. 
        if (_selector == bytes4(keccak256("safeMint(address)"))) {
            DataRequirement[] memory requirement = new DataRequirement[](2);
            requirement[0] = DataRequirement(dataProvider, address(this), MARKET_XAU);
            requirement[1] = DataRequirement(dataProvider, address(this), MARKET_POL);
            return requirement;
        }
        return new DataRequirement[](0);
    }


}
