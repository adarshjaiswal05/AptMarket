// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

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
    uint256 public tokenId721=0;
    uint256 public tokenId1155=0;
    
//do it private
    mapping (string=>RoyaltyInfo) public royaltyDeatils;

    mapping(string => mapping (address=>AssetDetails)) private  _reSaleAssetId;

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


    function setOnBidding(
        string memory tokenUri,
        uint256 price,
        uint256 quantity
        ) 
        external { 
            RoyaltyInfo memory royaltyInfo=royaltyDeatils[tokenUri];
            // uint tokenId=royaltyInfo.tokenId;
            AssetDetails memory asset = _reSaleAssetId[tokenUri][msg.sender];
            
            require(asset.quantityOnSale==0,"please remove asset from sale");
            require(price > 0, "Market Bid:please set a valid price");
            
            require( asset.tokenType == 721 || asset.tokenType == 1155 , "Market sale:invalid token URI");
                require(asset.quantityOnBidding == 0,"Market sale:sale created alredy ");

                require(
                    quantity <= asset.remainingQuantity,
                    "Market sale:No enough tokens left for bid"
                );

            asset.quantityOnBidding += quantity;
            asset.remainingQuantity -= quantity;
            asset.biddingPrice = price;
            if( royaltyInfo.creator != msg.sender){
                asset.royaltySaleShare = ((price*royaltyDeatils[tokenUri].royaltyPercentage)/100);
            }    
            _reSaleAssetId[tokenUri][msg.sender] = asset;

        }

        function removeFromBidding( string memory tokenUri ) external {
            AssetDetails memory Asset =  _reSaleAssetId[tokenUri][msg.sender];
      
          require( Asset.tokenType == 721 || Asset.tokenType == 1155 , "invalid token URI");
              
                require(Asset.quantityOnBidding != 0,"Remove Bid:No sale found");
                Asset.remainingQuantity += Asset.quantityOnBidding;
                Asset.quantityOnBidding = 0;
                Asset.biddingPrice  = 0;
                Asset.royaltySaleShare = 0;
                _reSaleAssetId[tokenUri][msg.sender]=Asset;
            }
        
    
        
        // function bidAsset() payable{

        // }
        // function acceptBid()external{} 



    function getAsset(
        string memory tokenUri,
        address owner
        )
        external view 
        returns (AssetDetails memory asset) {  
             return _reSaleAssetId[tokenUri][owner];
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
            _reSaleAssetId[tokenUri][msg.sender]=newAsset;
             newRoyalty.Type = 721;
             newRoyalty.tokenId=tokenId721;
            } else {
                tokenId1155++;
                _erc1155.mint(msg.sender, quantity,tokenUri,tokenId1155);
                
                newAsset.tokenType = 1155;
                newAsset.url = tokenUri;
                newAsset.remainingQuantity = quantity;
                _reSaleAssetId[tokenUri][msg.sender]=newAsset;
                 newRoyalty.Type = 1155;
                newRoyalty.tokenId=tokenId1155;
            }

            newRoyalty.creator=msg.sender;
            newRoyalty.royaltyPercentage=royaltiesPercentage;
            royaltyDeatils[tokenUri]=newRoyalty;
            
        }





    function setOnSale (
        string memory tokenUri,
        uint256 price,
        uint256 quantity
    ) external {
        RoyaltyInfo memory royaltyInfo=royaltyDeatils[tokenUri];
        // uint tokenId=royaltyInfo.tokenId;
        AssetDetails memory asset = _reSaleAssetId[tokenUri][msg.sender];

        require(price > 0, "Market sale:please set a valid price");
        
        require( asset.tokenType == 721 || asset.tokenType == 1155 , "Market sale:invalid token URI");

            require(asset.quantityOnSale == 0,"Market sale:sale created alredy ");
            require(
                quantity <= asset.remainingQuantity,
                "Market sale:No enough tokens left for sale"
            );

        asset.quantityOnSale += quantity;
        asset.remainingQuantity -= quantity;
        asset.salePrice = price;
        if( royaltyInfo.creator != msg.sender){
            asset.royaltySaleShare = ((price*royaltyDeatils[tokenUri].royaltyPercentage)/100);
        }    
        _reSaleAssetId[tokenUri][msg.sender] = asset;

        }
       

    function removeFromSale( string memory tokenUri ) external {
   
        AssetDetails memory Asset =  _reSaleAssetId[tokenUri][msg.sender];
      
          require( Asset.tokenType == 721 || Asset.tokenType == 1155 , "invalid token URI");
              
                require(Asset.quantityOnSale != 0,"Remove Sale:No sale found");
                Asset.remainingQuantity += Asset.quantityOnSale;
                Asset.quantityOnSale = 0;
                Asset.salePrice  = 0;
                Asset.royaltySaleShare =0;
                _reSaleAssetId[tokenUri][msg.sender]=Asset;
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
        require(msg.sender!=owner,"Buy:You can't buy your own nft");
        RoyaltyInfo memory royaltyInfo=royaltyDeatils[tokenUri];
        uint tokenId=royaltyInfo.tokenId;
        address creator=royaltyInfo.creator;
        AssetDetails memory Asset =  _reSaleAssetId[tokenUri][owner];
  
            require( Asset.tokenType ==721||Asset.tokenType==1155,
                    "invalid token ID");
    
    
                require(creator!=msg.sender,"Market Buy:creator buyback not allowed"); 
                require( Asset.tokenType !=0,"invalid token ID");
    
           if (Asset.tokenType == 721 ) {
            uint256 saleQuantity =Asset.quantityOnSale;
            require(saleQuantity != 0, "This token has not been listed on sale");
            require
            (msg.value == Asset.salePrice + Asset.royaltySaleShare,
            "please enter valid price to buy nft");

            resaleUpdate(tokenUri,owner);
            _addressAccumlatedAmount[msg.sender] += Asset.salePrice;
            _addressAccumlatedAmount[creator] += Asset.royaltySaleShare;
            _sendERC721(owner, msg.sender, tokenId);

            updateUser(tokenUri, 721, 1, msg.sender);
        
           }
           else{
            require(Asset.quantityOnSale != 0, "This token has not been listed on sale");
            require
            (msg.value == Asset.salePrice + Asset.royaltySaleShare,
            "please enter valid price to buy nft");
            
            resaleUpdate(tokenUri,owner);
            
            _addressAccumlatedAmount[owner] += Asset.salePrice;
            _addressAccumlatedAmount[creator] += Asset.royaltySaleShare;

            _sendERC1155(owner, msg.sender, tokenId, Asset.quantityOnSale );
            
            updateUser(tokenUri, 1155, Asset.quantityOnSale , msg.sender);
           }    
        emit BoughtNFT(tokenId, msg.sender);

    }
    


    function withdrawAccumlatedAmount(uint256 amount) external {
        require(amount > 0, "Please withdraw some amount");
        require(
            _addressAccumlatedAmount[msg.sender] >= amount,
            "Withdraw amount:you have entered wrong amount"
        );
        _addressAccumlatedAmount[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
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
