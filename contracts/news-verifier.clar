;; News Verification Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-found (err u102))
(define-constant err-not-verified (err u103))

;; Data structures
(define-map news-items
    { news-id: uint }
    {
        publisher: principal,
        content-hash: (buff 32),
        timestamp: uint,
        verified: bool,
        verifier-count: uint
    }
)

(define-map verifications
    { news-id: uint, verifier: principal }
    { verified: bool }
)

;; Data variables
(define-data-var next-id uint u0)

;; Public functions
(define-public (publish-news (content-hash (buff 32)))
    (let 
        (
            (news-id (var-get next-id))
        )
        (map-set news-items
            { news-id: news-id }
            {
                publisher: tx-sender,
                content-hash: content-hash,
                timestamp: block-height,
                verified: false,
                verifier-count: u0
            }
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
        )
        (asserts! (not (already-verified news-id tx-sender)) err-already-verified)
        (map-set verifications
            { news-id: news-id, verifier: tx-sender }
            { verified: true }
        )
        (map-set news-items
            { news-id: news-id }
            (merge news-item { 
                verifier-count: (+ current-verifications u1),
                verified: (>= (+ current-verifications u1) u3)
            })
        )
        (ok true)
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
