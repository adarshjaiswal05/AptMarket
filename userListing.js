const onboardUser
async function getNFTs721ByOwner(address) {
  const tokenCount721 = await contractMarket.methods.tokenId721().call();
  const tokenCount1155 = await contractMarket.methods.tokenId1155().call();
  const tokenUri = [];

  for (let i = 0; i < tokenCount721; i++) {
    const address = await contract721.methods.ownerOf(i).call();
    if(address==onboardUser){
      const uri = await contract721.methods.tokenURI(i).call();
      tokenUri.push(uri);
    }
  }
    
  for (let i = 0; i < tokenCount1155; i++) {
    const balance = await contract1155.methods.balanceOf(onboardUser,i).call();
    if(balance!=0){
      const uri = await contract1155.methods.uri(i).call();
      tokenUri.push(uri);
    }
  }
    
  return tokenUri;
}

