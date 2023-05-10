let contractStaking;
	const ADDRESSStaking = "0x6FAE4807c844d805a9c2007E99bfe6Ce0d6eFbB2"
	const ABISTAKING 
  
 async function stakeNft(uri,quantity) {

	try {
		let sAccounts = await web3.eth.getAccounts();
		let sMsgsender = sAccounts[0];

		let nGasUsed = await contractStaking.methods.stakeNft(uri,quantity)
			.estimateGas({ from: sMsgsender })
		alert("gas used for this transation is " + nGasUsed + " click on confirm in metamask to continue")

		await contractStaking.methods.stakeNft(uri,quantity)
			.send({ from: sMsgsender })
			.on('transactionHash', function (sHash) {
				if (window.confirm('Your transation hash is' + sHash + "press ok to visit the transation details on ether scan")) {
					window.open(`https://mumbai.polygonscan.com/address/${sHash}`);
				};
			}).on('receipt', function (receipt) {
				receiptStatus(receipt);
			})
			.catch(function (err) {
				alert(err.message)
			}
			)

	} catch (err) {
		console.log(err)
	}
}

async function unStake(uri) {

	try {
		let sAccounts = await web3.eth.getAccounts();
		let sMsgsender = sAccounts[0];

		let nGasUsed = await contractStaking.methods.unStake(uri)
			.estimateGas({ from: sMsgsender })
		alert("gas used for this transation is " + nGasUsed + " click on confirm in metamask to continue")

		await contractStaking.methods.unStake(uri)
			.send({ from: sMsgsender })
			.on('transactionHash', function (sHash) {
				if (window.confirm('Your transation hash is' + sHash + "press ok to visit the transation details on ether scan")) {
					window.open(`https://mumbai.polygonscan.com/address/${sHash}`);
				};
			}).on('receipt', function (receipt) {
				receiptStatus(receipt);
			})
			.catch(function (err) {
				alert(err.message)
			}
			)

	} catch (err) {
		console.log(err)
	}
}

async function withdrawAccumlatedAmount(){
	try {
		
		let sAccounts = await web3.eth.getAccounts();
		let sMsgsender = sAccounts[0];

		let nGasUsed = await contractStaking.methods.withdrawBalance()
			.estimateGas({ from: sMsgsender })
		alert("gas used for this transation is " + nGasUsed + " click on confirm in metamask to continue")

		contractStaking.methods.withdrawBalance().send({ from: sMsgsender })
			.on('transactionHash', function (sHash) {
				if (window.confirm('Your transation hash is' + sHash + "press ok to visit the transation details on ether scan")) {
					window.open(`https://goerli.etherscan.io/tx/${sHash}`);
				};
			}).on('receipt', function (receipt) {
				receiptStatus(receipt);
			})
			.catch(function (err) {
				alert(err.message)
			}
			)

	} catch (err) {
		console.log(err)
	}
}



