;; News Verification Contract with Reputation System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101)) 
(define-constant err-not-found (err u102))
(define-constant err-not-verified (err u103))
(define-constant err-insufficient-reputation (err u104))

;; Data structures
(define-map news-items
    { news-id: uint }
    {
        publisher: principal,
        content-hash: (buff 32),
        timestamp: uint,
        verified: bool,
        verifier-count: uint,
        reputation-score: uint,
        weighted-score: uint
    }
)

(define-map verifications
    { news-id: uint, verifier: principal }
    { verified: bool }
)

(define-map user-reputation
    { user: principal }
    { 
        score: uint,
        verified-count: uint,
        published-count: uint
    }
)

;; Data variables
(define-data-var next-id uint u0)

;; Private functions 
(define-private (get-user-reputation (user principal))
    (default-to
        { score: u10, verified-count: u0, published-count: u0 }
        (map-get? user-reputation { user: user })
    )
)

(define-private (update-reputation (user principal) (verified bool))
    (let
        (
            (current-rep (get-user-reputation user))
            (new-score (if verified 
                (+ (get score current-rep) u5)
                (- (get score current-rep) u3)))
        )
        (map-set user-reputation
            { user: user }
            (merge current-rep {
                score: new-score,
                verified-count: (+ (get verified-count current-rep) u1)
            })
        )
    )
)

(define-private (calculate-weighted-score (rep-score uint) (verifier-count uint))
    (* rep-score (+ u1 (/ verifier-count u2)))
)

;; Public functions
(define-public (publish-news (content-hash (buff 32)))
    (let 
        (
            (news-id (var-get next-id))
            (publisher-rep (get-user-reputation tx-sender))
        )
        (asserts! (>= (get score publisher-rep) u10) err-insufficient-reputation)
        (map-set news-items
            { news-id: news-id }
            {
                publisher: tx-sender,
                content-hash: content-hash, 
                timestamp: block-height,
                verified: false,
                verifier-count: u0,
                reputation-score: u0,
                weighted-score: u0
            }
        )
        (map-set user-reputation
            { user: tx-sender }
            (merge publisher-rep {
                published-count: (+ (get published-count publisher-rep) u1)
            })
        )
        (var-set next-id (+ news-id u1))
        (ok news-id)
    )
)

(define-public (verify-news (news-id uint))
    (let 
        (
            (news-item (unwrap! (get-news-item news-id) err-not-found))
            (current-verifications (default-to u0 (get verifier-count news-item)))
            (verifier-rep (get-user-reputation tx-sender))
        )
        (asserts! (>= (get score verifier-rep) u20) err-insufficient-reputation)
        (asserts! (not (already-verified news-id tx-sender)) err-already-verified)
        
        (map-set verifications
            { news-id: news-id, verifier: tx-sender }
            { verified: true }
        )
        
        (let
            (
                (new-count (+ current-verifications u1))
                (verified (>= new-count u3))
                (new-rep-score (+ (get reputation-score news-item) (get score verifier-rep)))
            )
            (map-set news-items
                { news-id: news-id }
                (merge news-item { 
                    verifier-count: new-count,
                    verified: verified,
                    reputation-score: new-rep-score,
                    weighted-score: (calculate-weighted-score new-rep-score new-count)
                })
            )
            (when verified
                (update-reputation (get publisher news-item) true)
            )
            (ok true)
        )
    )
)

;; Read-only functions
(define-read-only (get-news-item (news-id uint))
    (map-get? news-items { news-id: news-id })
)

(define-read-only (is-news-verified (news-id uint))
    (match (get-news-item news-id)
        news-item (ok (get verified news-item))
        err-not-found
    )
)

(define-read-only (already-verified (news-id uint) (verifier principal))
    (match (map-get? verifications { news-id: news-id, verifier: verifier })
        verification-data (get verified verification-data)
        false
    )
)

(define-read-only (get-reputation (user principal))
    (ok (get-user-reputation user))
)

(define-read-only (get-weighted-score (news-id uint))
    (match (get-news-item news-id)
        news-item (ok (get weighted-score news-item))
        err-not-found
    )
)
