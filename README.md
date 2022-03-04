![Logo](https://res.cloudinary.com/candy-labs/image/upload/v1644974796/smaller_dep6qo.png)
</br>
</br>
![Twitter](https://img.shields.io/twitter/follow/Candy_Chain_?style=social)
![GithubFollow](https://img.shields.io/github/followers/Candy-Labs?style=social)

# CandyCreatorV1A Governance
Variant of the CandyCreatorV1A base contract that restricts the owner from releasing funds without first passing a community vote by the token holders.

## Voting 
### Proposing a release (Project Creator)
In order for the contract owner to release funds from the contract into their own account, they must first propose a release measured in basis points measured out of 10,000. 
```javascript
function proposeRelease(uint256 basisPoints) external onlyOwner
```
So to propose the release of 25% of the contract owner would call:
```javascript
proposeRelease(2500)
```
**Requirements**
* There is no active proposal `bool private proposalActive`
* Basis points must be between 0 and 10,000
* There is a limit of 100 proposals
* The final 100th proposal must request the full contract balance (10,000 basis points)
* There must be a positive balance on the contract 
* The owner cannot make a release proposal if one was started in the last 7 days (604,800 seconds)
* Once the proposal is started, `require` statements in the mint functions and `beforeTokenTransfers` will prevent the transfer or minting of tokens
* If a previous proposal passed, and funds were made available to the owner for release, they must claim those funds before activating a new proposal

### Voting (NFT Owner)
During each proposal stage, the owners of the NFT have the ability to approve the withdrawal or trigger a refund of the current contract balance distributed to owners proportional to the value returned by `balanceOf`.
```javascript
function vote(bool approve) external
```
To approve the release to the address(es) owed payment by the mint earnings split in the CandyCreatorV1A contract:
```javascript
vote(true)
```
To reject the approval and vote for reimbursement
```javascript
vote(false)
```
If you would rather neither action occur then simply abstain from voting. 
**Requirements**
* There is an active proposal
* Less than 24 hours (86,400 seconds) have elapsed since the beginning of the voting period
* The user owns tokens in the project (`balanceOf(_msgSender())` > 0)
* The user has not already cast a vote for the current proposal number. The `uint8 private currentProposal` state variable tracks the current proposal for the contract. This value is checked against the 8-bit integer interpretation of the first byte of the `uint64 aux` variable in ERC721A. If they match, it means the user has already voted on that proposal. 
* The first 8 bits of the aforementioned variable are updated in the ERC721A AddressData before incrementing the variables which track true/false vote counts. 

### Passing Proposals 
The `vote(bool approve)` function previously discussed is responsible for moving a proposal from active and pending to successfully passed. 
```javascript
if (proposalYesCount + proposalNoCount > ( (totalSupply() / 2) + (totalSupply() / 10) )) {
      // Once quorum is met, majority vote 
      if (proposalYesCount > proposalNoCount) {
        // PROPOSAL PASSED
        proposalPassed = true;
      } else {
        // PROPOSAL FAILED
        proposalPassed = false;
        refundPrice = address(this).balance / totalSupply();
        refundActive = true;
      }
      // The proposal has ended and is no longer active
      proposalActive = false;
}
```
If a quorum is met (Currently 1/2 + 1/10 = 60%), then a simple majority determines either of the two outcomes:
* The proposal is passed and deactivated, the funds are available for release by the contract owner
* The proposal is rejected in favor of a refund of the remaining contract balance to the token holders

If a quorum is not met and a proposal is not decided, any call to the `publicMint` or `whitelistMint` or `transfer` will inactivate the proposal and make minting and transfer of tokens available to the community again.

### Releasing Funds (Project Creator)
If a proposal passes the owner will be able to release funds to the payees they configured in Candy Chain web platform (See `PaymentSplitter.sol`).
```javascript
  // @notice will release funds from the contract to the addresses
  // owed funds as passed to constructor 
  function release() external onlyOwner {
    // Require that the latest proposal passed 
    require(proposalPassed, "Proposal did not pass");
    // Require that the latest proposal funds haven't already been claimed
    require(!proposalClaimed, "Latest proposal funds already claimed");
    // Mark the proposal funds as claimed before the release to
    // prevent re-entrancy
    proposalClaimed = true;
    // End the proposal and re-enable minting and transfer
    proposalActive = false;
    // Release the funds to those owed payment
    _release(proposedReleaseBasisPoints);
  }
```
### Platform Fee (Candy Chain)
Anyone is welcome to fork this code and create their own version without this functionality but this implementation allows the address passed as `candyWallet` to the constructor to withdraw a 5% platform fee from the mint earnings without voter approval.

### Limitations 
We haven't yet tested the gas fee for voting. This code is in alpha release status and shouldn't be considered production-ready without further community input and support. Please open an issue if you find security vulnerabilities in this contract.

### Roadmap 
* Integrate with Snapshot/SnapshotX and enable gasless voting (perhaps with Layer 2 Rollup)

## Base Features 
* Minimal Setup
* Gas-Optimized
* ERC721A Batch Minting
* Flexible Mint Royalties
* Merkle Proof Whitelist
* Pending Reveal

## Security 
* Access Control
* Re-entrancy safe mint functions

## Testing / Auditing 
To start using these contracts with [Hardhat](https://hardhat.org/) simply run the following commands:
1. `npm install`
2. `npx hardhat compile` or `npx hardhat test`
