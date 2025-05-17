;; Recommendation Contract
;; This contract generates personalized suggestions

(define-data-var admin principal tx-sender)

;; Map to store product recommendations by retailer and category
(define-map product-recommendations
  (tuple (retailer principal) (category (string-utf8 30)) (product-id (string-utf8 50)))
  {
    name: (string-utf8 100),
    description: (string-utf8 255),
    price: uint,
    active: bool
  }
)

;; Map to track all products by retailer and category
(define-map retailer-products
  (tuple (retailer principal) (category (string-utf8 30)))
  (list 50 (string-utf8 50))
)

;; Public function for retailers to add a product recommendation
(define-public (add-product (category (string-utf8 30)) (product-id (string-utf8 50))
                           (name (string-utf8 100)) (description (string-utf8 255)) (price uint))
  (let (
    (retailer tx-sender)
    (current-products (default-to (list)
      (map-get? retailer-products (tuple (retailer retailer) (category category)))))
  )
    (begin
      ;; Add product to retailer's list if not already present
      (if (is-none (index-of current-products product-id))
        (map-set retailer-products (tuple (retailer retailer) (category category))
          (unwrap-panic (as-max-len? (append current-products product-id) u50)))
        true)

      ;; Set the product details
      (ok (map-set product-recommendations
        (tuple (retailer retailer) (category category) (product-id product-id))
        {
          name: name,
          description: description,
          price: price,
          active: true
        }
      ))
    )
  )
)

;; Public function for retailers to deactivate a product
(define-public (deactivate-product (category (string-utf8 30)) (product-id (string-utf8 50)))
  (let (
    (retailer tx-sender)
    (product-key (tuple (retailer retailer) (category category) (product-id product-id)))
  )
    (match (map-get? product-recommendations product-key)
      product (ok (map-set product-recommendations product-key
        (merge product { active: false })
      ))
      (err u401)
    )
  )
)

;; Read-only function to get product details
(define-read-only (get-product (retailer principal) (category (string-utf8 30)) (product-id (string-utf8 50)))
  (map-get? product-recommendations (tuple (retailer retailer) (category category) (product-id product-id)))
)

;; Read-only function to get all products for a retailer in a category
(define-read-only (get-retailer-products (retailer principal) (category (string-utf8 30)))
  (default-to (list) (map-get? retailer-products (tuple (retailer retailer) (category category))))
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
