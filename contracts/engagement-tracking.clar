;; Engagement Tracking Contract
;; This contract monitors customer interactions

(define-data-var admin principal tx-sender)

;; Map to store consumer engagement with products
(define-map consumer-engagements
  (tuple (consumer principal) (retailer principal) (product-id (string-utf8 50)))
  {
    view-count: uint,
    last-viewed: uint,
    purchase-count: uint,
    last-purchased: uint
  }
)

;; Public function for retailers to record a product view
(define-public (record-view (consumer principal) (product-id (string-utf8 50)))
  (let (
    (retailer tx-sender)
    (engagement-key (tuple (consumer consumer) (retailer retailer) (product-id product-id)))
    (current-engagement (default-to
      { view-count: u0, last-viewed: u0, purchase-count: u0, last-purchased: u0 }
      (map-get? consumer-engagements engagement-key)))
  )
    (ok (map-set consumer-engagements engagement-key
      (merge current-engagement {
        view-count: (+ (get view-count current-engagement) u1),
        last-viewed: block-height
      })
    ))
  )
)

;; Public function for retailers to record a product purchase
(define-public (record-purchase (consumer principal) (product-id (string-utf8 50)))
  (let (
    (retailer tx-sender)
    (engagement-key (tuple (consumer consumer) (retailer retailer) (product-id product-id)))
    (current-engagement (default-to
      { view-count: u0, last-viewed: u0, purchase-count: u0, last-purchased: u0 }
      (map-get? consumer-engagements engagement-key)))
  )
    (ok (map-set consumer-engagements engagement-key
      (merge current-engagement {
        purchase-count: (+ (get purchase-count current-engagement) u1),
        last-purchased: block-height
      })
    ))
  )
)

;; Read-only function to get consumer engagement with a product
(define-read-only (get-engagement (consumer principal) (retailer principal) (product-id (string-utf8 50)))
  (default-to
    { view-count: u0, last-viewed: u0, purchase-count: u0, last-purchased: u0 }
    (map-get? consumer-engagements (tuple (consumer consumer) (retailer retailer) (product-id product-id)))
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
