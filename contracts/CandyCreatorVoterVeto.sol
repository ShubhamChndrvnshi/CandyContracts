/***
 *    ░█████╗░░█████╗░███╗░░██╗██████╗░██╗░░░██╗  ░█████╗░██████╗░███████╗░█████╗░████████╗░█████╗░██████╗░
 *    ██╔══██╗██╔══██╗████╗░██║██╔══██╗╚██╗░██╔╝  ██╔══██╗██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗
 *    ██║░░╚═╝███████║██╔██╗██║██║░░██║░╚████╔╝░  ██║░░╚═╝██████╔╝█████╗░░███████║░░░██║░░░██║░░██║██████╔╝
 *    ██║░░██╗██╔══██║██║╚████║██║░░██║░░╚██╔╝░░  ██║░░██╗██╔══██╗██╔══╝░░██╔══██║░░░██║░░░██║░░██║██╔══██╗
 *    ╚█████╔╝██║░░██║██║░╚███║██████╔╝░░░██║░░░  ╚█████╔╝██║░░██║███████╗██║░░██║░░░██║░░░╚█████╔╝██║░░██║
 *    ░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝
 *
 *    
 *
 *
 *  “Growing up, I slowly had this process of realizing that all the things around me that people had told me 
 *  were just the natural way things were, the way things always would be, they weren’t natural at all. 
 *  They were things that could be changed, and they were things that, more importantly, were wrong and should change,
 *  and once I realized that, there was really no going back.”
 * 
 *    ― Aaron Swartz (1986-2013)
 *
 *
 * Version: VARIANT_BASE_NOTPROV_NOTAIRDROP_ERC721A_NOTENUMERABLE_CONTEXTV2
 *
 * Purpose: ERC-721 template for no-code users.
 *          Placeholder for pre-reveal information. 
 *          Guaranteed mint royalties with PaymentSplitter.
 *          EIP-2981 compliant secondary sale royalty information.
 *          Whitelist functionality. Caps whitelist users and invalidates whitelist users after mint.
 *          Deployable to ETH, AVAX, BNB, MATIC, FANTOM chains.
 *          
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./token/ERC721/ERC721A.sol";
import "./eip/2981/ERC2981Collection.sol";
import "./access/Ownable.sol";
import "./modules/PaymentSplitter.sol";
import "hardhat/console.sol";

contract CandyCreatorVoterVeto is ERC721A, ERC2981Collection, PaymentSplitter, Ownable {

  // bool = 1 byte
  // string = 64 bytes 
  // address = 20 bytes
  
  // @notice basic state variables

  // 256 BITS
  // Base URI prefix 
  string private base;
  
  // Maximum mints allowed in a publicMint transaction 
  uint256 private maxPublicMints = 1;
  // Price of each token 
  uint256 private mintPrice;
  // Planned size of the collection 
  uint256 private mintSize;
  // Unused for now 
  uint256 private revealTime;

  // Proposed basis points of the contract balance to release
  uint256 proposedReleaseBasisPoints; 
  // The start time of the last proposal
  // Proposal always ends 24 hours (86400 seconds) after start 
  uint256 private lastProposalStart;
  
  // Tracks the received yes votes 
  uint256 private proposalVetoCount;
  // Tracks received no votes
  uint256 private proposalRefundCount;

  // 256 BITS TOTAL
  // Used for a placeholder URI until one is set on the contract
  string private placeholderURI;

  // 256 BITS TOTAL
  // Merkle whitelist root hash
  bytes32 public whitelistMerkleRoot;

  // 160 BITS TOTAL
  // candyWallet address to allow for 5% transfer
  address private candyWallet;

  // 64 BITS TOTAL
  // Maximum mints allowed by a whitelisted user (defaults to 1)
  uint56 private maxWhitelistMints = 1;
  // Tracks the current proposal number
  uint8 private currentProposal;

  // 48 BITS TOTAL
  // Tracks whether whitelist is active/required
  bool private whitelistActive;
  // Tracks whether a proposal is active 
  bool private proposalActive;
  // Tracks whether to allow the withdrawal of the proposed release of funds  
  bool private proposalFailed;
  // Tracks whether the latest proposal has been claimed
  bool private proposalClaimed;
  // Whether minting is enabled 
  bool private mintingActive;
  // Whether the payees are locked in 
  bool private lockedPayees;
  // If refund is active
  bool private refundActive;
  // Price for the refund
  uint256 private refundPrice;

  event UpdatedRevealTimestamp(uint256 _old, uint256 _new);
  event UpdatedMintPrice(uint256 _old, uint256 _new);
  event UpdatedMintSize(uint _old, uint _new);
  event UpdatedMaxWhitelistMints(uint _old, uint _new);
  event UpdatedMaxPublicMints(uint _old, uint _new);
  event UpdatedMintStatus(bool _old, bool _new);
  event ProposedRelease(bool _old, bool _new);
  event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);
  event UpdatedWhitelistStatus(bool _old, bool _new);
  event UpdatedPresaleEnd(uint _old, uint _new);
  event PayeesLocked(bool _status);
  event UpdatedWhitelist(bytes32 _old, bytes32 _new);

  // @notice Contract constructor requires as much information 
  // about the contract as possible to avoid unnecessary function calls 
  // on the contract post-deployment. 
  constructor(string memory name, 
              string memory symbol, 
              string memory _placeholderURI,
              uint256 _mintPrice,
              uint256 _mintSize,
              address _candyWallet,
              bool _multi,
              address [] memory splitAddresses,
              uint256 [] memory splitShares) 
              ERC721A(name, symbol) {
                placeholderURI = _placeholderURI;
                candyWallet = _candyWallet;
                setMintPrice(_mintPrice);
                setMintSize(_mintSize);
                addPayee(_candyWallet, 500);
                if(!_multi) {
                  addPayee(_msgSender(), 9500);
                  lockPayees();
                } else {
                  for (uint i = 0; i < splitAddresses.length; i++) {
                    addPayee(splitAddresses[i], splitShares[i]);
                  }
                  lockPayees();
              }
  }

/***
 *    ███╗   ███╗██╗███╗   ██╗████████╗
 *    ████╗ ████║██║████╗  ██║╚══██╔══╝
 *    ██╔████╔██║██║██╔██╗ ██║   ██║   
 *    ██║╚██╔╝██║██║██║╚██╗██║   ██║   
 *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 */

  // @notice this is the mint function, mint Fees in ERC20,
  //  requires amount * mintPrice to be sent by caller
  // @param uint amount - number of tokens minted
  function whitelistMint(bytes32[] calldata merkleProof, uint56 amount) external payable {
    // @notice using Checks-Effects-Interactions
    require(mintingActive, "Minting not enabled");
    require(whitelistActive, "Whitelist not required, use publicMint()");
    require(_msgValue() == mintPrice * amount, "Wrong amount of Native Token");
    require(totalSupply() + amount <= mintSize, "Can not mint that many");
    require(amount <= maxWhitelistMints, "Exceeds maximum whitelist mints");
    require(
          MerkleProof.verify(
              merkleProof,
              whitelistMerkleRoot,
              keccak256(abi.encodePacked(_msgSender()))
          ),
          "Address not whitelisted"
    );
    // Invalidate the proposal if it hasn't passed 
    // If 24 hours have passed, the proposal is removed from active status
    if (block.timestamp - lastProposalStart > 86400) {
      proposalActive = false;
    }
    require(!proposalActive, "Can't mint during an active proposal");

    // Last 56 bits of the uint64 encodes the whitelist slots, get it, then add the amount
    // Saves 22k gas by avoiding traditional mapping lookup 
    uint64 aux = _getAux(_msgSender());

    // The uint56 value of the last 56 bits of the ERC721A uint64 aux variable
    uint56 numWhitelistMinted = uint56((aux) % 2 ** 56);

    // Add the number of tokens being minted 
    numWhitelistMinted += amount;

    // uint64 0xFF00000000000000 mask for the first 8 bits
    // Get the last voted proposal by shifting remaining bytes 56 places to the right
    uint8 lastVotedProposal = uint8((aux & 18374686479671623680) >> 56);

    // Generate the bytes
    bytes memory result = bytes.concat(bytes1(lastVotedProposal), bytes7(numWhitelistMinted));

    // Cast to uint64 type required by ERC721A
    uint64 newAux = uint64(bytes8(result));

    // Revert if whitelist slots exceeded 
    require(numWhitelistMinted <= maxWhitelistMints, "Not enough whitelist slots.");

    // Mint the token 
    _mint(_msgSender(), amount, '', false);

    // Set the ERC721A aux variable to the new generated uint64
    _setAux(_msgSender(), newAux); 
  }

  // @notice this is the mint function, mint Fees in ERC20,
  //  requires amount * mintPrice to be sent by caller
  // @param uint amount - number of tokens minted
  function publicMint(uint256 amount) external payable {
    require(!whitelistActive, "publicMint() disabled because whitelist is enabled");
    require(mintingActive, "Minting not enabled");
    require(_msgValue() == mintPrice * amount, "Wrong amount of Native Token");
    require(totalSupply() + amount <= mintSize, "Can not mint that many");
    require(amount <= maxPublicMints, "Exceeds public transaction limit");
    if (block.timestamp - lastProposalStart > 86400) {
      proposalActive = false;
    }
    require(!proposalActive, "Can't mint during an active proposal");
    _mint(_msgSender(), amount, '', false);
  }


