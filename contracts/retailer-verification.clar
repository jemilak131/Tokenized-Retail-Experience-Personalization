;; Retailer Verification Contract
;; This contract validates merchants in the retail ecosystem

(define-data-var admin principal tx-sender)

;; Map to store verified retailers
(define-map verified-retailers principal
  {
    name: (string-utf8 100),
    website: (string-utf8 100),
    verified-at: uint,
    active: bool
  }
)

;; Public function to check if a retailer is verified
(define-read-only (is-retailer-verified (retailer principal))
  (match (map-get? verified-retailers retailer)
    verified-data (get active verified-data)
    false
  )
)

;; Admin function to verify a retailer
(define-public (verify-retailer (retailer principal) (name (string-utf8 100)) (website (string-utf8 100)))
  (begin
    (asserts! (is-admin tx-sender) (err u100))
    (ok (map-set verified-retailers retailer
      {
        name: name,
        website: website,
        verified-at: block-height,
        active: true
      }
    ))
  )
)

;; Admin function to revoke retailer verification
(define-public (revoke-retailer (retailer principal))
  (begin
    (asserts! (is-admin tx-sender) (err u100))
    (match (map-get? verified-retailers retailer)
      verified-data (ok (map-set verified-retailers retailer
        (merge verified-data { active: false })
      ))
      (err u101)
    )
  )
)

;; Function to check if caller is admin
(define-read-only (is-admin (caller principal))
  (is-eq caller (var-get admin))
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) (err u100))
    (ok (var-set admin new-admin))
  )
)
