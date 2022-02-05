const hre = require("hardhat");

async function main() {
  const EpicGameFactory = await hre.ethers.getContractFactory("EpicGame");
  const epicGame = await EpicGameFactory.deploy(
      ['R2D2', 'Bulbasaur', 'Naruto'],
      ['https://i.ibb.co/1RWVdMr/r2d2.jpg',
        'https://i.ibb.co/KL6TDXF/bulbasaur-jpg.jpg',
        'https://i.ibb.co/LYC4pNF/naruto.png]'],
      [350, 200, 300],
      [500, 500, 500],
      [25, 50, 75],
      [100, 75, 25],
      "Joker",
      "https://i.ibb.co/4YdhnLh/joker.jpg",
      10000,
      50
  );

  await epicGame.deployed();
  console.log("EpicGame contract deployed to:", epicGame.address);

  let txn = await epicGame.mintCharNFT(2); //mint Naruto from array
  await txn.wait();

  txn = await epicGame.attackBoss();
  await txn.wait();

  txn = await epicGame.attackBoss();
  await txn.wait();

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
