const Market = artifacts.require('Market');

module.exports = function(_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(Market);
};
