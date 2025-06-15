const { ethers } = require("hardhat");
const path = require("path");
const fs = require("fs");

async function main() {
  const price = ethers.parseEther("1"); // 1 ETH po noći

  const Booking = await ethers.getContractFactory("Booking_contract");
  const contract = await Booking.deploy(price);

  await contract.waitForDeployment();
  console.log("Ugovor deployan");

  // Putanja do JSON fajla u frontend folderu
  const contractsFilePath = path.resolve(
    __dirname,
    "../frontend/frontend/src/contracts.json"
  );

  // Pročitaj postojeći sadržaj ako postoji, ili napravi prazan niz
  let contracts = [];
  if (fs.existsSync(contractsFilePath)) {
    const data = fs.readFileSync(contractsFilePath);
    contracts = JSON.parse(data);
  }
  if (fs.existsSync(contractsFilePath)) {
    const data = fs.readFileSync(contractsFilePath);
    contracts = JSON.parse(data);
    if (!Array.isArray(contracts)) {
      contracts = [];
    }
  }

  // Dodaj novu adresu (provjeri da nije već dodana)
  if (!contracts.find((c) => c.address === contract.address)) {
    contracts.push({ address: contract.address });
  }

  // Sačuvaj nazad u JSON
  fs.writeFileSync(contractsFilePath, JSON.stringify(contracts, null, 2));

  console.log("Adresa je sačuvana u frontend/src/contracts.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
