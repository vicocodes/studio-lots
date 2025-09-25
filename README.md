# Studio Lots - Virtual Film & Video Production Studio

A decentralized smart contract built on the Stacks blockchain for managing virtual film and video production studios with customizable sets.

## 🎬 Overview

Studio Lots enables creators to rent virtual production sets in a decentralized marketplace. Studio owners can list their virtual sets with custom pricing and features, while producers and directors can book these sets for their projects with flexible customization options.

## ✨ Features

### Core Functionality
- **Virtual Set Management**: Create and manage customizable virtual production sets
- **Decentralized Booking System**: Reserve sets with automated scheduling
- **User Profiles**: Track reputation and booking history
- **Flexible Pricing**: Dynamic pricing with platform fees
- **Customization Options**: Each set supports up to 5 customization options
- **Rating System**: Build reputation through completed bookings

### Set Types Supported
- Indoor studios
- Outdoor locations
- Green-screen setups
- Custom environments

## 🏗️ Smart Contract Architecture

### Data Structures

#### Studio Sets
```clarity
{
  name: string,
  description: string,
  set-type: string,
  price-per-hour: uint,
  owner: principal,
  is-active: bool,
  customization-options: list,
  created-at: uint
}
```

#### Bookings
```clarity
{
  set-id: uint,
  renter: principal,
  start-time: uint,
  duration-hours: uint,
  total-cost: uint,
  customizations: list,
  status: string,
  created-at: uint
}
```

#### User Profiles
```clarity
{
  username: string,
  user-type: string,
  reputation-score: uint,
  total-bookings: uint
}
```

## 🚀 Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for transaction fees
- Clarity development environment (optional for development)

### Deployment

1. **Deploy the Contract**:
   ```bash
   clarinet deploy --network testnet
   ```

2. **Verify Deployment**:
   ```bash
   clarinet call-read-only contract get-platform-fee
   ```

## 📖 Function Reference

### Read-Only Functions

#### `get-studio-set`
```clarity
(get-studio-set (set-id uint))
```
Retrieves information about a specific studio set.

#### `get-booking`
```clarity
(get-booking (booking-id uint))
```
Gets details of a specific booking.

#### `get-user-profile`
```clarity
(get-user-profile (user principal))
```
Returns user profile information.

#### `calculate-total-cost`
```clarity
(calculate-total-cost (price-per-hour uint) (duration uint))
```
Calculates total booking cost including platform fees.

### Public Functions

#### `create-user-profile`
```clarity
(create-user-profile (username string) (user-type string))
```
Creates a new user profile. User types: "studio-owner", "producer", "director"

**Example**:
```clarity
(contract-call? .studio-lots create-user-profile "john-producer" "producer")
```

#### `create-studio-set`
```clarity
(create-studio-set name description set-type price-per-hour customization-options)
```
Creates a new virtual studio set.

**Example**:
```clarity
(contract-call? .studio-lots create-studio-set 
  "Modern Office" 
  u"Contemporary office space with city views" 
  "indoor" 
  u100 
  (list "lighting-mood" "furniture-style" "wall-color" "props" "camera-angles"))
```

#### `book-studio-set`
```clarity
(book-studio-set set-id start-time duration-hours customizations)
```
Books a studio set for specified time and duration.

**Example**:
```clarity
(contract-call? .studio-lots book-studio-set 
  u1 
  u1000 
  u4 
  (list "warm-lighting" "modern-furniture"))
```

#### `cancel-booking`
```clarity
(cancel-booking booking-id)
```
Cancels an existing booking (renter or set owner only).

#### `complete-booking`
```clarity
(complete-booking booking-id rating)
```
Marks booking as complete and updates renter's reputation (set owner only).

#### `toggle-set-status`
```clarity
(toggle-set-status set-id)
```
Activates or deactivates a studio set (owner only).

#### `update-set-price`
```clarity
(update-set-price set-id new-price)
```
Updates the hourly rate for a studio set (owner only).

## 💰 Economics

### Platform Fees
- Default platform fee: 5%
- Maximum platform fee: 20%
- Fees are added to the base rental cost

### Pricing Structure
```
Total Cost = (Hourly Rate × Duration) + Platform Fee
Platform Fee = (Base Cost × Fee Percentage) / 100
```

### Example Calculation
- Hourly Rate: 100 STX
- Duration: 4 hours
- Platform Fee: 5%
- **Total Cost**: 420 STX (400 + 20 fee)

## 🎯 User Workflows

### For Studio Owners
1. Create user profile as "studio-owner"
2. Create studio sets with pricing and customization options
3. Manage set availability (activate/deactivate)
4. Complete bookings and rate renters
5. Update pricing as needed

### For Producers/Directors
1. Create user profile as "producer" or "director"
2. Browse available studio sets
3. Book sets with custom requirements
4. Complete productions and build reputation
5. Cancel bookings if necessary (subject to terms)

## 🔐 Security Features

### Access Controls
- Only set owners can modify their sets
- Only authorized users can cancel bookings
- Platform fee updates restricted to contract owner
- Reputation updates only through completed bookings

### Validation Checks
- Booking start time must be in the future
- Duration must be greater than zero
- Sets must be active to accept bookings
- Rating system prevents manipulation

## 🧪 Testing

### Unit Tests
```bash
clarinet test
```

### Integration Testing
1. Deploy to testnet
2. Create test user profiles
3. Create sample studio sets
4. Test booking workflow
5. Verify cancellation and completion flows

## 🚧 Limitations & Future Enhancements

### Current Limitations
- Simplified availability checking (no conflict prevention)
- Basic payment handling (STX transfers commented out)
- Limited customization options (max 5 per set)

### Planned Enhancements
- Advanced availability conflict resolution
- Integrated STX payment processing
- Multi-token payment support
- Enhanced reputation algorithms
- Set preview and media storage integration
- Automated refund mechanisms

## 📋 Error Codes

| Code | Description |
|------|-------------|
| u100 | ERR_NOT_AUTHORIZED |
| u101 | ERR_NOT_FOUND |
| u102 | ERR_ALREADY_EXISTS |
| u103 | ERR_INSUFFICIENT_FUNDS |
| u104 | ERR_SET_NOT_AVAILABLE |
| u105 | ERR_INVALID_BOOKING_TIME |
| u106 | ERR_INVALID_FEE_PERCENTAGE |
| u107 | ERR_INVALID_RATING |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License

## 🆘 Support

For questions and support:
- Create an issue in the repository
- Check the Stacks documentation for blockchain-specific questions

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Developer Tools](https://github.com/hirosystems/clarinet)

---

**Built with ❤️ for the creator economy on Stacks blockchain**