/***
 *    ██████╗░░█████╗░██╗░░░██╗███╗░░░███╗███████╗███╗░░██╗████████╗
 *    ██╔══██╗██╔══██╗╚██╗░██╔╝████╗░████║██╔════╝████╗░██║╚══██╔══╝
 *    ██████╔╝███████║░╚████╔╝░██╔████╔██║█████╗░░██╔██╗██║░░░██║░░░
 *    ██╔═══╝░██╔══██║░░╚██╔╝░░██║╚██╔╝██║██╔══╝░░██║╚████║░░░██║░░░
 *    ██║░░░░░██║░░██║░░░██║░░░██║░╚═╝░██║███████╗██║░╚███║░░░██║░░░
 *    ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚══╝░░░╚═╝░░░
 * This section pertains to mint fees, royalties, and fund release.
 */

  // Function to receive ether, msg.data must be empty
  receive() external payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  // Function to receive ether, msg.data is not empty
  fallback() external payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  // Needs to be edited CHANGE THIS
  // @notice will release funds from the contract to the addresses
  // owed funds as passed to constructor 
  function release() external onlyOwner {
    // Require that the latest proposal was not vetoed or sent to refund mode
    require(!proposalFailed, "Proposal was rejected");
    // Require that the latest proposal funds haven't already been claimed
    // makes sure the owner can only call this function 1 time 
    require(!proposalClaimed, "Latest proposal funds already claimed");
    // Mark the proposal funds as claimed before the release to
    // prevent re-entrancy
    if (block.timestamp - lastProposalStart > 86400) {
        proposalActive = false;
    }
    require(!proposalActive, "Voting hasn't ended");
    proposalClaimed = true;
    // Release the funds to those owed payment
    _release(proposedReleaseBasisPoints);
  }

  function refundRelease() external {
    // refund the user if refund is active 
    // and they haven't been refunded yet
    // Refund must be triggered by voters to call this function
    require(refundActive, "Refund has not been triggered");
    // might not be required
    require(proposalFailed, "The withdrawal proposal succeeded");
    // Caller must own tokens 
    require(balanceOf(_msgSender()) > 0, "User does not own any tokens");
    // Get the owner's auxilliary information
    uint64 aux = _getAux(_msgSender()); 
    uint8 lastVotedProposal = uint8((aux & 18374686479671623680) >> 56);
    // There are 100 proposals and 101 integer code means the refund has been claimed 
    require(lastVotedProposal != 101, "Refund already claimed");
    uint256 voterBalance = balanceOf(_msgSender());
      // The uint56 value of the last 56 bits of the ERC721A uint64 aux variable
    uint56 numWhitelistMinted = uint56((aux) % 2 ** 56);

    lastVotedProposal = uint8(101);

    // Generate the bytes
    bytes memory result = bytes.concat(bytes1(lastVotedProposal), bytes7(numWhitelistMinted));

    // Cast to uint64 type required by ERC721A
    uint64 newAux = uint64(bytes8(result));

    // Set the ERC721A aux variable to the new generated uint64
    _setAux(_msgSender(), newAux); 

    _refundRelease(_msgSender(), refundPrice*voterBalance);
  }

  function platformRelease() external {
    // Only the Candy Chain platform can call this function 
    require(_msgSender() == candyWallet);
    _platformRelease();
  }

  // @notice this will use internal functions to set EIP 2981
  //  found in IERC2981.sol and used by ERC2981Collections.sol
  // @param address _royaltyAddress - Address for all royalties to go to
  // @param uint256 _percentage - Precentage in whole number of comission
  //  of secondary sales
  function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage) public onlyOwner {
    _setRoyalties(_royaltyAddress, _percentage);
    emit UpdatedRoyalties(_royaltyAddress, _percentage);
  }

  // @notice this will set the fees required to mint using
  //  publicMint(), must enter in wei. So 1 ETH = 10**18.
  // @param uint256 _newFee - fee you set, if ETH 10**18, if
  //  an ERC20 use token's decimals in calculation
  function setMintPrice(uint256 _newFee) public onlyOwner {
    uint256 oldFee = mintPrice;
    mintPrice = _newFee;
    emit UpdatedMintPrice(oldFee, mintPrice);
  }

  // @notice will add an address to PaymentSplitter by owner role
  // @param address newAddy - address to recieve payments
  // @param uint newShares - number of shares they recieve
  function addPayee(address newAddy, uint newShares) private {
    require(!lockedPayees, "Can not set, payees locked");
    _addPayee(newAddy, newShares);
  }

  // @notice Will lock the ability to add further payees on PaymentSplitter.sol
  function lockPayees() private {
    require(!lockedPayees, "Can not set, payees locked");
    lockedPayees = true;
    emit PayeesLocked(lockedPayees);
  }

