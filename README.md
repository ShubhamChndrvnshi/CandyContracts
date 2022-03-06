![Logo](https://res.cloudinary.com/candy-labs/image/upload/v1644974796/smaller_dep6qo.png)
</br>
</br>
![Twitter](https://img.shields.io/twitter/follow/Candy_Chain_?style=social)
![GithubFollow](https://img.shields.io/github/followers/Candy-Labs?style=social)

Documentation work-in-progress

# CandyCreatorV1A Governance
Variant of the CandyCreatorV1A base contract that restricts the owner from releasing funds without first passing a community vote by the token holders. Thank you to the authors and maintainers of the [ERC721A](https://github.com/chiru-labs/ERC721A) repository for making this possible.

There are two variants of this token:
CandyCreatorVoterVeto
CandyCreatorVoterApprove

It's important to note that these are unaudited and security flaws are likely to exist, and possibilities for abuse of the governance protocol by both the contract owner and the token holders needs to be considered. A refund should perhaps not always be an option. A refund could allow token holders to always be able to refund the mint price but keep the token. We may need the Enumerable extension functions to properly burn each users token.

# CandyCreatorVoterApprove
This governance variant of the CandyCreatorV1A base contract requires the contract owner to propose a release of some percentage of the contract balance (measured in basis points). If this proposal is not explicitly approved by the token holders, it does not pass and nothing happens. At each proposal stage, voters can choose 3 options. 

There is added security in this variant in that contract owners can't 'sneakily' pass a proposal (in CandyCreatorVoterVeto, proposals pass by default). However, this added benefit is matched by the fact that project creators / contract owners will have to convince their community members to vote and pay a gas fee for the on-chain voting just to release funds to the owner (it is hard to convince people to spend money for a transaction fee that just enriches another party). 

## Abstain from voting
If the token holder abstains from voting, they are voting for nothing to occur. If they abstain, and enough token holders do also, nothing will occur on the contract. 

## Approve the withdrawal proposal
Call `vote(true)` to cast your votes to approve the proposal. 

## Request a refund
Call `vote(false)` to cast your votes to approve a refund. 

# CandyCreatorVoterVeto
This governance variant of the CandyCreatorV1A base contract requires the contract owner to propose a release of some percentage of the contract balance (measured in basis points). If this proposal is not rejected by token holders (vetoed), it will take place after the voting period has concluded (24 hours). 

The disadvantage to this variant is that contract owners could 'sneakily' propose a release without informing token holders (there is no guaranteed way to alert them and the alert would have to be through an off-chain system) and if the proposal is not discovered to be active by token holders in time, they will not have time to vote to reject the proposal. We are planning to experiment with extending the voting period for this variant (but this will prevent minting and token transfer during this period). 

The advantage to this variant is that the contract owner doesn't need to ask users to spend gas to approve the withdrawal. It is also very difficult to reach quorums in certain communities. Instead, token holders spend gas to secure an outcome that would directly economically benefit them (preventing the withdrawal by the owners and a 'rug pull' or refunding themselves. 

## Abstain from voting
If the token holder abstains from voting, they will allow the release to move forward after the voting period has concluded.

## Veto/reject the withdrawal proposal
Call `vote(true)` to cast your votes to veto the withdrawal.

## Request a refund
Call `vote(false)` to cast your votes to approve a refund. 

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

### Passing Proposals (Internal Logic)
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
* Integrate with [Snapshot](https://docs.snapshot.org/) and enable gasless voting (perhaps with Layer 2 Rollup)

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
