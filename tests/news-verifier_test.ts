import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can publish news and get correct news ID",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const contentHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('news-verifier', 'publish-news', 
                [types.buff(contentHash)],
                wallet1.address
            )
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), types.uint(0));
    },
});

Clarinet.test({
    name: "Can verify news and track verifications",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const contentHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        // First publish news
        let block = chain.mineBlock([
            Tx.contractCall('news-verifier', 'publish-news',
                [types.buff(contentHash)],
                wallet1.address
            )
        ]);
        
        // Then verify it
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('news-verifier', 'verify-news',
                [types.uint(0)],
                wallet2.address
            )
        ]);
        
        verifyBlock.receipts[0].result.expectOk();
        
        // Check verification status
        let statusBlock = chain.mineBlock([
            Tx.contractCall('news-verifier', 'is-news-verified',
                [types.uint(0)],
                wallet1.address
            )
        ]);
        
        statusBlock.receipts[0].result.expectOk().assertEquals(false); // Needs 3 verifications
    },
});
