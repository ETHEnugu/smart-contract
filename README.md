## ETH Enugu Smart Contracts

*Empowering the ETH Enugu 2025 Builder Residency, Pop-Up City, and Summit with NFT-based event passes.*

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Forge Tests: Passing](https://img.shields.io/badge/Forge%20Tests-passing-brightgreen.svg)
![Coverage: 100%](https://img.shields.io/badge/Coverage-100%25-brightgreen.svg)

---

## 🚀 Overview

The **ETH Enugu** suite implements ERC-721 “event pass” NFTs for three participation tiers:

1. **Residency Pass** (Builder Residency)
2. **In-Venue Pass** (Pop-Up City + Registration)
3. **Summit Pass** (Conference Attendance)

Each pass is unique, verifiable on-chain, and transferable. Organizers (the contract owner) grant specific minter roles per pass type, and each wallet may mint **only one** pass in each category.

---

## 🔑 Key Features

* **Role-Based Access Control**
  Separate whitelists for Residency, In-Venue, and Summit minters. Only authorized addresses can mint the corresponding pass.

* **One-Pass-Per-Wallet Enforcement**
  Internal mappings track per-address mints to prevent duplicates within each tier.

* **Reentrancy Protection**
  All minting functions use OpenZeppelin’s `ReentrancyGuard` to block nested calls and guard against reentrancy exploits.

* **Category-Specific Metadata URIs**
  Distinct base URIs for each pass type. On-chain logic concatenates `baseURI + tokenId + ".json"` to serve the correct metadata.

---

## ⚙️ Installation

1. **Install Foundry**

   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```
2. **Clone & Build**

   ```bash
   git clone https://github.com/ETHEnugu/smart-contract
   cd smart-contract
   forge install
   forge build
   ```

---

## ✅ Testing & Coverage

* **Run all tests**

  ```bash
  forge test
  ```
* **Generate coverage report**

  ```bash
  forge coverage
  forge coverage --report lcov
  # then use genhtml lcov.info -o coverage-report
  ```

---

## 📄 Contract Breakdown

### `src/EthEnugu.sol`

* **ERC-721 Implementation** with three mint functions:

  * `mintBuilderResidency()`
  * `mintInVenueRegistration()`
  * `mintConferenceAttendance()`
* **Access Control** via owner-managed mappings:

  * `allowedResidencyMinters`
  * `allowedInVenueMinters`
  * `allowedConferenceMinters`
* **Single-Mint Guards** using `hasMinted…` mappings.
* **Metadata Logic** in `tokenURI()` that routes to the correct base URI.

### `test/EthEnugu.t.sol`

* **Unit Tests** covering:

  * Default owner privileges
  * Authorized vs. unauthorized minters
  * One-mint enforcement
  * URI correctness
  * Role updates (add/remove)
  * Reentrancy attacks via a malicious IERC721Receiver

---

## 📦 Usage Examples

### Granting Minter Roles

```solidity
// As contract owner:
ethEnugu.updateAllowedResidencyMinter(minterAddress, true);
ethEnugu.updateAllowedInVenueMinter(minterAddress, true);
ethEnugu.updateAllowedConferenceMinter(minterAddress, true);
```

### Minting a Pass

```solidity
// Called by an address with the matching minter role:
ethEnugu.mintBuilderResidency();
ethEnugu.mintInVenueRegistration();
ethEnugu.mintConferenceAttendance();
```

### Fetching Metadata URI

```js
const uri = await ethEnugu.tokenURI(tokenId);
// e.g. https://residency.example/api/1.json
```

---

## 🔒 Security

* **ReentrancyGuard** on all mint functions.
* **Safe ERC-721** via `_safeMint`, enforcing receiver interface checks.
* **Strict Role Checks** with clear error messages (`"Not allowed"`).

---

## 📜 License

Released under the [MIT License](LICENSE).

---

## 🤝 Contributing

Pull requests and issues are welcome! Please open an issue to discuss major changes before submitting.

---

## 🙏 Acknowledgments

* **ETH Enugu Community** for event vision and support.
* **Nigeria Web3 Ecosystem** for ongoing collaboration.
* **OpenZeppelin & Foundry** teams for their open-source tooling.