/***
 *    
 *    ░█████╗░██████╗░███╗░░░███╗██╗███╗░░██╗
 *    ██╔══██╗██╔══██╗████╗░████║██║████╗░██║
 *    ███████║██║░░██║██╔████╔██║██║██╔██╗██║
 *    ██╔══██║██║░░██║██║╚██╔╝██║██║██║╚████║
 *    ██║░░██║██████╔╝██║░╚═╝░██║██║██║░╚███║
 *    ╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝
 * This section pertains to to basic contract administration tasks. 
 */

  // @notice this will enable publicMint()
  function enableMinting() external onlyOwner {
    bool old = mintingActive;
    mintingActive = true;
    emit UpdatedMintStatus(old, mintingActive);
  }

  // @notice this will disable publicMint()
  function disableMinting() external onlyOwner {
    bool old = mintingActive;
    mintingActive = false;
    emit UpdatedMintStatus(old, mintingActive);
  }

  // @notice this will enable whitelist or "if" in publicMint()
  function enableWhitelist() external onlyOwner {
    bool old = whitelistActive;
    whitelistActive = true;
    emit UpdatedWhitelistStatus(old, whitelistActive);
  }

  // @notice this will disable whitelist or "else" in publicMint()
  function disableWhitelist() external onlyOwner {
    bool old = whitelistActive;
    whitelistActive = false;
    emit UpdatedWhitelistStatus(old, whitelistActive);
  }

  // @notice this will set a new Merkle root used to verify whitelist membership
  // together with a proof submitted to the mint function  
  // @param bytes32 _merkleRoot - generated merkleRoot hash  
  function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 old = whitelistMerkleRoot;
        whitelistMerkleRoot = _merkleRoot;
        emit UpdatedWhitelist(old, whitelistMerkleRoot);
  }

  // @notice this will set the maximum number of tokens a whitelisted user can mint.
  // @param uint256 _amount - max amount of tokens
  function setMaxWhitelistMints(uint56 _amount) public onlyOwner {
    uint256 oldAmount = maxWhitelistMints;
    maxWhitelistMints = _amount;
    emit UpdatedMaxWhitelistMints(oldAmount, maxWhitelistMints);
  }

  // @notice this will set the maximum number of tokens a single address can mint at a time
  // during the public mint period. Keep in mind that user will be able to transfer their tokens
  // to a different address, and continue minting this amount of tokens on each transaction. 
  // If you wish to prevent this, use the whitelist. 
  // @param uint256 _amount - max amount of tokens
  function setMaxPublicMints(uint256 _amount) public onlyOwner {
    uint256 oldAmount = maxPublicMints;
    maxPublicMints = _amount;
    emit UpdatedMaxPublicMints(oldAmount, maxPublicMints);
  }

  // @notice this updates the base URI for the token metadata
  // it does not emit an event so that it can be set invisibly to purchasers
  // and avoid token sniping 
  // @param string _ - max amount of tokens
  function setBaseURI(string memory baseURI) public onlyOwner {
        base = baseURI;
  }

  // @notice will set mint size by owner role
  // @param uint256 _amount - set number to mint
  function setMintSize(uint256 _amount) public onlyOwner {
    uint256 old = mintSize;
    mintSize = _amount;
    emit UpdatedMintSize(old, mintSize);
  }

  // @notice this will set the reveal timestamp
  // This is more for your API and not on-chain...
  // @param uint256 _time - uinx time stamp for reveal (use with API's only)
  function setRevealTimestamp(uint256 _timestamp) public onlyOwner {
    uint256 old = revealTime;
    revealTime = _timestamp;
    emit UpdatedRevealTimestamp(old, revealTime);
  }
  

