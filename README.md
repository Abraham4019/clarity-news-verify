# Decentralized News Verification System

A blockchain-based system for verifying news authenticity using collective validation and reputation scoring.

## Features

- Publishers can submit news items with content hashes
- Independent verifiers can validate news items 
- News items require multiple verifications to be marked as verified
- All verifications are transparent and immutable
- Prevents duplicate verifications from same verifier
- Reputation system for publishers and verifiers
- Minimum reputation thresholds for publishing and verifying
- Dynamic reputation scoring based on verified content

## How it works

1. News publishers submit content hashes of their news articles
2. Publishers must have minimum reputation score (10) to publish
3. Independent verifiers can review and verify the authenticity
4. Verifiers must have minimum reputation score (20) to verify
5. News items require at least 3 independent verifications to be marked as verified
6. Successful verifications increase publisher reputation
7. All verification history is permanently stored on the blockchain
8. Reputation scores determine user privileges and influence

## Reputation System

- New users start with base reputation of 10
- Publishing requires minimum reputation of 10
- Verification requires minimum reputation of 20
- Verified news items increase publisher reputation by 5
- Failed verifications decrease reputation by 3
- Higher reputation gives more influence in verification process
