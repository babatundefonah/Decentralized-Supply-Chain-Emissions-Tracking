;; Entity Verification Contract
;; Validates supply chain participants

(define-data-var admin principal tx-sender)

;; Entity status: 0 = unverified, 1 = verified, 2 = suspended
(define-map entities
  { entity-id: principal }
  {
    name: (string-utf8 100),
    industry: (string-utf8 50),
    status: uint,
    registration-date: uint
  }
)

(define-read-only (get-entity (entity-id principal))
  (map-get? entities { entity-id: entity-id })
)

(define-read-only (is-verified (entity-id principal))
  (let ((entity (map-get? entities { entity-id: entity-id })))
    (if (is-some entity)
      (is-eq (get status (unwrap-panic entity)) u1)
      false
    )
  )
)

(define-public (register-entity (name (string-utf8 100)) (industry (string-utf8 50)))
  (let ((entity-id tx-sender))
    (if (is-none (map-get? entities { entity-id: entity-id }))
      (ok (map-set entities
        { entity-id: entity-id }
        {
          name: name,
          industry: industry,
          status: u0, ;; Initially unverified
          registration-date: block-height
        }))
      (err u1) ;; Entity already exists
    )
  )
)

(define-public (verify-entity (entity-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
    (if (is-some (map-get? entities { entity-id: entity-id }))
      (ok (map-set entities
        { entity-id: entity-id }
        (merge (unwrap-panic (map-get? entities { entity-id: entity-id }))
          { status: u1 }))) ;; Set to verified
      (err u404) ;; Entity not found
    )
  )
)

(define-public (suspend-entity (entity-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can suspend
    (if (is-some (map-get? entities { entity-id: entity-id }))
      (ok (map-set entities
        { entity-id: entity-id }
        (merge (unwrap-panic (map-get? entities { entity-id: entity-id }))
          { status: u2 }))) ;; Set to suspended
      (err u404) ;; Entity not found
    )
  )
)

(define-public (update-entity-info (name (string-utf8 100)) (industry (string-utf8 50)))
  (let ((entity-id tx-sender))
    (if (is-some (map-get? entities { entity-id: entity-id }))
      (ok (map-set entities
        { entity-id: entity-id }
        (merge (unwrap-panic (map-get? entities { entity-id: entity-id }))
          {
            name: name,
            industry: industry
          })))
      (err u404) ;; Entity not found
    )
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
