;; Consumer Identity Contract
;; This contract manages shopper profiles

(define-data-var admin principal tx-sender)

;; Map to store consumer profiles
(define-map consumer-profiles principal
  {
    display-name: (string-utf8 50),
    email-hash: (buff 32),
    created-at: uint,
    preferences-updated: uint,
    active: bool
  }
)

;; Public function for consumers to register
(define-public (register-consumer (display-name (string-utf8 50)) (email-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? consumer-profiles tx-sender)) (err u200))
    (ok (map-set consumer-profiles tx-sender
      {
        display-name: display-name,
        email-hash: email-hash,
        created-at: block-height,
        preferences-updated: u0,
        active: true
      }
    ))
  )
)

;; Public function for consumers to update their profile
(define-public (update-profile (display-name (string-utf8 50)) (email-hash (buff 32)))
  (begin
    (match (map-get? consumer-profiles tx-sender)
      profile (ok (map-set consumer-profiles tx-sender
        (merge profile {
          display-name: display-name,
          email-hash: email-hash
        })
      ))
      (err u201)
    )
  )
)

;; Public function for consumers to deactivate their profile
(define-public (deactivate-profile)
  (begin
    (match (map-get? consumer-profiles tx-sender)
      profile (ok (map-set consumer-profiles tx-sender
        (merge profile { active: false })
      ))
      (err u201)
    )
  )
)

;; Read-only function to check if a consumer exists
(define-read-only (consumer-exists (consumer principal))
  (match (map-get? consumer-profiles consumer)
    profile (get active profile)
    false
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
