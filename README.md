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
- Weighted reputation scoring based on verification count

## How it works

1. News publishers submit content hashes of their news articles
2. Publishers must have minimum reputation score (10) to publish
3. Independent verifiers can review and verify the authenticity
4. Verifiers must have minimum reputation score (20) to verify
5. News items require at least 3 independent verifications to be marked as verified
6. Successful verifications increase publisher reputation
7. All verification history is permanently stored on the blockchain
8. Reputation scores determine user privileges and influence
9. News items get weighted reputation scores based on verifier count

## Reputation System

- New users start with base reputation of 10
- Publishing requires minimum reputation of 10
- Verification requires minimum reputation of 20
- Verified news items increase publisher reputation by 5
- Failed verifications decrease reputation by 3
- Higher reputation gives more influence in verification process
- Weighted scoring formula: reputation_score * (1 + verifier_count/2)

## Recent Updates

- Added weighted reputation scoring that increases with more verifications
- New weighted-score field for news items that combines reputation and verification count
- Added get-weighted-score read-only function to query weighted reputation scores
