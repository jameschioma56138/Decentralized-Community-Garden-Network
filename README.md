# Decentralized Community Garden Network

A blockchain-based system for managing community gardens, built on the Stacks blockchain using Clarity smart contracts.

## Overview

The Community Garden Network consists of five interconnected smart contracts that manage different aspects of a community garden:

1. **Plot Rental Contract** - Manages garden space assignments and rental fees
2. **Water Usage Contract** - Tracks irrigation consumption and billing
3. **Tool Sharing Contract** - Manages community equipment lending and maintenance
4. **Harvest Sharing Contract** - Coordinates produce distribution to food banks
5. **Educational Program Contract** - Schedules gardening workshops and classes

## Features

### Plot Rental System
- Register and rent garden plots
- Track plot ownership and rental periods
- Manage rental fees and payments
- Plot availability tracking

### Water Usage Management
- Monitor water consumption per plot
- Calculate usage-based billing
- Track payment status
- Water allocation limits

### Tool Sharing Network
- Community tool inventory management
- Tool borrowing and return system
- Maintenance scheduling and tracking
- Tool availability status

### Harvest Distribution
- Record harvest yields by plot
- Coordinate donations to food banks
- Track distribution history
- Community sharing metrics

### Educational Programs
- Workshop scheduling and registration
- Instructor management
- Attendance tracking
- Educational resource allocation

## Contract Architecture

Each contract is designed to be independent while maintaining data consistency across the network. The contracts use Clarity's built-in data structures and functions for secure, transparent operations.

### Data Types Used
- \`uint\` for numerical values (fees, quantities, timestamps)
- \`principal\` for user addresses
- \`string-ascii\` for names and descriptions
- \`bool\` for status flags
- Maps for storing structured data
- Lists for collections

### Security Features
- Input validation on all public functions
- Access control for administrative functions
- Error handling with descriptive error codes
- Immutable contract deployment

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Run tests:
   \`\`\`bash
   npm test
   \`\`\`

4. Deploy contracts:
   \`\`\`bash
   clarinet deploy
   \`\`\`

## Usage Examples

### Renting a Plot
\`\`\`clarity
(contract-call? .plot-rental rent-plot u1 u12)
\`\`\`

### Recording Water Usage
\`\`\`clarity
(contract-call? .water-usage record-usage u1 u50)
\`\`\`

### Borrowing a Tool
\`\`\`clarity
(contract-call? .tool-sharing borrow-tool u1)
\`\`\`

### Donating Harvest
\`\`\`clarity
(contract-call? .harvest-sharing donate-harvest u1 u25)
\`\`\`

### Registering for Workshop
\`\`\`clarity
(contract-call? .educational-program register-workshop u1)
\`\`\`

## Testing

The project includes comprehensive tests using Vitest. Tests cover:
- Contract deployment
- Function execution
- Error handling
- Data integrity
- Edge cases

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions or support, please open an issue in the repository.
