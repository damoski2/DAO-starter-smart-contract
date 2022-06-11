//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



interface IdaoContract{
    function balanceOf(address, uint256) external view returns (uint256);
}

contract DAO{
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [88427669623065427940018316413392003557212506205426504405130611757770715693057];
    }

    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(uint256 id, string description, uint256 maxVotes, address proposer);

    event newVote(uint256 votesUp, uint256 votesDown, address voter, uint256 proposal, bool votedFor);

    event proposalCount(
        uint256 id,
        bool passed
    );



    function checkProposalEligibilty(address _proposalist) private view returns(bool){
        for(uint i=0; i<validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibilty(uint256 _id, address _voter) private view returns(bool){
        for(uint256 i=0; i<Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public{
        require(checkProposalEligibilty(msg.sender), "Only NFT holders can put forth Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public{
        require(Proposals[_id].exists,"This Proposal does not exist");
        require(checkVoteEligibilty(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "This deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];
        if(_vote){
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public{
        require(msg.sender == owner, "Only the owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Voting has already been conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
     }

     //Check to See if Proposal Deadline Has been met with
     function isDeadLineMet(uint _id) public view returns(bool){
         require(msg.sender == owner, "Only Owner Can View Deadline");
         proposal storage p = Proposals[_id];
         
         if(p.deadline > block.timestamp){
             return true;
         }
         return false;
     }

     function addTokenId(uint256 _tokenId) public{
         require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
     }
    }