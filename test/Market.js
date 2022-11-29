const Market = artifacts.require("Market");

const status = {
    ADDED: 0,
    REJECTED: 1,
    ACCEPTED: 2
}

const vote = {
    NONE: 0,
    ACCEPTED: 1,
    REJECTED: 2
}

const reviewResult = {
    PENDING: 0,
    ACCEPTED: 1,
    REJECTED: 2
}

const reviewerAddresses = [3, 5, 7, 2, 9, 12, 17, 13];
/* 5x3 = 15, 5 reviewers and 3 voters on each */

contract('Market', (accounts) => {
    it('', async () => {
        const marketInstance = await Market.deployed();

    })


})