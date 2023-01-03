// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract /* Your Contract Name */  is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private baseURI;
    string public baseExtension = ".json";
    string public hiddenURI;
    bool public mintActive = false;
    bool public revealLive = false;
    uint256 public supply = /* Maximum supply of you NFT collection */;
    uint256 public mintLimit = /* Maximum mint limit per 1 wallet */;
    uint256 private reserve = /* Amount of NFTS reserved for the owner */;
    uint256 private freeMints = /* Amount of free mints per wallet. Set 0 if you want all payable. */;
    uint256 public cost = /* Cost of a 1 NFT in Wei */;

    constructor() ERC721A("Your Collection Name", "YCN") {}

    
    modifier mintActiveCompliance(uint256 _count) {
        require(mintActive, "Mint is not active!");
        _;
    }

    modifier mintLimitCompliance(uint256 _count) {
        require(
            _numberMinted(msg.sender) + _count <= mintLimit,
            "Requested mint amount too big!"
        );
        _;
    }

    modifier supplyCompliance(uint256 _count) {
        require(
            totalSupply() + _count <= supply - reserve,
            "Requested mint count exceeds the supply!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _count) {
        require(msg.value >= cost * _count, "Not enough ETH to mint!");
        _;
    }

    function mintFree(
        uint256 _count
    )
        external
        nonReentrant
        mintActiveCompliance(_count)
        mintLimitCompliance(_count)
    {       

        require(msg.sender == tx.origin, "Contracts can't mint!");
        require(
            totalSupply() + _count <= freeMints,
            "Requested mint count exceeds free mint supply!"
        );

        _safeMint(msg.sender, _count);
    }

    function mint(
        uint256 _count
    )
        external
        payable
        nonReentrant
        mintActiveCompliance(_count)
        supplyCompliance(_count)
        mintLimitCompliance(_count)
        mintPriceCompliance(_count)
        
    {
        require(msg.sender == tx.origin, "contracts can't mint");
        _safeMint(msg.sender, _count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealLive == false) {
            return hiddenURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,_tokenId.toString(),baseExtension)): "";
    }

    function reserveTokens(
        address owner,
        uint256 _count
    ) external nonReentrant onlyOwner {
        require(
            _count <= reserve,
            "Requested mint count exceeds reserve limit!"
        );
        _safeMint(owner, _count);
        reserve = reserve - _count;
    }

    function releaseReserve() external onlyOwner {
        reserve = 0;
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function setReveal() public onlyOwner {
        revealLive = true;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setHiddenURI(string memory _hiddenURI) external onlyOwner {
            hiddenURI = _hiddenURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}



//Ivan Falimendikov 2023