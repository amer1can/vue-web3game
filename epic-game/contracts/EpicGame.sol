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

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharAttributes[] defaultCharacters;

    mapping(uint256 => CharAttributes) public nftHolderAttributes;
    mapping(address => uint256) public nftHolders;

    constructor(
        string[] memory charNames,
        string[] memory charImageURIs,
        uint[] memory charHp,
        uint[] memory maxHp,
        uint[] memory charAttackDamage,
        uint[] memory charDefence

    ) ERC721("NFTHeroes", "HERO") {
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
}

/*
1) 0xE8036b6b27d0Db0aB3fAe822C9d88c1D3C84341D
*/