/***
 *    
 *██╗░░░██╗░█████╗░████████╗██╗███╗░░██╗░██████╗░
 *██║░░░██║██╔══██╗╚══██╔══╝██║████╗░██║██╔════╝░
 *╚██╗░██╔╝██║░░██║░░░██║░░░██║██╔██╗██║██║░░██╗░
 *░╚████╔╝░██║░░██║░░░██║░░░██║██║╚████║██║░░╚██╗
 *░░╚██╔╝░░╚█████╔╝░░░██║░░░██║██║░╚███║╚██████╔╝
 *░░░╚═╝░░░░╚════╝░░░░╚═╝░░░╚═╝╚═╝░░╚══╝░╚═════╝░
 * This section pertains to governance and voting. 
 */

  // Allows a token holder to vote on whether the owner should be allowed to withdraw funds
  function vote(bool approve) external {

    // Similarily if there is not an active proposal there is no voting
    require(proposalActive, "Proposal is not active");
    
    // Require that voting is still available (within 24 hours of lastProposalStart)
    require(block.timestamp - lastProposalStart < 86400, "Voting has ended");
    
    // Require the voter to be a token holder 
    uint256 voterBalance = balanceOf(_msgSender());
    require(balanceOf(_msgSender()) > 0, "User does not own any tokens");

    // Get the owner's auxilliary information
    uint64 aux = _getAux(_msgSender()); 

    // uint64 0xFF00000000000000 mask for the first 8 bits
    // Get the last voted proposal by shifting remaining bytes 56 places to the right
    uint8 lastVotedProposal = uint8((aux & 18374686479671623680) >> 56);

    // The uint56 value of the last 56 bits of the ERC721A uint64 aux variable
    uint56 numWhitelistMinted = uint56((aux) % 2 ** 56);

    // Revert execution if the user has already voted
    require(lastVotedProposal != currentProposal, "User has already voted on current proposal");

    // Generate the new aux bytes 
    bytes memory result = bytes.concat(bytes1(currentProposal), bytes7(numWhitelistMinted));

    // Cast to uint64 type required by ERC721A
    uint64 newAux = uint64(bytes8(result));
    // Set the ERC721A aux variable
    _setAux(_msgSender(), newAux); 

    // If the user approved the release
    if (approve == true) {
      // Add the VETO votes
      proposalVetoCount += voterBalance;
    } else {
      // Add the REFUND votes
      proposalRefundCount += voterBalance;
    }

    // Check to see if a 60% quorum has been met 
    // (60% of totalSupply of tokens regardless of collection size of if they minted out)
    // (50% + 10%)
    if (proposalVetoCount + proposalRefundCount > ( (totalSupply() / 2) + (totalSupply() / 10) )) {

      if (proposalRefundCount > proposalVetoCount) {
        refundActive = true;
        refundPrice = address(this).balance / totalSupply();
      }
      // of the above outcome
      // The proposal failed, banning the proposed withdrawal
      // 1) Nothing occurs and the contract owner can propose \
      // another release after a timeout
      // 2) A refund was triggered and token holders will now be reimbursed 
      // If either events occur, the proposal is marked as failed 
      proposalFailed = true;
      // The proposal has ended 
      proposalActive = false;
    }

    
    
  }

  // Basis points measured out of 10,000 
  // Use smaller uint size for basisPoints since it's bounded?
  function proposeRelease(uint256 basisPoints) external onlyOwner {

    // https://blog.openzeppelin.com/bypassing-smart-contract-timelocks/

    // Max proposal number 7-bit unsigned integer = 2^7 - 1 = 127
    // Prevents overflow error
    require(currentProposal < 100, "Maximum proposals reached");

    // If this is the last possible proposal, owner must request the full remaining balance
    if (currentProposal == 99) {
      require(basisPoints == 10000, "Must request full balance on last proposal");
    }

    // Require that there is no active proposal 
    require(!proposalActive, "Release already proposed by contract owner");

    // There must be funds in the contract to initiate a proposal
    require(address(this).balance > 0, "Contract must have a non-zero balance to release funds");

    // Require that the basis points are less than or equal to maximum
    // and non-zero (would result in no funds being released)
    require(basisPoints !=0 && basisPoints <= 10000, "Invalid basis points value");

    // Check for subsequent proposal
    if (lastProposalStart != 0) {
      // Owner cannot trigger a new proposal within one week (604,800 seconds) of triggering the first one 
      require(block.timestamp - lastProposalStart > 604800, "Owner has already proposed release in past week");
      require(proposalClaimed, "You need to claim your funds before proposing another release");
    }

    // Save old value to emit event
    bool old = proposalActive;

    // Set the start time for the latest proposal
    // to the current block timestamp
    lastProposalStart = block.timestamp;
    
    // Increment the proposal number
    currentProposal += 1;
    
    // Set flag to false if it's true
    proposalFailed = false;

    // On the first proposal this will be set to false explicitly
    // If this is a subsequent proposal, proposalClaimed is guaranteed to be true 
    proposalClaimed = false;

     // Set the proposed basis points for the contract balance withdrawal
    proposedReleaseBasisPoints = basisPoints;

    // The proposal now becomes active
    proposalActive = true;

    // emit event
    emit ProposedRelease(old, proposalActive); 
  }

