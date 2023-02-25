// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//for seeing values in console
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage{

    using Counters for Counters.Counter;

    //counter for tokenId and items sold
    Counters.Counter private tokenIds;
    Counters.Counter private itemsSold;

    //set owner
    address payable owner;

    //initialize listing price
    uint listingPrice = 0.0015 ether;

    //tokenId to struct with nft details mapping
    mapping(uint => MarketItem) private idMarketItem;

    //strcut with details of NFT
    struct MarketItem {
        uint tokenId;
        address payable seller;
        address payable owner;
        uint price;
        bool sold;
    }

    //event to see change in the values on chain
    event idMarketItemCreated(

        uint indexed tokenId,
        address seller,
        address owner,
        uint price,
        bool sold
    );

    //modifier for only owner
    modifier onlyOwner{
        require(msg.sender == owner, "Only marketplace owner can change listing price");
        _;
    }

    //constructor to create nft
    constructor() ERC721("NFT Metaverse Token", "MYNFT"){
        
        //set owner
        owner = payable(msg.sender);
    }

    //function to set a lsiting price, ie a fee we charge for listing the nft on the marketplace
    function updateListingPrice(uint _listingPrice)public payable onlyOwner{

        listingPrice = _listingPrice;
    }

    //anybody can see listing price
    function getListingPrice() public view returns(uint){
        return listingPrice;
    }

    //create token (nft)
    //passing in tokenURi and price and returning tokenId
    function createToken(string memory _tokenURI, uint _price)public payable returns(uint){
        
        //update _tokenIds
        tokenIds.increment();

        //set tokenid to newTokenId
        uint newTokenId = tokenIds.current();

        //calling mint function from ERC721URIStorage
        _mint(msg.sender, newTokenId);

        //call set token URI function
        _setTokenURI(newTokenId, _tokenURI);

        //calling createMarketItem fn which is custom made
        createMarketItem(newTokenId, _price);

        return newTokenId;
    }

    //create market items 
    function createMarketItem(uint _tokenId, uint _price)private {

        //price must be greater than 0
        require(_price > 0, "price must be greater than 0");

        //should send listing price
        require(msg.value == listingPrice, "please send the listing price");

        //the mapping idMarketItem holds all the nfts
        //calling it with tokenid and we are updating thr struct with nft info
        idMarketItem[_tokenId] = MarketItem(

            _tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price,
            false

        );

        //transfer nft from seller to contract using _transfer fn from erc721
        _transfer(msg.sender, address(this), _tokenId);

        //emit the event as ownership was got changes
        emit idMarketItemCreated(
            _tokenId, 
            msg.sender, 
            address(this),
             _price, 
             false
        );

    }

    //function to resale the nft, ie if the owner wants to change price 
    function reSellToken(uint _tokenId, uint _price) public payable{

        //the msg.sender should be the nft owner
        require(idMarketItem[_tokenId].owner == msg.sender, "only item owner can perform this operation");

        //should send listing price
        require(msg.value == listingPrice, "please send the listing price");

        //the struct idMarketItem holds all the nfts
        //we are updating the struct using the mapping everything except tokenId
        idMarketItem[_tokenId].seller = payable(msg.sender);
        idMarketItem[_tokenId].owner = payable(address(this));
        idMarketItem[_tokenId].price = _price;
        idMarketItem[_tokenId].sold = false;

        //everytime the function called this get incremented so we have to decrement it
        itemsSold.decrement();

        //transfer nft from seller to contract using _transfer fn from erc721
        _transfer(msg.sender, address(this), _tokenId);

    }

}