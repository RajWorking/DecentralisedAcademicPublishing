pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

enum Status{
    ADDED,
    REVIEWED,
    REJECTED,
    ACCEPTED
}

struct Paper{
    string content;
    address publisher;
    address[] authors;
    Status status;
    uint paperID;
}

enum Vote{
    NONE,
    ACCEPTED,
    REJECTED
}

enum ReviewResult{
    ACCEPTED,
    REJECTED
}

struct Review{
    string content;
    address reviewer;
    mapping(address=>Vote[]) votes;
    uint yesCount;
    uint noCount;
    ReviewResult result;
}

Contract Conference is Ownable {
    struct Paper, Review;
    enum Vote, Status;
    
    mapping(address=>uint) reviewers;
    mapping(uint=>Paper) papers;
    mapping(uint=>Review) reviews;
    uint limit = 0;
    uint num_papers = 0;

    // function to hire a reviewer
    function registerReviewer(address _reviewerAddress) public onlyOwner {
        reviewers[_reviewerAddress] = 1;
    }

    // function to fire a reviewer
    function removeReviewer(address _reviewerAddress) public onlyOwner {
        reviewers[_reviewerAddress] = 0;
    }

    function viewPapersToBeReviewed() public view returns(Paper[]) {
        // function to view all the papers that havent been reviewed
        Paper[] return_value;
        for(uint i=0;i<papers.length;i++){
            if(papers[i].status == Status.ADDED){
                return_value.push(papers[i]);
            }
        }
        return return_value;
    }

    function viewReviewedPapers() public view {
        // function to view all the papers (along with their review) that have been reviewed but arent accepted or rejected yet
        Paper[] return_value;
        for(uint i=0;i<papers.length;i++){
            if(papers[i].status == Status.REVIEWED){
                return_value.push(papers[i]);
            }
        }
        return return_value;
    }

    function viewPublishedPapers() public view{
        // function to view all the papers that have been publshed
        Paper[] return_value;
        for(uint i=0;i<papers.length;i++){
            if(papers[i].status == Status.ACCEPTED){
                return_value.push(papers[i]);
            }
        }
        return return_value;
    }

    function setReviewNumber(uint _number) public onlyOwner {
        // function to set the number of votes needed for a decision to be made
        // on whether the review is accepted or rejected
        limit = _number;
    }

    function applyPaper(string _paperContent, address _publisher, address[] _authors) public payable {
        // function to send a paper to the conference
        // store paper itself
        Paper new_paper;
        new_paper.status = Status.ADDED;
        new_paper.content = _paperContent;
        new_paper.publisher = _publisher;
        new_paper.authors = _authors;
        new_paper.paperID = papers.length;
        papers.push(new_paper);

        // store dummy review to be filled later
        Review new_review;
        reviews.push(new_review);
    }

    function addReview(string _reviewContent, uint _paperID) public OnlyReviewer {
        // function to submit a reviewer for a pending paper
        // can only be called by a reviewer
        require(paper[_paperID].status == Status.ADDED);
        reviews[_paperID].content = _reviewContent;
        reviews[_paperID].reviewer = msg.sender;
        reviews[_paperID].status = Status.REVIEWED;
    }

    function addVote(Vote _vote, uint _paperID) public OnlyReviewer {
        // function to add a vote for a reviewed paper
        // can only be called by a reviewer
        // This function will check if there are enough votes to accept or reject the paper, 
        // and will accordingly take action (distributing funds and published paper or reverting review)
        require(reviews[_paperID].status == Status.REVIEWED);

        if (reviews[_paperID].votes[msg.sender] == Vote.NONE){
            reviews[_paperID].votedReviewers.push(msg.sender);
        }
        else if (reviews[_paperID].votes[msg.sender] == Vote.ACCEPTED){
            reviews[_paperID].yesCount-=1;
        }
        else if (reviews[_paperID].votes[msg.sender] == Vote.REJECTED){
            reviews[_paperID].noCount-=1;
        }

        reviews[_paperID].votes[msg.sender] = _vote;
        if(_vote == Vote.ACCEPTED){
            reviews[_paperID].yesCount+=1;
            if(reviews[_paperID].yesCount>=limit){
                if(reviews[_paperID].result == ReviewResult.ACCEPTED){
                    reviews[_paperID].status = Status.ACCEPTED;
                }
                if(reviews[_paperID].result == ReviewResult.REJECTED){
                    reviews[_paperID].status = Status.REJECTED;
                }
                // transfer money appropriately to reviewers involved.
            }
        }
        else if(_vote == Vote.REJECTED){
            reviews[_paperID].noCount+=1;
            if(reviews[_paperID].noCount+=1>=limit){
                Review new_review;
                reviews[_paperID] = new_review;
            }
        }

        
    }

}