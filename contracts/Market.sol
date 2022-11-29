pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

enum Status {
    ADDED,
    REJECTED,
    ACCEPTED
}

enum Vote {
    NONE,
    ACCEPTED,
    REJECTED
}

enum ReviewResult {
    PENDING,
    ACCEPTED,
    REJECTED
}

struct Paper {
    uint256 paperID;
    string content;
    address publisher;
    address[] authors;
    address[] reviewers;
    mapping(address => Review) reviews;
    Status status;
    uint256 acceptCount;
    uint256 rejectCount;
}

struct Review {
    address reviewer;
    uint256 paperID;
    string comments;
    ReviewResult reviewerDecision;
    address[] votedReviewers;
    mapping(address => Vote) votes;
    ReviewResult result;
    uint256 yesCount;
    uint256 noCount;
}

struct Reviewer {
    address reviewerAddress;
    string name;
}

contract Conference is Ownable {
    // @dev these two are a list of all the reviewer with ther data
    mapping(address => Reviewer) private reviewers;
    address[] public reviewerslist;

    mapping(uint256 => Paper) papers;
    uint256[] public paperlist;

    uint256 vote_limit = 0;
    uint256 review_limit = 0;
    uint256 num_papers = 0;

    // @dev verifies if the reviewer has registered or not
    modifier validReviewer(address _reviewerAddress) {
        require(
            _reviewerAddress == reviewers[_reviewerAddress].reviewerAddress,
            "unregistered reviewer"
        );
        _;
    }

    // @dev allows contract owner to register a new reviewer
    function registerReviewer(address _reviewerAddress, string calldata _name)
        public
        onlyOwner
    {
        if (reviewers[_reviewerAddress].reviewerAddress == address(0)) {
            reviewers[_reviewerAddress].reviewerAddress = _reviewerAddress;
            reviewers[_reviewerAddress].name = _name;
            reviewerslist.push(_reviewerAddress);
        }
    }

    function getPaper(uint256 _paperID)
        public
        view
        returns (string memory content)
    {
        // function to get a paper from paperID
        return papers[_paperID].content;
    }

    function applyPaper(
        string calldata _paperContent,
        address _publisher,
        address[] memory _authors
    ) public payable {
        // function to send a paper to the conference
        // store paper itself

        uint256 new_paperID = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _paperContent)
            )
        );
        papers[new_paperID].paperID = new_paperID;
        papers[new_paperID].status = Status.ADDED;
        papers[new_paperID].content = _paperContent;
        papers[new_paperID].publisher = _publisher;
        papers[new_paperID].authors = _authors;

        paperlist.push(new_paperID);
    }

    function viewPapersToBeReviewed() public view returns (uint256[10] memory) {
        // function to view all the papers that havent been reviewed
        uint256[10] memory rlist;
        uint256 j = 0;
        for (uint256 i = 0; i < paperlist.length; i++) {
            if (papers[i].status == Status.ADDED) {
                rlist[j] = (papers[i].paperID);
                j += 1;
                if (j >= 9) break;
            }
        }
        return rlist;
    }

    function viewPublishedPapers() public view returns (uint256[10] memory) {
        // function to view all the papers that have been publshed
        uint256[10] memory rlist;
        uint256 j = 0;
        for (uint256 i = paperlist.length; i >= 0; i--) {
            if (papers[i].status == Status.ACCEPTED) {
                rlist[j] = (papers[i].paperID);
                j += 1;
                if (j >= 9) break;
            }
        }
        return rlist;
    }

    function setVoteNumber(uint256 _number) public onlyOwner {
        // function to set the number of votes needed for a decision to be made
        // on whether the review is accepted or rejected
        vote_limit = _number;
    }

    function setReviewNumber(uint256 _number) public onlyOwner {
        // function to set the number of reviews needed for a decision to be made
        // on whether the paper is accepted or rejected
        review_limit = _number;
    }

    function addReview(
        string calldata _reviewContent,
        ReviewResult _reviewDecision,
        uint256 _paperID
    ) public validReviewer(msg.sender) {
        // function to submit a reviewer for a pending paper
        // can only be called by a reviewer
        require(papers[_paperID].status == Status.ADDED);
        papers[_paperID].reviewers.push(msg.sender);
        papers[_paperID].reviews[msg.sender].reviewer = msg.sender;
        papers[_paperID].reviews[msg.sender].comments = _reviewContent;
        papers[_paperID].reviews[msg.sender].reviewerDecision = _reviewDecision;
        papers[_paperID].reviews[msg.sender].result = ReviewResult.PENDING;
    }

    function addVote(
        Vote _vote,
        address reviewer,
        uint256 _paperID
    ) public validReviewer(msg.sender) {
        // function to add a vote for a reviewed paper
        // can only be called by a reviewer
        // This function will check if there are enough votes to accept or reject the paper,
        // and will accordingly take action (distributing funds and published paper or reverting review)
        require(papers[_paperID].status == Status.ADDED);

        require(
            papers[_paperID].reviews[reviewer].result == ReviewResult.PENDING
        );

        if (papers[_paperID].reviews[reviewer].votes[msg.sender] == Vote.NONE) {
            papers[_paperID].reviews[reviewer].votedReviewers.push(msg.sender);
        } else if (
            papers[_paperID].reviews[reviewer].votes[msg.sender] ==
            Vote.ACCEPTED
        ) {
            papers[_paperID].reviews[reviewer].yesCount -= 1; // remove previous vote
        } else if (
            papers[_paperID].reviews[reviewer].votes[msg.sender] ==
            Vote.REJECTED
        ) {
            papers[_paperID].reviews[reviewer].noCount -= 1; // remove previous vote
        }

        papers[_paperID].reviews[reviewer].votes[msg.sender] = _vote;
        if (_vote == Vote.ACCEPTED) {
            papers[_paperID].reviews[reviewer].yesCount += 1;
            if (papers[_paperID].reviews[reviewer].yesCount >= vote_limit) {
                papers[_paperID].reviews[reviewer].result = ReviewResult
                    .ACCEPTED;

                papers[_paperID].reviewers.push(msg.sender);

                if (
                    papers[_paperID].reviews[reviewer].reviewerDecision ==
                    ReviewResult.ACCEPTED
                ) {
                    papers[_paperID].acceptCount += 1;
                    if (papers[_paperID].acceptCount >= review_limit) {
                        papers[_paperID].status = Status.ACCEPTED;
                    }
                } else if (
                    papers[_paperID].reviews[reviewer].reviewerDecision ==
                    ReviewResult.REJECTED
                ) {
                    papers[_paperID].rejectCount += 1;
                    if (papers[_paperID].rejectCount >= review_limit) {
                        papers[_paperID].status = Status.REJECTED;
                    }
                }

                // transfer money appropriately to reviewers involved
            }
        } else if (_vote == Vote.REJECTED) {
            papers[_paperID].reviews[reviewer].noCount += 1;
            if (papers[_paperID].reviews[reviewer].noCount >= vote_limit) {
                papers[_paperID].reviews[reviewer].result = ReviewResult
                    .REJECTED;
            }
        }
    }
}
