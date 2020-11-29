pragma solidity >=0.4.22 <0.8.0;

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

contract MockGoodRecipient is ERC721TokenReceiver {
    // Mock variables
    address private operator;
    address private from;
    uint256 private tokenId;
    bytes private data;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
    external returns (bytes4) {
        operator = _operator;
        from = _from;
        tokenId = _tokenId;
        data = _data;

        // Mock received transaction
        return MAGIC_ON_ERC721_RECEIVED;
    }

}

