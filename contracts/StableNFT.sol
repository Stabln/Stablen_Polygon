// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUSDT {
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
}
interface IUSDC {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint256) external;
}


/*
//                           ***DEMO***
//  This contract has only two functions, mintWithTenUSD() and redeem().
//  mintWithTenUSD(): User can mint by paying 10 USD
//  redeem(): redeem USD they paid, and return NFT to this contract
//  * In Demo,
//  * 1. Only USDC is used
//  * 2. After redeem, NFT is lock into contract.
*/ 
contract Stablen is ERC721, Ownable{

// using SafeERC20 for IERC20

    struct NFTInfo{
        uint256 tokenId;
        address paymentToken;
        uint256 tokenAmount;
        address owner;
    }

    uint256 public totalSupply;
    uint256 public totalSupplyTenUSD;
    uint256 public totalSupplyFiftyUSD;
    mapping (uint256 => NFTInfo) public NFTInfos; // token Id => NFTInfo

    // munbai USTC: 0xFEca406dA9727A25E71e732F9961F680059eF1F9
    address public immutable USDT;
    address public immutable USDC;
    
    event totalSupplyAdded(uint256);
    event mintNFT_FiftyUSD(address owner, uint256 tokenId);
    event mintNFT_TenUSD(address owner, uint256 tokenId);

    constructor(uint256 _totalSupply, address _USDC, address _USDT) ERC721("Stablen",  "STB") {
        require(_USDC != address(0), "USDC is ZERO ADDRESS");
        require(_USDT != address(0), "USDT is ZERO ADDRESS");

        USDT = _USDT;
        USDC = _USDC;
        totalSupply = _totalSupply;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "needBaseURI";
    }

    
    /// @notice Newly mint NFT worth 10 USD
    /// @dev Transfers the `paymentToken` from `msg.sender` to the contract
    /// @dev must approved before use `transferFrom`, `paymentToken.approve(...)`
    /// @param paymentToken USDC or USDT, only USDC for DEMO
    function mintWithTenUSD(address paymentToken) public {
        require(totalSupplyTenUSD < 50, "exceed total supply");
        uint256 tokenId = totalSupplyTenUSD;
        
        // must approve the contract for payment
        if(paymentToken == USDT){
            IUSDT(USDT).transferFrom(msg.sender, address(this), 10*10**6);
        } else if(paymentToken == USDC){
        // USDC payment
            IUSDC(USDC).transferFrom(msg.sender, address(this), 10*10**6);
        } else{
            revert("Wrong Payment Token");
        }
 
        NFTInfos[tokenId] = NFTInfo(
            tokenId,
            paymentToken,
            10*10**6,
            msg.sender
        );

        totalSupplyTenUSD++;
        _safeMint(msg.sender, tokenId);

        emit mintNFT_TenUSD(msg.sender, tokenId);
    }


    /// @notice Users can redeem USDT or USDC, and return NFT to contract
    /// @dev Transfers the `paymentToken` to `msg.sender` and `safeTransferFrom` NFT to address(this)
    /// @param tokenId USDC or USDT, only USDC for DEMO
    function redeem(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender,"Not Owner");

        // later used for payment
        NFTInfo memory tokenInfo = NFTInfos[tokenId];

        NFTInfos[tokenId] = NFTInfo(
            tokenId,
            address(0),
            10*10**6,
            address(this)
        );
        // token 회수
        safeTransferFrom(msg.sender, address(this), tokenId);
        
        // token 돈 다시 보내주기
        // maybe just use safeTransfer
        if(tokenInfo.paymentToken == USDT){
            IUSDT(USDT).transfer(tokenOwner, tokenInfo.tokenAmount);
        } else {
            IUSDC(USDC).transfer(tokenOwner, tokenInfo.tokenAmount);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

}