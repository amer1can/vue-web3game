const hre = require("hardhat");

async function main() {
    const EpicGameFactory = await hre.ethers.getContractFactory("EpicGame");
    const epicGame = await EpicGameFactory.deploy(
        ['R2D2', 'Bulbasaur', 'Naruto'],
        ['https://i.ibb.co/1RWVdMr/r2d2.jpg',
        'https://i.ibb.co/KL6TDXF/bulbasaur-jpg.jpg',
        'https://i.ibb.co/LYC4pNF/naruto.png]'],
        [650, 500, 1000],
        [650, 500, 1000],
        [25, 50, 50],
        [100, 75, 50],
        "Joker",
        "https://i.ibb.co/4YdhnLh/joker.jpg",
        10000,
        50
    );
    console.log('Waiting...');

    await epicGame.deployed();
    console.log("EpicGame contract deployed to:", epicGame.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
