;; News Verification Contract with Reputation System
;; Enhanced with overflow protection and input validation

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
(define-constant err-invalid-content (err u108))
(define-constant err-max-verifiers-reached (err u109))

;; Configuration
(define-constant max-reputation u1000)
(define-constant min-reputation u0)
(define-constant verification-window u144) ;; ~24 hours in blocks
(define-constant max-verifiers u100) ;; Maximum number of verifiers per news item

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
        last-activity: uint,
        accurate-verifications: uint
    }
)

;; Private helper functions
(define-private (is-valid-content-hash (content-hash (buff 32)))
    (> (len content-hash) u0)
)

(define-private (safe-multiply (a uint) (b uint))
    (let ((result (* a b)))
        (asserts! (or (is-eq b u0) (is-eq (/ result b) a)) err-reputation-overflow)
        result
    )
)

(define-private (calculate-weighted-score (rep-score uint) (verifier-count uint))
    (let ((multiplier (+ u1 (/ verifier-count u2))))
        (min max-reputation (safe-multiply rep-score multiplier))
    )
)

(define-public (publish-news (content-hash (buff 32)))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (is-valid-content-hash content-hash) err-invalid-content)
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

[... remaining contract functions with similar enhancements ...]
