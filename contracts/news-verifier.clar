;; News Verification Contract with Reputation System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101)) 
(define-constant err-not-found (err u102))
(define-constant err-not-verified (err u103))
(define-constant err-insufficient-reputation (err u104))
(define-constant err-invalid-timestamp (err u105))
(define-constant err-contract-paused (err u106))
(define-constant err-reputation-overflow (err u107))

;; Configuration
(define-constant max-reputation u1000)
(define-constant min-reputation u0)
(define-constant verification-window u144) ;; ~24 hours in blocks

;; Data variables
(define-data-var next-id uint u0)
(define-data-var contract-paused bool false)

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
        published-count: uint,
        last-activity: uint
    }
)

;; Admin functions
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused paused))
    )
)

;; Private functions 
(define-private (get-user-reputation (user principal))
    (default-to
        { score: u10, verified-count: u0, published-count: u0, last-activity: block-height }
        (map-get? user-reputation { user: user })
    )
)

(define-private (update-reputation (user principal) (verified bool))
    (let
        (
            (current-rep (get-user-reputation user))
            (new-score (if verified 
                (min max-reputation (+ (get score current-rep) u5))
                (max min-reputation (- (get score current-rep) u3))))
        )
        (map-set user-reputation
            { user: user }
            (merge current-rep {
                score: new-score,
                verified-count: (+ (get verified-count current-rep) u1),
                last-activity: block-height
            })
        )
    )
)

(define-private (calculate-weighted-score (rep-score uint) (verifier-count uint))
    (min max-reputation (* rep-score (+ u1 (/ verifier-count u2))))
)

(define-private (validate-timestamp (timestamp uint))
    (and 
        (>= timestamp (- block-height verification-window))
        (<= timestamp block-height)
    )
)

;; Public functions
(define-public (publish-news (content-hash (buff 32)))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
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
                    published-count: (+ (get published-count publisher-rep) u1),
                    last-activity: block-height
                })
            )
            (var-set next-id (+ news-id u1))
            (ok news-id)
        )
    )
)

[... remaining contract functions ...]
