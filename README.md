## 🎯 Overview

A blockchain-based token economy that incentivizes ocean plastic cleanup through verified collection rewards and eco-credit exchanges.

## 🚀 Features

- 📍 **GPS-Verified Collection**: Submit plastic collection with precise location data
- 🏅 **Token Rewards**: Earn tokens for verified ocean plastic collection
- ♻️ **Recycler Partnerships**: Connect with verified recycling partners
- 💚 **Eco-Credit Exchange**: Convert tokens to environmental credits
- 📊 **Progress Tracking**: Monitor individual and community impact

## 🛠️ Quick Start

### Prerequisites
- Clarinet CLI installed
- Stacks wallet

### Installation

```bash
git clone <repository-url>
cd Ocean-Plastic-Recovery-Token-Economy
clarinet check
```

### Testing

```bash
npm install
npm test
```

## 📋 Contract Functions

### 🏗️ Setup Functions

**`register-recycler`**
- Register as a verified recycling partner
- Only contract owner can verify recyclers

**`set-token-reward-rate`**
- Adjust token rewards per unit of plastic
- Admin function for economic balancing

### 🗑️ Collection Functions

**`submit-collection`**
- Submit plastic collection with GPS coordinates
- Requires: latitude (-90° to 90°), longitude (-180° to 180°), amount (kg)
- Returns: collection ID for tracking

**`verify-collection`**
- Verify submitted collection (admin only)
- Mints reward tokens to collector
- Updates user statistics

**`assign-recycler`**
- Connect verified collection to recycling partner
- Tracks recycler processing volume

### 💰 Token Functions

**`transfer-tokens`**
- Transfer tokens between users
- Standard token transfer functionality

**`exchange-tokens-for-eco-credits`**
- Burn tokens in exchange for eco-credits
- Permanent token removal from circulation

### 📊 Query Functions

**`get-collection`**
- View collection details by ID

**`get-user-stats`**
- Check user's total collected plastic and tokens earned

**`get-token-balance`**
- Check token balance for any user

**`get-recycler-stats`**
- View recycler processing statistics

## 📍 GPS Coordinate Format

Coordinates use integer format with 6 decimal precision:
- Latitude: -90000000 to 90000000 (represents -90.000000° to 90.000000°)
- Longitude: -180000000 to 180000000 (represents -180.000000° to 180.000000°)

## 💡 Usage Examples

### Submit Collection
```clarity
(contract-call? .Ocean-Plastic-Recovery-Token-Economy submit-collection 
  25123456   ;; 25.123456° N
  -80654321  ;; -80.654321° W  
  u15        ;; 15 kg of plastic
)
```

### Check Balance
```clarity
(contract-call? .Ocean-Plastic-Recovery-Token-Economy get-token-balance 'SP1234...)
```

### Exchange for Eco-Credits
```clarity
(contract-call? .Ocean-Plastic-Recovery-Token-Economy exchange-tokens-for-eco-credits u100)
```

## 🌍 Impact Tracking

The contract maintains comprehensive statistics:
- Individual collector progress
- Total plastic recovered from oceans
- Recycler processing volumes
- Token circulation and eco-credit exchanges

## 🔒 Security Features

- Owner-only verification prevents fraud
- GPS coordinate validation
- Secure token transfer mechanisms
- Verified recycler network

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Test your changes with `clarinet check`
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

---

*Making ocean cleanup profitable and transparent* 🌊♻️✨
