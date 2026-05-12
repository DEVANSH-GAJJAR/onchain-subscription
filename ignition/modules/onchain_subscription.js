const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { parseEther } = require("ethers");

const SUBSCRIPTION_PRICE    = parseEther("0.01");
const SUBSCRIPTION_DURATION = 30n * 24n * 60n * 60n; // 30 days

module.exports = buildModule("OnChainSubscriptionModule", (m) => {
  const price    = m.getParameter("subscriptionPrice",    SUBSCRIPTION_PRICE);
  const duration = m.getParameter("subscriptionDuration", SUBSCRIPTION_DURATION);

  const subscription = m.contract("OnChainSubscription", [price, duration]);

  return { subscription };
});
