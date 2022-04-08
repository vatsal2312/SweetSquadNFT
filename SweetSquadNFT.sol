//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract SweetSquadNFT is ERC721, ERC721Enumerable, Ownable {

	uint public constant MAX_TOKENS = 9975;
	uint public constant MAX_TOKENS_VIP = 25;
	
	uint private _currentToken = 0;
	
	uint public CURR_MINT_COST = 0.01 ether;
	
	//---- Round based supplies
	string private CURR_ROUND_NAME = "Presale";
	uint private CURR_ROUND_SUPPLY = 500;
	uint private CURR_ROUND_TIME = 0;
	uint private maxMintAmount = 5;
	uint private nftPerAddressLimit = 20;
	bytes32 private verificationHash = 0x8823bdb34f3cea44b8f49a36bb34623948834fb1612a4abaa8574522dbec0a0e;
	
	uint private currentVIPs = 0;
	
	bool public hasSaleStarted = false;
	bool public onlyWhitelisted = false;
	bool public traditional = false;
	
	string public baseURI;
	
    uint256 private remaining = MAX_TOKENS;
    mapping(uint256 => uint256) private cache;
	mapping (address => bool) private whitelistUserAddresses;
	
	constructor() ERC721("Sweet Squad", "SweetSquad") {
		setBaseURI("http://api.sweetsquadnft.com/sweetsquad/");
	}

	function totalSupply() public view override returns(uint) {
		return _currentToken;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
	
	function walletOfOwner(address _owner) public view returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}


	function mintNFT(uint _mintAmount, bytes32[] memory proof) external payable {
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
		require((_mintAmount  + balanceOf(msg.sender)) <= nftPerAddressLimit, "Max NFT per address exceeded");

        if(onlyWhitelisted == true) {
			if(traditional)
			{
				require(isWhitelisted(msg.sender), "User is not whitelisted");
			}
			else
			{
				bytes32 user = keccak256(abi.encodePacked(msg.sender));
				require(verify(user,proof), "User is not whitelisted");
			}
        }

		for (uint256 i = 1; i <= _mintAmount; i++) {
			_currentToken++;
			CURR_ROUND_SUPPLY--;
			_safeMint(msg.sender, _currentToken);
		}
	}
	
	
   function getInformations() external view returns (string memory, uint, uint, uint, uint,uint ,bool,bool)
   {
		return (CURR_ROUND_NAME,CURR_ROUND_SUPPLY,CURR_ROUND_TIME,CURR_MINT_COST,maxMintAmount,nftPerAddressLimit, hasSaleStarted, onlyWhitelisted);
   }
	
	function verify(bytes32 user, bytes32[] memory proof) internal view returns (bool)
	{
		bytes32 computedHash = user;

		for (uint256 i = 0; i < proof.length; i++) {
			bytes32 proofElement = proof[i];

			if (computedHash <= proofElement) {
				computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
			} else {
				computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
			}
		}
		return computedHash == verificationHash;
	}
	
	function isWhitelisted(address _user) public view returns (bool) {
		return whitelistUserAddresses[_user];
	}

	//only owner functions
	
	function setNewRound(uint _supply, uint cost, string memory name, uint perTransactionLimit, uint perAddressLimit, uint theTime, bool isOnlyWhitelisted, bool saleState) external onlyOwner {
		require(_supply <= (MAX_TOKENS - _currentToken), "Exceeded supply");
		CURR_ROUND_SUPPLY = _supply;
		CURR_MINT_COST = cost;
		CURR_ROUND_NAME = name;
		maxMintAmount = perTransactionLimit;
		nftPerAddressLimit = perAddressLimit;
		CURR_ROUND_TIME = theTime;
		hasSaleStarted = saleState;
		onlyWhitelisted = isOnlyWhitelisted;
	}

	function setVerificationHash(bytes32 hash) external onlyOwner
	{
		verificationHash = hash;
	}	
	
	function setOnlyWhitelisted(bool _state, bool _traditional) external onlyOwner {
		onlyWhitelisted = _state;
		traditional = _traditional;
	}

	function whitelistAddresses (address[] calldata users) public onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			whitelistUserAddresses[users[i]] = true;
		}
	}

	function removeWhitelistAddresses (address[] calldata users) external onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			delete whitelistUserAddresses[users[i]];
		}
	}
	
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function reserveVIP(uint numTokens, address recipient) external onlyOwner {
		require((currentVIPs + numTokens) <= MAX_TOKENS_VIP, "Exceeded VIP supply");
		uint index;
		for(index = 1; index <= numTokens; index++) {
			_currentToken++;
			currentVIPs = currentVIPs + 1;
			uint theToken = currentVIPs + MAX_TOKENS;
			_safeMint(recipient, theToken);
		}
	}

	function Giveaways(uint numTokens, address recipient) external onlyOwner {
		require((_currentToken + numTokens) <= MAX_TOKENS, "Exceeded supply");
		uint index;
		for(index = 1; index <= numTokens; index++) {
			_currentToken++;
			_safeMint(recipient, _currentToken);
		}
	}

	function withdraw(uint amount) external onlyOwner {
		require(payable(msg.sender).send(amount));
	}
	
	
	function setSaleStarted(bool _state) external onlyOwner {
		hasSaleStarted = _state;
	}
}
