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
    string content;
    ReviewResult reviewerDecision;
    address[] votedReviewers;
    mapping(address => Vote) votes;
    ReviewResult result;
    uint256 yesCount;
    uint256 noCount;
}

contract Conference is Ownable {
    mapping(address => uint256) reviewers;
    mapping(uint256 => Paper) papers;
    uint256 vote_limit = 0;
    uint256 review_limit = 0;
    uint256 num_papers = 0;

    // function to hire a reviewer
    function registerReviewer(address _reviewerAddress) public onlyOwner {
        reviewers[_reviewerAddress] = 1;
    }

    // function to fire a reviewer
    function removeReviewer(address _reviewerAddress) public onlyOwner {
        reviewers[_reviewerAddress] = 0;
    }

    function viewPapersToBeReviewed() public view returns (Paper[]) {
        // function to view all the papers that havent been reviewed
        Paper[] return_value;
        for (uint256 i = 0; i < papers.length; i++) {
            if (papers[i].status == Status.ADDED) {
                return_value.push(papers[i]);
            }
        }
        return return_value;
    }

    function viewReviewedPapers() public view {
        // function to view all the papers (along with their review) that have been reviewed but arent accepted or rejected yet
        Paper[] return_value;
        for (uint256 i = 0; i < papers.length; i++) {
            if (papers[i].status == Status.REVIEWED) {
                return_value.push(papers[i]);
            }
        }
        return return_value;
    }

    function viewPublishedPapers() public view {
        // function to view all the papers that have been publshed
        Paper[] return_value;
        for (uint256 i = 0; i < papers.length; i++) {
            if (papers[i].status == Status.ACCEPTED) {
                return_value.push(papers[i]);
            }
        }
        return return_value;
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

    function applyPaper(
        string _paperContent,
        address _publisher,
        address[] _authors
    ) public payable {
        // function to send a paper to the conference
        // store paper itself
        Paper new_paper;
        new_paper.paperID = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _paperContent)
            )
        );
        new_paper.status = Status.ADDED;
        new_paper.content = _paperContent;
        new_paper.publisher = _publisher;
        new_paper.authors = _authors;

        papers.push(new_paper);
        papers[new_paper.paperID] = new_paper;
    }

    function addReview(
        string _reviewContent,
        ReviewResult _reviewDecision,
        uint256 _paperID
    ) public OnlyReviewer {
        // function to submit a reviewer for a pending paper
        // can only be called by a reviewer
        require(paper[_paperID].status == Status.ADDED);
        paper[_paperID].reviewers.push(msg.sender);
        paper[_paperID].reviews[msg.sender].reviewer = msg.sender;
        paper[_paperID].reviews[msg.sender].content = _reviewContent;
        paper[_paperID].reviews[msg.sender].reviewerDecision = _reviewDecision;
        paper[_paperID].reviews[msg.sender].result = Status.PENDING;
    }

    function addVote(
        Vote _vote,
        address reviewer,
        uint256 _paperID
    ) public OnlyReviewer {
        // function to add a vote for a reviewed paper
        // can only be called by a reviewer
        // This function will check if there are enough votes to accept or reject the paper,
        // and will accordingly take action (distributing funds and published paper or reverting review)
        require(papers[_paperID].status == Status.REVIEWED);

        Review review = papers[_paperID].reviews[reviewer];

        require(review.result == ReviewResult.PENDING);

        if (review.votes[msg.sender] == Vote.NONE) {
            review.votedReviewers.push(msg.sender);
        } else if (review.votes[msg.sender] == Vote.ACCEPTED) {
            review.yesCount -= 1; // remove previous vote
        } else if (review.votes[msg.sender] == Vote.REJECTED) {
            review.noCount -= 1; // remove previous vote
        }

        review.votes[msg.sender] = _vote;
        if (_vote == Vote.ACCEPTED) {
            review.yesCount += 1;
            if (review.yesCount >= vote_limit) {
                review.result = ReviewResult.ACCEPTED;

                papers[_paperID].reviewers.push(msg.sender);

                if (review.reviewerDecision == ReviewResult.ACCEPTED) {
                    papers[_paperID].acceptCount += 1;
                    if (papers[_paperID].acceptCount >= review_limit) {
                        papers[_paperID].status = Status.ACCEPTED;
                    }
                } else if (review.reviewerDecision == ReviewResult.REJECTED) {
                    papers[_paperID].rejectCount += 1;
                    if (papers[_paperID].rejectCount >= review_limit) {
                        papers[_paperID].status = Status.REJECTED;
                    }
                }

                // transfer money appropriately to reviewers involved
            }
        } else if (_vote == Vote.REJECTED) {
            review.noCount += 1;
            if (review.noCount >= vote_limit) {
                review.result = ReviewResult.REJECTED;
            }
        }

        papers[_paperID].reviews[reviewer] = review;
    }
}
