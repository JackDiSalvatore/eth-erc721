const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers')
const ERC721Token = artifacts.require('ERC721Token')
const MockGoodRecipient = artifacts.require('MockGoodRecipient')
const MockBadRecipient = artifacts.require('MockBadRecipient')

contract('ERC721Token', async (accounts) => {
  let nft
  const deployer = accounts[0]
  const alice = accounts[1]
  const bob = accounts[2]
  const carl = accounts[3]

  console.log('deployer: ' + deployer)
  console.log('alice: ' + alice)
  console.log('bob: ' + bob)
  console.log('carl: ' + carl)

  beforeEach('Contract should be deployed', async () => {
    nft = await ERC721Token.new('nft coins', 'NFT', 5)
  })

  // Testing:
  // transferFrom(from, to, tokenId)
  describe('Should allow NTF to change ownership from address to address', async () => {

    it('Transfer ownership of nft 0 from deployer to alice', async () => {
      console.log('deployerBalance: ' + await nft.balanceOf(deployer))
      console.log('owner of tokenId 0: ' + await nft.ownerOf(0))

      console.log('TRANSFERING...')
      await nft.transferFrom(deployer, alice, 0, {from: deployer})

      console.log('deployerBalance: ' + await nft.balanceOf(deployer))
      console.log('aliceBalance: ' + await nft.balanceOf(alice))
      console.log('owner of tokenId 0: ' + await nft.ownerOf(0))

      // Should update alices nft balance and ownership
      const aliceBalance = await nft.balanceOf(alice)
      const tokenId_0_owner = await nft.ownerOf(0)
      assert(parseInt(aliceBalance) === 1, 'alice did not get the nft')
      assert(tokenId_0_owner === alice, 'alice does not own the nft')
    })

    it('Should reject alice transfering NFT that belongs to the owner', async() => {
      console.log('Owner of nft 1: ' + await nft.ownerOf(1))
      await expectRevert(
          nft.transferFrom(deployer, bob, 1, {from: alice}),
          'sender not authorized to transfer NFT'
      )
    })

  })

  // Testing:
  // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data)
  // function safeTransferFrom(address _from, address _to, uint256 _tokenId)

  describe('Should allow NFT to change ownership from address to smart contract', async () => {
    let goodRecipient
    let badRecipient

    beforeEach('Load MockGoodRecipient and MockBadRecipient contracts', async () => {
      goodRecipient = await MockGoodRecipient.new()
      badRecipient = await MockBadRecipient.new()
    })

    it('Should successfully transfer to a smart contract that implements onERC721Received', async () => {
      console.log('MockGoodRecipient: ' + goodRecipient.address)
      console.log('MockBadRecipient: ' + badRecipient.address) 
      let deployerBalance = await nft.balanceOf(deployer)
      console.log('deployerBalance: ' + deployerBalance)

      const receipt = await nft.safeTransferFrom(deployer, goodRecipient.address, 0)
      const newOwner = await nft.ownerOf(0)
      assert(web3.utils.toBN(await nft.balanceOf(deployer)).eq(deployerBalance.sub(web3.utils.toBN(1))),
             'wrong deployer balance')
      assert(web3.utils.toBN(await nft.balanceOf(goodRecipient.address)).eq(web3.utils.toBN(1)),
             'wrong recipient balance')
      await expectEvent(receipt, 'Transfer', {
        _from: deployer,
        _to: newOwner,
        _tokenId: web3.utils.toBN(0)
      })
    })

    it('Should successfully transfer with bytes data', async () => {
      const receipt = await nft.safeTransferFrom(deployer, goodRecipient.address, 1, web3.utils.fromUtf8('123456789'))
      const newOwner = await nft.ownerOf(1)

      await expectEvent(receipt, 'Transfer', {
        _from: deployer,
        _to: newOwner,
        _tokenId: web3.utils.toBN(1)
      })
    })

    it('Should not transfer to a smart contract that does not implement onERC721Received', async () => {
      await expectRevert(
        nft.safeTransferFrom(deployer, badRecipient.address, 1, web3.utils.fromUtf8('123456789')),
        ' '  // 'recipient SC cannot accept ERC721 tokens'
      )
    })

  })

  // Testing:
  // approve(address _approved, uint256 _tokenId)
  // getApproved(uint256 _tokenId)

  describe('Should allow appoved sender to transfer an NFT', async () => {

    beforeEach('Deployer approves alice to transfer NFTs on there behalf', async () => {
        console.log('owner of NFT 0: ' + await nft.ownerOf(0))
        const receipt = await nft.approve(alice, 0, {from: deployer})
        const approved = await nft.getApproved(0)

        expectEvent(receipt, 'Approval', {
          _owner: deployer,
          _approved: approved,
          _tokenId: web3.utils.toBN(0)
        })
        assert(approved == alice, 'alice was not successfully approved') 
    })

    it('Should let the approved sender (alice) send the approved nft (0)', async () => {
      const receipt = await nft.transferFrom(deployer, bob, 0, {from: alice})
      const ownernft0 = await nft.ownerOf(0)    // Should be bob
      assert(ownernft0 === bob, 'bob did not receive transfer')
    })

  })

  // Testing:
  // setApprovalForAll(address _operator, bool _approved)
  // isApprovedForAll(address _owner, address _operator)

  describe('Should allow approved operator to transfer all nfts', async() => {

    beforeEach('Deployer makes alice an operator', async () => {
      const receipt = await nft.setApprovalForAll(alice, true, {from: deployer})
      expectEvent(receipt, 'ApprovalForAll', {
        _owner: deployer,
        _operator: alice,
        _approved: true
      })
    })

    it('alice should be approved for all', async () => {
      const isApprovedForAll = await nft.isApprovedForAll(deployer, alice)
      assert(isApprovedForAll === true, 'alice is not an operator for deployer')
    })

    it('alice should be able to transfer all of deployers nfts', async () => {
      let deployerNFTCount = await nft.balanceOf(deployer)

      // Transfer all NTFs from deployer to bob using alices permission
      for (let i = 0; i < deployerNFTCount; i++) {
        await nft.transferFrom(deployer, bob, i, {from: alice})
        let bobNFTCount = await nft.balanceOf(bob)
      }

      let bobNFTCount = await nft.balanceOf(bob)
      assert(parseInt(deployerNFTCount) === parseInt(bobNFTCount),
             'not all NFTs transferred to bob ' + deployerNFTCount + ', ' + bobNFTCount)

      deployerNFTCount = await nft.balanceOf(deployer)
      assert(parseInt(deployerNFTCount) === 0, 'not all NFTs transferred from deployer')
    })

  })

})
