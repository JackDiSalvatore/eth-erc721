// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import './utils/address-utils.sol';

interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

contract ERC721Token is ERC721 {
    using AddressUtils for address;

    string public name;
    string public symbol;
    uint256 public tokenId;
    uint256 public totalSupply;

    // tokenId => owner
    mapping(uint256 => address) private tokenIdToOwner;
    // owner => tokenCount
    mapping(address => uint256) private ownerToTokenCount;
    // tokenId => approved sender
    mapping(uint256 => address) private tokenIdToApprovedSender;
    // owner => (operator => active)
    mapping(address => mapping(address => bool)) private ownerToOperatorToAllowed;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol; 
        totalSupply = _totalSupply;

        // Mint total supply to deployer
        for (uint256 i = 0; i < totalSupply; i++) {
            tokenIdToOwner[i] = msg.sender;
            ownerToTokenCount[msg.sender]++;
        }
    }

    // **************************************************************
    // EXTERNAL FUNCTIONS
    // **************************************************************

    // Count all NTFs assigned to an owner
    function balanceOf(address _owner) view public returns (uint256) {
        return ownerToTokenCount[_owner];
    }

    // Get the owner of an NTF by its tokenId
    function ownerOf(uint256 _tokenId) view public returns (address) {
        return tokenIdToOwner[_tokenId];
    }

    // Transfer to a smart contract with byte data
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) payable public {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    // Transfer to a smart contract without byte data
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) payable public {
        _safeTransferFrom(_from, _to, _tokenId, '');
    }

    // Transfer to an address
    function transferFrom(address _from, address _to, uint256 _tokenId) payable public {
        require(_from != _to, 'cannot transfer to self');
        _transferFrom(_from, _to, _tokenId);
    }

    // Approve a designated address to transfer an NFT that belongs to an owner
    function approve(address _approved, uint256 _tokenId) payable public {
        address owner = tokenIdToOwner[_tokenId]; 
        require(tokenIdToOwner[_tokenId] == msg.sender, 'sender not NTF owner');
        tokenIdToApprovedSender[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    // Approve a designated address to transfer all NFTs that belongs to an owner
    function setApprovalForAll(address _operator, bool _approved) public {
        ownerToOperatorToAllowed[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // Get approved address for NFT (I' am guess a NFT can have a single owner and a single approved designated spender
    function getApproved(uint256 _tokenId) view public returns (address) {
        return tokenIdToApprovedSender[_tokenId];
    }

    // Check to see if an address is an operator for another address
    function isApprovedForAll(address _owner, address _operator) view public returns (bool) {
        return ownerToOperatorToAllowed[_owner][_operator];
    }

    // **************************************************************
    // INTERNAL FUNCTIONS 
    // **************************************************************

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data)
    private ownerOnly(_tokenId) {
        _transferFrom(_from, _to, _tokenId);

        if (_to.isContract()) {
            // See if contract supports onERC721Received
            bytes4 returnVal = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
            require(returnVal == MAGIC_ON_ERC721_RECEIVED, 'recipient SC cannot accept ERC721 tokens');
        }

        emit Transfer(_from, _to, _tokenId);
   }

   function _transferFrom(address _from, address _to, uint256 _tokenId) private ownerOnly(_tokenId) {
        ownerToTokenCount[_from] -= 1;
        ownerToTokenCount[_to] += 1;
        tokenIdToOwner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    modifier ownerOnly(uint256 _tokenId) {
        address owner = tokenIdToOwner[_tokenId];
        require(
            msg.sender == owner ||    // sender is owner
            msg.sender == tokenIdToApprovedSender[_tokenId] ||    // sender is approved
            ownerToOperatorToAllowed[owner][msg.sender] == true,    // sender is operator
            'sender not authorized to transfer NFT'
        );
        _;
    }

}
