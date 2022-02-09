// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./libraries/Base64.sol";

contract EpicGame is ERC721 {

    struct CharAttributes {
        uint charIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
        uint defence;
    }

    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
        uint defence;
    }

    BigBoss public bigBoss;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharAttributes[] defaultCharacters;

    mapping(uint256 => CharAttributes) public nftHolderAttributes;
    mapping(address => uint256) public nftHolders;

    event CharacterNFTMined(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    constructor(
        string[] memory charNames,
        string[] memory charImageURIs,
        uint[] memory charHp,
        uint[] memory maxHp,
        uint[] memory charAttackDamage,
        uint[] memory charDefence,
        string memory bossName, // boss variables would be passed in via run.js or deploy.js.
        string memory bossImageURI,
        uint bossHp,
        uint bossAttackDamage

    ) ERC721("NFTHeroes", "HERO") {
        //bigBoss creating
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: 10000,
            attackDamage: bossAttackDamage,
            defence: 100
        });

        console.log("Done initializing boss %s with HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

        for(uint i = 0; i < charNames.length; i++) {
            defaultCharacters.push(CharAttributes({
                charIndex: i,
                name: charNames[i],
                imageURI: charImageURIs[i],
                hp: charHp[i],
                maxHp: maxHp[i],
                attackDamage: charAttackDamage[i],
                defence: charDefence[i]
        }));

            CharAttributes memory c = defaultCharacters[i];
            console.log("Done initializing %s with -> HP: %s, DF: %s.", c.name, c.hp, c.defence);
        }
        _tokenIds.increment();
    }

    function mintCharNFT(uint _charIndex) external {
        uint256 newItemId = _tokenIds.current(); // get current token newItemId
        _safeMint(msg.sender, newItemId); //magical function, which assigns the tokenId to caller's wallet address

        //mapping the tokenId => their character attributes
        nftHolderAttributes[newItemId] = CharAttributes({
            charIndex: _charIndex,
            name: defaultCharacters[_charIndex].name,
            imageURI: defaultCharacters[_charIndex].imageURI,
            hp: defaultCharacters[_charIndex].hp,
            maxHp: defaultCharacters[_charIndex].maxHp,
            attackDamage: defaultCharacters[_charIndex].attackDamage,
            defence: defaultCharacters[_charIndex].defence
        });

        console.log("Minted NFT with tokenId %s and characterIndex %s", newItemId, _charIndex);

        nftHolders[msg.sender] = newItemId; //keep who owns what NFT
        _tokenIds.increment();

        emit CharacterNFTMined(msg.sender, newItemId, _charIndex);
    }

    function tokenURI(uint _tokenId) public view override returns(string memory) {
        CharAttributes memory localCharAttr = nftHolderAttributes[_tokenId];
        string memory strHp = Strings.toString(localCharAttr.hp); //toString cause uint
        string memory strMaxHp = Strings.toString(localCharAttr.maxHp);
        string memory strAttackDamage = Strings.toString(localCharAttr.attackDamage);
        string memory strDefence = Strings.toString(localCharAttr.defence);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                    localCharAttr.name,
                ' -- NFT #: ', Strings.toString(_tokenId),
                '", "description": "This is an NFT that lets people fun play.", "image": "',
                localCharAttr.imageURI,
                '", "attributes": [ {"trait_type": "Health Points", "value": ',strHp,', "max_value": ',strMaxHp,'}, {"trait_type": "Attack Damage", "value": ',strAttackDamage,'}, {"trait_type": "Defence Points", "value": ',strDefence,'} ]}'
            )
        );

        string memory output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function attackBoss() public {
        // Get the state of the player's NFT.
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender]; //grab the NFT's tokenId that the player owns
        CharAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer]; //grab the player's attributes
        // I use the keyword storage here as well which will be more important a bit later. Basically, when we do storage and then do player.hp = 0 then it would change the health value on the NFT itself to 0.
        //In contrast, if we were to use memory instead of storage it would create a local copy of the variable within the scope of the function. That means if we did player.hp = 0 it would only be that way within the function and wouldn't change the global value.
        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
        console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);
        // Make sure the player has more than 0 HP.
        require(player.hp > 0, "Error: character must have HP to attack boss");
        // Make sure the boss has more than 0 HP.
        require(bigBoss.hp > 0, "Error: boss must have HP to attack character");
        // Allow player to attack boss.
        if (bigBoss.hp < player.attackDamage) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        }
        // Allow boss to attack player.
        if (player.hp < bigBoss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attackDamage;
        }
        console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);

        emit AttackComplete(bigBoss.hp, player.hp);
    }

    function checkIfUserHaveNFT() public view returns(CharAttributes memory) {
        // Get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenId in the map, return their character.
        /*Why do we do userNftTokenId > 0? Well, basically there's no way to check if a key in a map exists. We set up our map like this: mapping(address => uint256) public nftHolders. No matter what key we look for, there will be a default value of 0.
        This is a problem for user's with NFT tokenId of 0. That's why earlier, I did _tokenIds.increment() in the constructor! That way, no one is allowed to have tokenId 0. This is one of those cases where we need to be smart in how we set up our code because of some of the quirks of Solidity :).*/
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Else, return an empty character.
        else {
            CharAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters() public view returns(CharAttributes[] memory) {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }

    function donateHpCharacter(uint _charIndex) public {
        defaultCharacters[_charIndex].hp += 300;
        console.log('Donate successfully done: character %s have %s HP', defaultCharacters[_charIndex].name, defaultCharacters[_charIndex].hp );
    }

}

/*
1) 0xE8036b6b27d0Db0aB3fAe822C9d88c1D3C84341D
2) test attack: 0xd613319068DeeABaA32b28f10d0672c59709e42F
3) with donate: 0x99533Ff26719A5159E0087E273915840237D8b83
*/
