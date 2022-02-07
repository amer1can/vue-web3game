<template>
    <div class="main">
      <div class="header pt-4">Epic Game Production</div>
      <p class="subheader mt-3">Top rated NFT game to play!</p>
      <div v-if="!walletStatus">
        <button class="walletbtn mt-3" @click="connectToWallet">Connect to wallet</button>
      </div>

      <div v-else-if="currentAccount && !currentCharacter">
<!--        <select-character :chars="characters"></select-character>-->
        <div v-if="characters.length !==0" class="select-char mt-5 text-white">
          <h2>Select and mint your character:</h2>
          <div class="char-cards">
            <div class="card mx-3 hero" style="width: 18rem;" v-for="(char, index) in characters" :key="char.name">
              <img :src="char.imageURI" :alt="char.name" class="card-img-top">
              <button class="btn btn-dark" @click="mintCharacterNFTAction(index)">Mint {{ char.name }}</button>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="battle">
        <div v-if="bigBoss" class="card mx-3 boss" style="width: 18rem;">
          <h2>{{ bigBoss.name }}</h2>
          <img :src="bigBoss.imageURI" :alt="bigBoss.name" class="card-img-top">
          <div class="attr">
            <progress class="progress-health" :value="bigBoss.hp" :max="bigBoss.maxHp"></progress>
            <p class="health">{{ bossHp }} / {{ bigBoss.maxHp }} HP</p>
          </div>
        </div>

        <div class="swords mt-5 mb-5" :class="runAttackStatus">
          <button class="btn btn-dark btn-attack" @click="runAttackAction"><img src="../img/battle.jpg" alt="" width="40" height="40"> Attack {{ bigBoss.name }}</button>
        </div>

        <div class="card mx-3 hero" style="width: 18rem;">
          <h2>{{ currentCharacter.name }}</h2>
          <img :src="currentCharacter.imageURI" :alt="currentCharacter.name" class="card-img-top">
          <div class="attr">
            <progress class="progress-health" :value="currentCharacter.hp" :max="currentCharacter.maxHp"></progress>
            <p class="health"> {{ heroHp }} / {{ currentCharacter.maxHp }} HP</p>
          </div>
          <p style="font-size: 15px">Attack damage: {{ currentCharacter.attackDamage }}</p>

        </div>
      </div>
    </div>


    <div class="footer">
      <img src="./assets/twitter-logo.svg" alt="">
      <a href="https://twitter.com/amer1canWM" target="_blank" rel="noreferrer">Seeing on Twitter</a>
    </div>
</template>

<script>

// import SelectCharacter from "@/components/SelectCharacter";
import ethers from 'ethers';
import abi from './utils/EpicGame.json';

