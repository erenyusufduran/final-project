const { ethers, network } = require("hardhat");
const { storeImages, storeTokenUriMetadata } = require("../utils/uploadToPinata");
const { verify } = require("../utils/verify");

const imagesLocation = "./images/";
const developmentChains = ["hardhat", "localhost"];

const metadataTemplate = {
  name: "",
  description: "",
  image: "",
  attributes: [{ trait_type: "prestige" }],
};

let tokenUris = [];

async function main() {
  if (process.env.UPLOAD_TO_PINATA == "true") {
    tokenUris = await handleTokenUris();
  }
  const FundingNFTContract = await ethers.getContractFactory("FundingNFT");
  const fundingNFT = await FundingNFTContract.deploy(tokenUris);
  await fundingNFT.deployed();
  console.log(fundingNFT.address);

  const FundingDAOContract = await ethers.getContractFactory("FundingDAO");
  const fundingDAO = await FundingDAOContract.deploy(fundingNFT.address);
  await fundingDAO.deployed();
  console.log(fundingDAO.address);

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    console.log("Verifying...");
    await verify(fundingNFT.address, [tokenUris]);
    await verify(fundingDAO.address, [fundingNFT.address]);
  }
}

async function handleTokenUris() {
  tokenUris = [];
  const { responses: imageUploadResponses, files } = await storeImages(imagesLocation);
  for (imageUploadResponseIndex in imageUploadResponses) {
    let tokenUriMetadata = { ...metadataTemplate };
    tokenUriMetadata.name = files[imageUploadResponseIndex].replace(".jpeg", "");
    tokenUriMetadata.description = `An governance ${tokenUriMetadata.name} token for voting/funding.`;
    tokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`;
    console.log(`Uploading ${tokenUriMetadata.name}...`);

    const metadataUploadResponse = await storeTokenUriMetadata(tokenUriMetadata);
    tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`);
  }
  console.log("Token URIs Uploaded!");
  console.log(tokenUris);
  return tokenUris;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
