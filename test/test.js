async function main() {
  const { ethers } = require("hardhat");
  console.log(ethers.utils.parseEther("1").toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