export default {
  name: 'App',
  // components: {SelectCharacter},
  data() {
    return {
      gameContract: null,
      address: '0xd613319068DeeABaA32b28f10d0672c59709e42F',
      contractABI: abi.abi,
      account: null,
      walletStatus: false,
      currentAccount: null,
      currentCharacter: null,
      bigBoss: null,
      characters: [],
      attackStatus: 'hit'
    }
  },
  async beforeMount() {
    await this.checkIfWalletConnect()
    await this.fetchBoss()
  },
  mounted() {
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    const signer = provider.getSigner()
    this.gameContract = new ethers.Contract(this.address, this.contractABI, signer)
  },
  computed: {
    runAttackStatus() {
      return this.attackStatus
    },
    bossHp() {
      return this.bigBoss.hp
    },
    heroHp() {
      return this.currentCharacter.hp
    }
  },
  methods: {
    async checkIfWalletConnect() {
      try {
        const { ethereum } = window;

        if(!ethereum) { console.log('Make sure you have Metamask'); return; }
        else { console.log('We have ethereum object', ethereum) }

        await this.checkNetwork()

        const accounts = await ethereum.request({
          method: 'eth_accounts'
        })

        if(accounts.length !== 0) {
          this.currentAccount = accounts[0]
          this.walletStatus = true
          console.log('Found authorized account', this.currentAccount)
          await this.fetchNFTMetadata()
        } else { console.log('No authorized accounts found'); this.walletStatus = false }

      }catch(err) { console.log(err) }
    },
    async checkNetwork() {
      try {
        if (window.ethereum.networkVersion != '4') { alert('Please, connect to Rinkeby Network!') }
      } catch (err) { console.log(err) }
    },
    async connectToWallet() {
      try {
        const { ethereum } = window;

        if(!ethereum) { console.log('Get Metamask!'); this.walletStatus = false; return; }

        const accounts = await ethereum.request({
          method: 'eth_requestAccounts'
        })
        this.currentAccount = accounts[0]
        this.walletStatus = true
        console.log('Connected', this.currentAccount)
        await this.fetchNFTMetadata()
      } catch(err) { console.log(err) }
    },
    async fetchNFTMetadata() {
      console.log('Checking for Character NFT on address', this.currentAccount)

      const txn = await this.gameContract.checkIfUserHaveNFT();
      if (txn.name) {
        console.log('User has character NFT')
        this.currentCharacter = this.transformCharData(txn)
        console.log('Current character: ', this.currentCharacter)

      } else {
        console.log('No character NFT found')

        this.gameContract.on('CharacterNFTMinted', this.onCharacterMint)
        await this.getCharacters()
        this.gameContract.off('CharacterNFTMinted', this.onCharacterMint)
      }
    },
    transformCharData(charData) {
      return {
        name: charData.name,
        imageURI: charData.imageURI,
        hp: charData.hp.toNumber(),
        maxHp: charData.maxHp.toNumber(),
        attackDamage: charData.attackDamage.toNumber(),
        defence: charData.defence.toNumber()
      }
    },
    async getCharacters() {
      try {
        console.log('Getting contract characters to mint')

        const charactersTxn = await this.gameContract.getAllDefaultCharacters()
        console.log('charactersTxn: ', charactersTxn)

        charactersTxn.forEach(data => {
          this.characters.push(this.transformCharData(data))
        })

        console.log('CHARACTERS!: ', this.characters)

      } catch(err) { console.log(err) }
    },
    async mintCharacterNFTAction(charId) {
      try {
        if (this.gameContract) {
          console.log('Minting character in progress...')
          const mintTxn = await this.gameContract.mintCharNFT(charId)
          await mintTxn.wait()
          console.log('mintTxn:', mintTxn)
        }
      } catch (err) { console.warn('MintCharacterAction Error: ', err) }
    },
    async onCharacterMint(sender, tokenId, charIndex) {
      console.log(`CharacterNFTMinted - sender: ${sender}, tokenId: ${tokenId.toNumber()}, characterIndex: ${charIndex.toNumber()}`)
      alert(`Your NFT is all done -- see it here: https://testnets.opensea.io/assets/${this.address}/${tokenId.toNumber()}`)
    },
    async fetchBoss() {
      console.log('Fetching the BiGBoss...')
      this.bigBoss = await this.gameContract.getBigBoss()
      console.log('BigBoss: ', this.bigBoss)
    },
    async runAttackAction() {
      try {
        if(this.gameContract) {
          this.gameContract.on('AttackComplete', this.onAttackComplete)

          this.attackStatus = 'attacking'
          console.log('Attacking boss...')
          const attackTxn = await this.gameContract.attackBoss()
          await attackTxn.wait()
          console.log('attackTxn: ', attackTxn)
          this.attackStatus = 'hit'

          this.gameContract.off('AttackComplete', this.onAttackComplete)
        }

      } catch(err) { console.error('Error attacking boss: ', err); this.attackStatus = '' }
    },
    async onAttackComplete(newBossHp, newPlayerHp) {
      const bossHp = newBossHp.toNumber()
      const playerHp = newPlayerHp.toNumber()

      console.log(`AttackComplete: Boss HP: ${bossHp}, Player HP: ${playerHp}`)
      this.bigBoss.hp = bossHp
      this.currentCharacter.hp = playerHp
    }
  }

}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  background: #100f0f;
  display: flex;
  flex-direction: column;
  height: 100%;
}
.main {
  flex-grow: 1;
}
.header {
  font-size: 50px;
  font-weight: bold;
  background: -webkit-linear-gradient(left, #e8b756 30%, #e71515 60%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.subheader {
  font-size: 30px;
  color: white;
}
.walletbtn {
  font-size: 22px;
  padding: 0.5em;
  border-radius: 15px;
  background: -webkit-linear-gradient(left, #e8b756, #e71515);
  background-size: 200% 200%;
  animation: gradient-animation 4s ease infinite;
  align-self: center;
}
.char-cards {
  margin: 0 auto;
  max-width: 800px;
  display: flex;
  justify-content: center;
}
.card {
  padding: 20px;
  background: #e8b756!important;
}
.boss {
  background: #ff4444!important;
}

.card img {
  flex-grow: 1;
}
.battle {
  max-width: 600px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.hero {
  transform: scale(1);
  transition: all 0.5s ease-in-out;
}
.hero:hover {
  transform: scale(1.05);
  transition: all 0.5s ease-in-out;
}
.boss {
  transform: rotate3d(0, 0, 0, 0deg);
  transition: all 0.5s ease-in-out;
}
.boss:hover {
  transform: rotate3d(1, 1, 1, 15deg);
  transition: all 0.5s ease-in-out;
}
progress {
  width: 100%;
  height: 50px;
}
.attr {
  position: relative;

}
.health {
  position: absolute;
  top: 23%;
  left: 50%;
  transform: translateX(-50%);
  font-size: 15px;
}

.swords.attacking {
  width: 100px;
  height: 100px;
  background: url("assets/waiting.gif");
  background-size: contain;
}
.swords.attacking > button {
  display: none;
}

.swords.hit {
  background: none;
}
.swords.hit > button {
  display: inline-block;
}

.footer {
  padding: 20px 0px;
}
.footer a {
  color: coral;
  font-size: 18px;
  font-weight: bold;
  text-decoration: none;
  transition: all 0.2s ease-in;
}
.footer a:hover {
  color: #ff4444;
  transition: all 0.2s ease-in;
}
.footer img {
  width: 30px;
}


/* KeyFrames */
@-webkit-keyframes gradient-animation {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}
@-moz-keyframes gradient-animation {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}
@keyframes gradient-animation {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}
</style>
