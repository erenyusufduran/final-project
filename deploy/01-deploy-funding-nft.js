const { network } = require("hardhat");

const metadataTemplate = {
  name: "",
  description: "",
  image: "",
  attributes: [{ trait_type: "prestige" }],
};

let tokenUris = [];

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  if (process.env.UPLOAD_TO_PINATA == "true") {
    // tokenUris = await handleTokenUris();
  }

  log("-------------------------");
  const args = [tokenUris];
  const fundingNft = await deploy("FundingNFT", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  log("--------------------------");
};
