## onchain-subscription

An ETH-based on-chain subscription smart contract built with Solidity 0.8.20 and Hardhat. Users pay ETH to subscribe for a fixed period, subscriptions stack on renewal, and cancellation issues a pro-rata refund.

---

## Features

- `subscribe()` — pay ETH, get a timed subscription; renewing early stacks time on top
- `cancel()` — cancel anytime and get a pro-rata refund for unused time
- `isActive()` / `timeRemaining()` — on-chain expiry queries (use as a gate in your dApp)
- `withdraw()` — owner pulls accumulated ETH
- `setPrice()` / `setDuration()` — owner can update terms for future subscribers
- `transferOwnership()` — hand off the contract to a new address
- Custom errors for cheaper gas
- Checks-Effects-Interactions pattern (re-entrancy safe)
- `receive()` and `fallback()` both revert — only `subscribe()` accepts ETH

---

## Project Structure

```
onchain-subscription/
├── contracts/
│   └── OnChainSubscription.sol        # Main contract
├── test/
│   └── OnChainSubscription.test.js    # Full test suite (25+ tests)
├── scripts/
│   └── deploy.js                      # Deploy script
├── ignition/
│   └── modules/
│       └── OnChainSubscription.js     # Hardhat Ignition module
├── hardhat.config.js
├── package.json
├── .env.example
├── .gitignore
└── README.md
```

---

## Getting Started

### Prerequisites

- Node.js >= 18
- npm >= 9

### Install

```bash
git clone https://github.com/YOUR_USERNAME/onchain-subscription.git
cd onchain-subscription
npm install
```

### Configure environment

```bash
cp .env.example .env
# Fill in your RPC URLs, private key, Etherscan API key
```

---

## Commands

```bash
# Compile contracts
npm run compile

# Run all tests
npm test

# Run tests with gas report
npm run test:gas

# Check code coverage
npm run coverage

# Start a local Hardhat node
npm run node

# Deploy to local node (run `npm run node` first in another terminal)
npm run deploy:local

# Deploy to Sepolia testnet
npm run deploy:sepolia
```

---

## Verify on Etherscan

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> <PRICE_IN_WEI> <DURATION_IN_SECONDS>
```

---

## Contract API

### State Variables

| Variable | Type | Description |
|---|---|---|
| `owner` | `address` | Contract owner |
| `subscriptionPrice` | `uint256` | Cost per period in wei |
| `subscriptionDuration` | `uint256` | Period length in seconds |
| `expiresAt(address)` | `uint256` | Expiry timestamp per subscriber |

### Functions

| Function | Access | Description |
|---|---|---|
| `subscribe()` | public payable | Subscribe or extend. Must send >= `subscriptionPrice`. |
| `cancel()` | public | Cancel and receive pro-rata refund. |
| `isActive(address)` | view | Returns `true` if subscription is active. |
| `timeRemaining(address)` | view | Seconds left (0 if expired). |
| `contractBalance()` | view | ETH held by contract. |
| `withdraw(address)` | owner | Send all ETH to address. |
| `setPrice(uint256)` | owner | Update price for future subs. |
| `setDuration(uint256)` | owner | Update duration for future subs. |
| `transferOwnership(address)` | owner | Transfer ownership. |

### Events

| Event | Description |
|---|---|
| `Subscribed(address, uint256, uint256)` | New sub or renewal |
| `Cancelled(address, uint256)` | Cancellation with refund amount |
| `PriceUpdated(uint256, uint256)` | Old → new price |
| `DurationUpdated(uint256, uint256)` | Old → new duration |
| `OwnershipTransferred(address, address)` | Ownership change |
| `Withdrawn(address, uint256)` | ETH withdrawal |

---

## Example Deployment Values

| Parameter | Value | Wei |
|---|---|---|
| Price | 0.01 ETH | `10000000000000000` |
| Duration | 30 days | `2592000` |

---

## License

MIT