/***
 *    ██████╗░██╗░░░██╗██████╗░██╗░░░░░██╗░█████╗░  ██╗░░░██╗██╗███████╗░██╗░░░░░░░██╗░██████╗
 *    ██╔══██╗██║░░░██║██╔══██╗██║░░░░░██║██╔══██╗  ██║░░░██║██║██╔════╝░██║░░██╗░░██║██╔════╝
 *    ██████╔╝██║░░░██║██████╦╝██║░░░░░██║██║░░╚═╝  ╚██╗░██╔╝██║█████╗░░░╚██╗████╗██╔╝╚█████╗░
 *    ██╔═══╝░██║░░░██║██╔══██╗██║░░░░░██║██║░░██╗  ░╚████╔╝░██║██╔══╝░░░░████╔═████║░░╚═══██╗
 *    ██║░░░░░╚██████╔╝██████╦╝███████╗██║╚█████╔╝  ░░╚██╔╝░░██║███████╗░░╚██╔╝░╚██╔╝░██████╔╝
 *    ╚═╝░░░░░░╚═════╝░╚═════╝░╚══════╝╚═╝░╚════╝░  ░░░╚═╝░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═════╝░
 */
 
  // @notice will return the current proposal number
  function latestProposal() external view  returns (uint8) {
    return currentProposal;
  }

  // @notice will return YES votes for the current proposal
  function vetoCount() external view  returns (uint256) {
    return proposalVetoCount;
  }

  // @notice will return NO votes for the current proposal
  function refundCount() external view  returns (uint256) {
    return proposalRefundCount;
  }

  // @notice will return whether the current proposal has passed
  function proposalDidFail() external view  returns (bool) {
    return proposalFailed;
  }

  // @notice will return whether there is an active proposal
  function proposalIsActive() external view returns (bool) {
    return proposalActive;
  }

  // @notice will return the basis points (out of 10,000)
  // requested by the proposal
  function proposalBasisPoints() external view returns (uint256) {
    return proposedReleaseBasisPoints;
  }

  // @notice will return whether minting is enabled
  function mintStatus() external view  returns (bool) {
    return mintingActive;
  }

  // @notice will return whitelist status of Minter
  function whitelistStatus() external view returns (bool) {
    return whitelistActive;
  }

  // @notice will return the reveal timestamp for use by off-chain API to conditionally render
  // mint button 
  function revealTimestamp() external view returns (uint) {
    return revealTime;
  }

  // @notice will return minting fees
  function mintingFee() external view returns (uint256) {
    return mintPrice;
  }

  // @notice will return whitelist status of Minter
  function whitelistMaxMints() external view returns (uint256) {
    return maxWhitelistMints;
  }

  // @notice will return maximum tokens that are allowed to be minted during a single transaction
  // during the whitelist period
  function publicMaxMints() external view returns (uint256) {
    return maxPublicMints;
  }

  // @notice this is a public getter for ETH balance on contract
  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

  // @notice will return the planned size of the collection
  function collectionSize() external view returns (uint256) {
    return mintSize;
  }

  /***
 *    ░█████╗░██╗░░░██╗███████╗██████╗░██████╗░██╗██████╗░███████╗
 *    ██╔══██╗██║░░░██║██╔════╝██╔══██╗██╔══██╗██║██╔══██╗██╔════╝
 *    ██║░░██║╚██╗░██╔╝█████╗░░██████╔╝██████╔╝██║██║░░██║█████╗░░
 *    ██║░░██║░╚████╔╝░██╔══╝░░██╔══██╗██╔══██╗██║██║░░██║██╔══╝░░
 *    ╚█████╔╝░░╚██╔╝░░███████╗██║░░██║██║░░██║██║██████╔╝███████╗
 *    ░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═════╝░╚══════╝
 */

  // @notice Solidity required override for _baseURI(), if you wish to
  //  be able to set from API -> IPFS or vice versa using setBaseURI(string)
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice Override for ERC721A _startTokenId to change from default 0 -> 1
  function _startTokenId() internal view override returns (uint256) {
    return 1;
  }

  // @notice Override for ERC721A tokenURI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json")) : placeholderURI;
  }

  // @notice Override ERC721A method to prevent token transfer during an active proposal
  function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
  ) internal override {
    // If there is an active proposal blocking minting and transfer
    // and the voting period has expired (24 hours / 86400 seconds)
    // then we remove the block
    if (block.timestamp - lastProposalStart > 86400) {
      proposalActive = false;
    }
    require(!proposalActive, "Token transfers are paused during voting period");
  }

  // @notice solidity required override for supportsInterface(bytes4)
  // @param bytes4 interfaceId - bytes4 id per interface or contract
  // calculated by ERC165 standards automatically
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
    return (
      interfaceId == type(ERC2981Collection).interfaceId  ||
      interfaceId == type(PaymentSplitter).interfaceId ||
      interfaceId == type(Ownable).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }

}
