// SPDX-License-Identifier: MIT
// Author: CHFTY, developed by BlockStop

pragma solidity ^0.8.10;

import "./ERC721Enum.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ChftyTest is ERC721Enum, Ownable, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    bool public paused = false;
    string public baseTokenURI;
    uint256 public maxMint = 3;
	uint256 private price = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 25;
    mapping(address => uint256) private _allowList;

	//share settings
	address[] private addressList = [
	0x55c0f20123862aD1F6C1B235D06cCb5ebBe97414,
	0x320866337fEBaC0414E54bA5e70453C912BB5124
	];
	uint[] private shareList = [20,80];

	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) ERC721P(_name, _symbol)
	PaymentSplitter( addressList, shareList ){
	setBaseURI(_initBaseURI);
	}

    // public mint function
	function mint(uint256 _mintAmount) public payable nonReentrant{
        uint256 s = totalSupply();
        require(saleIsActive, "Public sale is not active");
        require(!paused);
        require(_mintAmount > 0, "Must mint more than 0" );
        require(_mintAmount <= maxMint, "Too many, please mint less" );
        require(s + _mintAmount <= MAX_SUPPLY, "Purchase would exceed max token supply" );
        require(msg.value >= price * _mintAmount, "Ether value sent is not correct" );
        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
	}

    //presale mint function
    function mintPresale(uint256 _mintAmount) public payable {
        require(!paused, "Mint is paused");
        require(isAllowListActive, "Allow list is not active");
        uint256 s = totalSupply();
        uint256 reserve = _allowList[msg.sender];
        require(!saleIsActive, "Public Sale is active, wrong function");
        require(reserve > 0, "Low reserve");
        require(_mintAmount <= reserve, "Try minting less");
        require(s + _mintAmount <= MAX_SUPPLY, "Purchase would exceed max token supply" );
        require(msg.value >= price * _mintAmount, "Ether value sent is not correct" );

        _allowList[msg.sender] = reserve - _mintAmount;
        delete reserve;
        for(uint256 i; i < _mintAmount; i++){
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
	}

    //admin reserve minting
	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
        require(quantity.length == recipient.length, "Provide quantities and recipients" );
        uint totalQuantity = 0;
        uint256 s = totalSupply();
        for(uint i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
        }
        require( s + totalQuantity <= MAX_SUPPLY, "Minting amount would exceed max token supply" );
        delete totalQuantity;
        for(uint i = 0; i < recipient.length; ++i){
            for(uint j = 0; j < quantity[i]; ++j){
                _safeMint( recipient[i], s++, "" );
            }
        }
        delete s;	
	}

    //set URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
	    baseTokenURI = _newBaseURI;
	}
	// internal view URI
	function _baseURI() internal view virtual returns (string memory) {
	return baseTokenURI;
	}
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
    //set WL address array
    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }
	//price switch
	function setPrice(uint256 _newPrice) public onlyOwner {
	    price = _newPrice;
	}
    //pause the minting if needed
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    //on / off switch for public sale
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    //on / off switch for presale
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }
    //withdraw funds
	function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
	}
}