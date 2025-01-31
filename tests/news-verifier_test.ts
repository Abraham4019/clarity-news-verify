import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can publish news with sufficient reputation",
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
    name: "Cannot verify without sufficient reputation",
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
        
        // Attempt verification with insufficient reputation
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('news-verifier', 'verify-news',
                [types.uint(0)],
                wallet2.address
            )
        ]);
        
        assertEquals(verifyBlock.receipts[0].result.expectErr(), types.uint(104));
    },
});

Clarinet.test({
    name: "Can check user reputation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('news-verifier', 'get-reputation',
                [types.principal(wallet1.address)],
                wallet1.address
            )
        ]);
        
        const reputation = block.receipts[0].result.expectOk().expectTuple();
        assertEquals(reputation['score'], types.uint(10));
        assertEquals(reputation['verified-count'], types.uint(0));
        assertEquals(reputation['published-count'], types.uint(0));
    },
});

Clarinet.test({
    name: "Weighted score increases with verifications",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const contentHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        // Publish news
        let block = chain.mineBlock([
            Tx.contractCall('news-verifier', 'publish-news',
                [types.buff(contentHash)],
                wallet1.address
            )
        ]);
        
        let newsId = block.receipts[0].result.expectOk();
        
        // Get initial weighted score
        let scoreBlock = chain.mineBlock([
            Tx.contractCall('news-verifier', 'get-weighted-score',
                [newsId],
                wallet1.address
            )
        ]);
        
        assertEquals(scoreBlock.receipts[0].result.expectOk(), types.uint(0));
    },
});
