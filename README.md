## ETH Enugu Smart Contracts

*Empowering the ETH Enugu 2025 Builder Residency, Pop-Up City, and Summit with NFT-based event passes.*

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Forge Tests: Passing](https://img.shields.io/badge/Forge%20Tests-passing-brightgreen.svg)
![Coverage: 100%](https://img.shields.io/badge/Coverage-100%25-brightgreen.svg)

---

## 🚀 Overview

The **ETH Enugu** suite implements ERC-721 “event pass” NFTs for three participation tiers:

1. **Residency Pass** (Builder Residency, managed by `EthEnuguResidency.sol`)
2. **In-Venue Pass** (Pop-Up City + Registration, managed by `EthEnugu.sol`)
3. **Summit Pass** (Conference Attendance, managed by `EthEnugu.sol`)

Each pass is unique, verifiable on-chain, and transferable. Organizers (the contract owner) manage whitelists for Residency passes, and each wallet may mint **only one** pass in each category.

---

## 🔑 Key Features

- **Role-Based Access Control**
  - Address-based whitelisting for Residency passes. Only whitelisted addresses can mint Residency passes.
  - Open minting for In-Venue and Summit passes, limited to one per address.

- **One-Pass-Per-Wallet Enforcement**
  - Internal mappings (`hasMintedResidency`, `hasMintedInVenue`, `hasMintedConference`) prevent duplicate mints within each tier.

- **Custom Errors**
  - Gas-efficient custom errors (e.g., `AddressNotAllowed`, `AlreadyMinted`, `NonexistentToken`) for clear and efficient error handling.

- **Category-Specific Metadata URIs**
  - Distinct base URIs for each pass type. On-chain logic concatenates `baseURI + tokenId + ".json"` to serve the correct metadata.

---

## ⚙️ Installation

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Clone & Build

```bash
git clone https://github.com/ETHEnugu/smart-contract
cd smart-contract
forge install
forge build
```

### 3. Testing & Coverage

**Run all tests**
```bash
forge test
```

**Generate coverage report**
```bash
forge coverage
forge coverage --report lcov
# then use genhtml lcov.info -o coverage-report
```

---

## 📦 Contract Breakdown

### `src/EthEnuguResidency.sol`
**Purpose:** Manages Residency passes for the Builder Residency.

- **ERC-721 Implementation** with one mint function:
  - `mintBuilderResidency()`: Mints a Residency pass for whitelisted addresses.

- **Access Control:**
  - Owner-managed whitelist via `allowedResidencyAddresses` mapping.
  - `updateAllowedResidencyAddress(address, bool)` to add/remove whitelisted addresses.

- **Single-Mint Guard:** `hasMintedResidency` mapping ensures one Residency pass per address.

- **Metadata Logic:** `tokenURI()` returns `residencyBaseTokenURI + tokenId + ".json"`.

- **Custom Errors:**
  - `InvalidAddress`
  - `AddressNotAllowed`
  - `AlreadyMinted`
  - `NonexistentToken`

---

### `src/EthEnugu.sol`
**Purpose:** Manages In-Venue and Summit passes for Pop-Up City and Conference Attendance.

- **ERC-721 Implementation** with two mint functions:
  - `mintInVenueRegistration()`: Mints an In-Venue pass.
  - `mintConferenceAttendance()`: Mints a Summit pass.

- **Access Control:** Open minting, restricted to one pass per type per address.

- **Single-Mint Guards:**
  - `hasMintedInVenue` for In-Venue passes.
  - `hasMintedConference` for Summit passes.

- **Metadata Logic:** `tokenURI()` routes to `inVenueBaseTokenURI` or `conferenceBaseTokenURI` based on pass type.

- **Custom Errors:**
  - `AlreadyMintedInVenue`
  - `AlreadyMintedConference`
  - `NonexistentToken`

---

### `test/EthEnugu.t.sol`
**Unit Tests covering:**
- Default base URI correctness for all pass types.
- Metadata URI generation for Residency, In-Venue, and Summit passes.
- Whitelisted and non-whitelisted minting for Residency.
- Open minting for In-Venue and Summit passes.
- Single-mint enforcement per address for each pass type.
- Owner-only whitelist management for Residency.
- Custom error handling for invalid addresses, unauthorized mints, and nonexistent tokens.
- Zero-address whitelist prevention.

---

## 💡 Usage Examples

### Granting Whitelist Access (Residency)
```solidity
// As contract owner:
ethEnuguResidency.updateAllowedResidencyAddress(minterAddress, true);
```

### Minting a Pass
```solidity
// Residency (whitelisted address):
ethEnuguResidency.mintBuilderResidency();

// In-Venue (any address, once):
ethEnugu.mintInVenueRegistration();

// Summit (any address, once):
ethEnugu.mintConferenceAttendance();
```

### Fetching Metadata URI
```javascript
// Residency pass
const residencyUri = await ethEnuguResidency.tokenURI(tokenId);
// e.g., https://residency.example/api/1.json

// In-Venue or Summit pass
const passUri = await ethEnugu.tokenURI(tokenId);
// e.g., https://invenue.example/api/1.json or https://conference.example/api/1.json
```

---

## 🔒 Security

- **Safe ERC-721:** Uses `_safeMint` to enforce receiver interface checks.
- **Single-Mint Enforcement:** Prevents duplicate mints without relying on external state.
- **Custom Errors:** Reduces gas costs and improves error clarity.
- **Owner-Only Whitelist:** Only the contract owner can manage the Residency whitelist.

> **Note:** Reentrancy protection is not included, as minting functions are simple and do not interact with external contracts beyond `_safeMint`.

---

## 🪪 License

Released under the MIT License ([LICENSE](LICENSE)).

---

## 🤝 Contributing

Pull requests and issues are welcome! Please open an issue to discuss major changes before submitting.

---

## 🙏 Acknowledgments

- ETH Enugu Community for event vision and support.
- Nigeria Web3 Ecosystem for ongoing collaboration.
- OpenZeppelin & Foundry teams for their open-source tooling.
