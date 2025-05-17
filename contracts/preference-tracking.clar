;; Preference Tracking Contract
;; This contract records individual interests

(define-data-var admin principal tx-sender)

;; Map to store consumer preferences by category
(define-map consumer-preferences (tuple (consumer principal) (category (string-utf8 30)))
  {
    interest-level: uint,
    last-updated: uint
  }
)

;; Map to track all categories a consumer has preferences for
(define-map consumer-categories principal (list 20 (string-utf8 30)))

;; Public function for consumers to set a preference
(define-public (set-preference (category (string-utf8 30)) (interest-level uint))
  (let (
    (consumer tx-sender)
    (current-categories (default-to (list) (map-get? consumer-categories consumer)))
  )
    (begin
      ;; Interest level must be between 0 and 10
      (asserts! (<= interest-level u10) (err u300))

      ;; Add category to consumer's list if not already present
      (if (is-none (index-of current-categories category))
        (map-set consumer-categories consumer
          (unwrap-panic (as-max-len? (append current-categories category) u20)))
        true)

      ;; Set the preference
      (ok (map-set consumer-preferences (tuple (consumer consumer) (category category))
        {
          interest-level: interest-level,
          last-updated: block-height
        }
      ))
    )
  )
)

;; Read-only function to get a consumer's preference for a category
(define-read-only (get-preference (consumer principal) (category (string-utf8 30)))
  (default-to
    {
      interest-level: u0,
      last-updated: u0
    }
    (map-get? consumer-preferences (tuple (consumer consumer) (category category)))
  )
)

;; Read-only function to get all categories a consumer has preferences for
(define-read-only (get-consumer-categories (consumer principal))
  (default-to (list) (map-get? consumer-categories consumer))
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
