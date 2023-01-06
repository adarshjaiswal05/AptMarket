// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "./APT721.sol";

import "./APT1155.sol";

contract CommonMarket  {

    struct AssetDetails {
        uint256 tokenType;
        string url;
        uint256 biddingPrice;
        uint256 royaltyBidShare;
        uint256 salePrice;
        uint256 royaltySaleShare;
        uint256 quantityOnSale;
        uint256 quantityOnBidding;
        uint256 remainingQuantity;
    }

    struct RoyaltyInfo {
        uint256 tokenId;
        uint256 Type;
        address creator;
        uint256 royaltyPercentage;
    }

    APT721 private _erc721;
    APT1155 private _erc1155;
    address private _admin;
    address private _pendingAdmin;
    uint256 private tokenId721=0;
    uint256 private tokenId1155=0;
    
    // mapping(string => uint) public _uriId;
//do it private
    mapping (string=>RoyaltyInfo) public royaltyDeatils;

    mapping(uint256 => AssetDetails) public _assetId721;
//do it private
    mapping(uint256 => AssetDetails) public _assetId1155;

    mapping(string => mapping (address=>AssetDetails)) public _reSaleAssetId;

    mapping(address => uint256) public  _addressAccumlatedAmount;

    event BoughtNFT(uint256 tokenId, address buyer);

    constructor(APT721 erc721, APT1155 erc1155) {
        //chechking address zero
        require(erc721 != APT721(address(0)), "APT_Market:zero address sent");
        require(erc1155 != APT1155(address(0)), "APT_Market:zero address sent");
        //setting admin to message sender
        _admin = msg.sender;
        _erc721 = erc721;
        _erc1155 = erc1155;
        //setting the market place address in the ERC721 and ERC1155 contract
        _erc721.setMarketAddress();
        _erc1155.setMarketAddress();
    }



    function mintUser(
        string memory tokenUri,
        uint256 quantity,
        uint256 royaltiesPercentage
        )
        external {
            require( quantity>0, "APT_Market:Invalid quantity");
            require( royaltyDeatils[tokenUri].tokenId == 0 ,"APT_Market: Token uri already exists");
            require( royaltiesPercentage>0,"please enter valid percentage");
            // uint token;
            
        AssetDetails memory newAsset;
        RoyaltyInfo memory newRoyalty;
     
            if (quantity==1) {        
             tokenId721++;
             _erc721.mint(msg.sender,tokenUri,tokenId721);
    
             newAsset.tokenType = 721;
             newAsset.url = tokenUri;
             newAsset.remainingQuantity = quantity;
             _assetId721[tokenId721] = newAsset;
             newRoyalty.Type = 721;
             newRoyalty.tokenId=tokenId721;
            } else {
                tokenId1155++;
                _erc1155.mint(msg.sender, quantity,tokenUri,tokenId1155);
                
                newAsset.tokenType = 1155;
                newAsset.url = tokenUri;
                newAsset.remainingQuantity = quantity;
                _assetId1155[tokenId1155] = newAsset;
                 newRoyalty.Type = 1155;
                newRoyalty.tokenId=tokenId1155;
            }

            newRoyalty.creator=msg.sender;
            newRoyalty.royaltyPercentage=royaltiesPercentage;
            royaltyDeatils[tokenUri]=newRoyalty;
            
        }



    function setOnSale(
        string memory tokenUri,
        uint256 price,
        uint256 quantity
    ) external {
        RoyaltyInfo memory royaltyInfo=royaltyDeatils[tokenUri];
        uint tokenId=royaltyInfo.tokenId;
        AssetDetails memory creator721Asset =_assetId721[tokenId];
        AssetDetails memory creator1155Asset = _assetId1155[tokenId];


        require(price > 0, "Market sale:please set a valid price");
        
        require( creator721Asset.tokenType == 721 || creator1155Asset.tokenType == 1155 , "invalid token URI");
        
        if(creator721Asset.tokenType == 721 ) {
            //this means that token type is 721
            require ( msg.sender == royaltyInfo.creator, "721:Only creator is allowed to call this function");

            require(creator721Asset.quantityOnSale == 0,"721:sale created alredy ");
            require(
                quantity <= creator721Asset.remainingQuantity,
                "721:No enough tokens left for sale"
            );
            require(quantity == 1, "721:only one token available for type 721");

        creator721Asset.quantityOnSale += quantity;
        creator721Asset.remainingQuantity -= quantity;
        creator721Asset.salePrice = price;
        _assetId721[tokenId]=creator721Asset;

        }else {
            //this means that token type is 1155

            require ( msg.sender == royaltyInfo.creator, "1155:Only creator is allowed to call this function");
            require(creator1155Asset.quantityOnSale == 0,"1155:sale created alredy ");
            require(
                quantity <= creator1155Asset.remainingQuantity,
                "1155:No enough tokens left for sale"
            );
            require(
                _erc1155.balanceOf(msg.sender, tokenId) >= quantity,
                "1155:Owner dosent have enough tokens "
            );

        creator1155Asset.quantityOnSale += quantity;
        creator1155Asset.remainingQuantity -= quantity;
        creator1155Asset.salePrice = price;
        _assetId1155[tokenId]=creator1155Asset; 
        } 
    }


    function resale(
        string memory tokenUri,
        uint256 price,
        uint256 quantity) external {

        RoyaltyInfo memory royaltyInfo=royaltyDeatils[tokenUri];
        uint tokenId=royaltyInfo.tokenId;
        AssetDetails memory reSaleAsset =  _reSaleAssetId[tokenUri][msg.sender];
        


        // uint256 tokenId= royaltyDeatils[tokenUri].tokenId;


        require(price > 0, "Market sale:please set a valid price");
        require( royaltyInfo.Type == 721  ||royaltyInfo.Type == 1155 , "invalid token URI");

        if(royaltyInfo.Type == 721){

            require(quantity == 1, "721:only one token available for type 721");
            
            require ( 
                royaltyInfo.creator != msg.sender
            , "721:Creator is not allowed to call this function" );
            
            require ( 
                msg.sender == _erc721.ownerOf(tokenId)
            , "721:Only owner is allowed to call this function" );

            require( reSaleAsset.quantityOnSale == 0,"721:sale created alredy");

        }
    else{
          require(  reSaleAsset.quantityOnSale == 0,"1155:sale created alredy ");
          require ( 
                royaltyDeatils[tokenUri].creator != msg.sender
            , "1155:Creator is not allowed to call this function" );
            
            require ( 
                quantity <= _erc1155.balanceOf(msg.sender,tokenId)
            , "1155:No enough token Balance of function caller" );

            require(
                quantity <= reSaleAsset.remainingQuantity,
                "1155:No enough tokens left for sale"
            );

        }

        reSaleAsset.quantityOnSale += quantity;
        reSaleAsset.remainingQuantity -= quantity;
        reSaleAsset.salePrice = price;
        reSaleAsset.royaltySaleShare = ((price*royaltyDeatils[tokenUri].royaltyPercentage)/100); 
        _reSaleAssetId[tokenUri][msg.sender]=reSaleAsset;
        
    }



    function removeFromSale( string memory tokenUri , address owner) external {
         RoyaltyInfo memory royaltyInfo=royaltyDeatils[tokenUri] ;
         uint256 tokenId= royaltyInfo.tokenId;
         address creator=royaltyInfo.creator;
        AssetDetails memory creator721Asset =_assetId721[tokenId];
        AssetDetails memory creator1155Asset = _assetId1155[tokenId];
         
        if(owner==creator){
          require( creator721Asset.tokenType == 721 || creator1155Asset.tokenType == 1155 , "invalid token URI");
              if(creator721Asset.tokenType==721) {
                require(creator721Asset.quantityOnSale != 0,"721:No sale found");
                 onlyOwner(721 , tokenId, msg.sender);
                creator721Asset.remainingQuantity += _assetId721[tokenId].quantityOnSale;
                creator721Asset.quantityOnSale = 0;
                creator721Asset.salePrice  = 0;
                _assetId721[tokenId]=creator721Asset;

              }else{
                require(creator1155Asset.quantityOnSale != 0,"721:No sale found");
                onlyOwner(1155 , tokenId, msg.sender);
                creator1155Asset.remainingQuantity += _assetId1155[tokenId].quantityOnSale;
                creator1155Asset.quantityOnSale = 0;
                creator1155Asset.salePrice  = 0;
                _assetId1155[tokenId]= creator1155Asset;
              }
        }else{

        }
        }


    function updateUser(string memory uri , uint _type , uint quantity, address account )internal {
        AssetDetails memory newAsset= _reSaleAssetId[uri][account];
            newAsset.url= uri;
            newAsset.tokenType= _type;
            newAsset.remainingQuantity +=quantity;
            _reSaleAssetId[uri][account] = newAsset;

        }

      //reentracy attack proof
    function buyImage(
        address owner,
        string memory tokenUri
    ) external payable {
        RoyaltyInfo memory royaltyInfo=royaltyDeatils[tokenUri];
        uint tokenId=royaltyInfo.tokenId;
        address creator=royaltyInfo.creator;
        AssetDetails memory reSaleAsset =  _reSaleAssetId[tokenUri][owner];
        AssetDetails memory creator721Asset =_assetId721[tokenId];
        AssetDetails memory creator1155Asset = _assetId1155[tokenId];

        if(owner==creator){

            require( creator721Asset.tokenType ==721||creator1155Asset.tokenType==1155,
                    "invalid token ID");
    
           if(creator721Asset.tokenType==721) {

                require(creator721Asset.quantityOnSale != 0, "This token has not been listed on sale");
                require(
                msg.value == creator721Asset.salePrice,
                "please enter valid price to buy nft "
                );

                saleQuantityCheck721(tokenUri,owner);
                _addressAccumlatedAmount[owner] += msg.value;
                _sendERC721(owner, msg.sender, tokenId);

                updateUser(tokenUri, 721, 1, msg.sender);
            }
           else{
                uint256 saleQuantity = creator1155Asset.quantityOnSale;
                require(saleQuantity != 0, "This token has not been listed on sale");
                require(
                msg.value ==creator1155Asset.salePrice,
                "please enter valid price to buy nft "
                );
                
                saleQuantityCheck1155(tokenUri,owner);
                _addressAccumlatedAmount[owner] += msg.value;
                updateUser(tokenUri, 1155, saleQuantity, msg.sender); 
                _sendERC1155(owner, msg.sender, tokenId, saleQuantity);
        
           }
         
            emit BoughtNFT(tokenId, msg.sender);
        }else{
                require(creator!=msg.sender,"Market Buy:creator buyback not allowed"); 
                require( reSaleAsset.tokenType !=0,"invalid token ID");
    
           if (reSaleAsset.tokenType == 721 ) {
            uint256 saleQuantity =reSaleAsset.quantityOnSale;
            require(saleQuantity != 0, "This token has not been listed on sale");
            require
            (msg.value == reSaleAsset.salePrice + reSaleAsset.royaltySaleShare,
            "please enter valid price to buy nft");

            saleQuantityCheck721(tokenUri,owner);
            _addressAccumlatedAmount[owner] += reSaleAsset.salePrice;
            _addressAccumlatedAmount[creator] += reSaleAsset.royaltySaleShare;
            _sendERC721(owner, msg.sender, tokenId);

            updateUser(tokenUri, 721, 1, msg.sender);
        
           }
           else{
            require(reSaleAsset.quantityOnSale != 0, "This token has not been listed on sale");
            require
            (msg.value == reSaleAsset.salePrice + reSaleAsset.royaltySaleShare,
            "please enter valid price to buy nft");
            
            saleQuantityCheck1155(tokenUri,owner);
            
            _addressAccumlatedAmount[owner] += reSaleAsset.salePrice;
            _addressAccumlatedAmount[creator] += reSaleAsset.royaltySaleShare;

            _sendERC1155(owner, msg.sender, tokenId, reSaleAsset.quantityOnSale );
            
            updateUser(tokenUri, 1155, reSaleAsset.quantityOnSale , msg.sender);
           }    
        emit BoughtNFT(tokenId, msg.sender);

    }
    }




    function withdrawAccumlatedAmount(uint256 amount) external {
        require(amount > 0, "Please withdraw some amount");
        require(
            _addressAccumlatedAmount[msg.sender] >= amount,
            "you have entered wrong amount"
        );
        _addressAccumlatedAmount[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
      

      //chnge the remaining quantity
   
    function saleQuantityCheck721(string memory uri,address checkAddress) private {
        //this is for reentrency data updating
        RoyaltyInfo memory tokenDetails = royaltyDeatils[uri];     
        uint tokenId = tokenDetails.tokenId;
        require(tokenDetails.Type==721,"Wrong update function called");
        if(checkAddress==tokenDetails.creator){
            //CreatorAsset
            AssetDetails memory creatorSaleAsset= _assetId721[tokenId];
                
                if (
                creatorSaleAsset.remainingQuantity +
                    creatorSaleAsset.quantityOnBidding ==
                0
            ) {
                delete _assetId721[tokenId];

            } else {
                    creatorSaleAsset.quantityOnSale = 0;
                    creatorSaleAsset.salePrice =0;
                    _assetId721[tokenId]=creatorSaleAsset;
            }
            }
        else{
            resaleUpdate(uri,checkAddress);
            }
    }



    function saleQuantityCheck1155(string memory uri,address checkAddress) private {
        RoyaltyInfo memory tokenDetails = royaltyDeatils[uri];     
        uint tokenId = tokenDetails.tokenId;
        require(tokenDetails.Type==1155,"Wrong update function called");

        if(checkAddress==tokenDetails.creator){
            //CreatorAsset
            AssetDetails memory creatorSaleAsset= _assetId1155[tokenId];
                
                if (
                creatorSaleAsset.remainingQuantity +
                    creatorSaleAsset.quantityOnBidding ==
                0
            ) {
                delete _assetId721[tokenId];

            } else {
                    creatorSaleAsset.quantityOnSale = 0;
                    creatorSaleAsset.salePrice =0;
                    _assetId1155[tokenId]=creatorSaleAsset;
            }
        }
        else{
                resaleUpdate(uri,checkAddress);
        }
    }


    function resaleUpdate(string memory uri,address checkAddress) private {
         AssetDetails memory reSaleAsset =  _reSaleAssetId[uri][checkAddress];

            if (
                reSaleAsset.remainingQuantity +
                reSaleAsset.quantityOnBidding ==
                0
        ) {
                delete _reSaleAssetId[uri][checkAddress];

        } else {
                reSaleAsset.quantityOnSale = 0;
                reSaleAsset.salePrice =0;
                reSaleAsset.royaltySaleShare=0;
                _reSaleAssetId[uri][checkAddress]=reSaleAsset;
        }

    }

    
    

    function onlyOwner(
        uint256 tokenType,
        uint256 tokenId,
        address owner
    ) private view {
        if (tokenType == 721) {
            require(_erc721.ownerOf(tokenId) == owner, "invalid owner");
        } else if (tokenType == 1155) {
            require(
                _erc1155.balanceOf(owner, tokenId) != 0,
                "wrong owner, token type or token id"
            );
        }
    }



    function changeOwnership(address newAdmin)external {
        require(msg.sender==_admin,"APT_Market:Only admin is allowed to call this function");
        _pendingAdmin=newAdmin;  
    }

    function acceptOwnership()external {
        require(msg.sender==_pendingAdmin,"APT_Market:You are forbidden to call");
        _admin=_pendingAdmin;
    }

    function _sendERC721(
        address owner,
        address to,
        uint256 tokenId
    ) private {
        _erc721.safeTransferFrom(owner, to, tokenId);
    }

    function _sendERC1155(
        address owner,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) private {
        _erc1155.safeTransferFrom(owner, to, tokenId, quantity, "");
    }
    }
