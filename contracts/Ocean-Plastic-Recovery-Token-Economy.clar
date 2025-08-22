(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INVALID_LOCATION (err u102))
(define-constant ERR_ALREADY_VERIFIED (err u103))
(define-constant ERR_NOT_FOUND (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_INVALID_RECYCLER (err u106))
(define-constant ERR_COLLECTION_NOT_VERIFIED (err u107))

(define-fungible-token ocean-plastic-token)

(define-map collections
  { collection-id: uint }
  {
    collector: principal,
    latitude: int,
    longitude: int,
    plastic-amount: uint,
    verified: bool,
    timestamp: uint,
    recycler: (optional principal)
  }
)

(define-map recyclers
  { recycler: principal }
  {
    name: (string-ascii 50),
    verified: bool,
    total-processed: uint
  }
)

(define-map user-stats
  { user: principal }
  {
    total-collected: uint,
    total-tokens-earned: uint,
    collections-count: uint
  }
)

(define-data-var collection-counter uint u0)
(define-data-var token-reward-rate uint u10)
(define-data-var verification-threshold uint u5)

(define-read-only (get-collection (collection-id uint))
  (map-get? collections { collection-id: collection-id })
)

(define-read-only (get-recycler (recycler principal))
  (map-get? recyclers { recycler: recycler })
)

(define-read-only (get-user-stats (user principal))
  (map-get? user-stats { user: user })
)

(define-read-only (get-token-balance (user principal))
  (ft-get-balance ocean-plastic-token user)
)

(define-read-only (get-total-supply)
  (ft-get-supply ocean-plastic-token)
)

(define-read-only (get-collection-counter)
  (var-get collection-counter)
)

(define-read-only (get-token-reward-rate)
  (var-get token-reward-rate)
)

(define-public (register-recycler (name (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set recyclers
      { recycler: tx-sender }
      {
        name: name,
        verified: true,
        total-processed: u0
      }
    ))
  )
)

(define-public (submit-collection (latitude int) (longitude int) (plastic-amount uint))
  (let
    (
      (collection-id (+ (var-get collection-counter) u1))
    )
    (asserts! (> plastic-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (and (>= latitude -90000000) (<= latitude 90000000)) ERR_INVALID_LOCATION)
    (asserts! (and (>= longitude -180000000) (<= longitude 180000000)) ERR_INVALID_LOCATION)
    
    (map-set collections
      { collection-id: collection-id }
      {
        collector: tx-sender,
        latitude: latitude,
        longitude: longitude,
        plastic-amount: plastic-amount,
        verified: false,
        timestamp: stacks-block-height,
        recycler: none
      }
    )
    
    (var-set collection-counter collection-id)
    (ok collection-id)
  )
)

(define-public (verify-collection (collection-id uint))
  (let
    (
      (collection-data (unwrap! (get-collection collection-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get verified collection-data) false) ERR_ALREADY_VERIFIED)
    
    (map-set collections
      { collection-id: collection-id }
      (merge collection-data { verified: true })
    )
    
    (let
      (
        (collector (get collector collection-data))
        (plastic-amount (get plastic-amount collection-data))
        (tokens-to-mint (* plastic-amount (var-get token-reward-rate)))
        (current-stats (default-to 
          { total-collected: u0, total-tokens-earned: u0, collections-count: u0 }
          (get-user-stats collector)
        ))
      )
      (try! (ft-mint? ocean-plastic-token tokens-to-mint collector))
      
      (map-set user-stats
        { user: collector }
        {
          total-collected: (+ (get total-collected current-stats) plastic-amount),
          total-tokens-earned: (+ (get total-tokens-earned current-stats) tokens-to-mint),
          collections-count: (+ (get collections-count current-stats) u1)
        }
      )
      
      (ok tokens-to-mint)
    )
  )
)

(define-public (assign-recycler (collection-id uint) (recycler principal))
  (let
    (
      (collection-data (unwrap! (get-collection collection-id) ERR_NOT_FOUND))
      (recycler-data (unwrap! (get-recycler recycler) ERR_INVALID_RECYCLER))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (get verified collection-data) ERR_COLLECTION_NOT_VERIFIED)
    (asserts! (get verified recycler-data) ERR_INVALID_RECYCLER)
    
    (map-set collections
      { collection-id: collection-id }
      (merge collection-data { recycler: (some recycler) })
    )
    
    (map-set recyclers
      { recycler: recycler }
      (merge recycler-data 
        { total-processed: (+ (get total-processed recycler-data) (get plastic-amount collection-data)) }
      )
    )
    
    (ok true)
  )
)

(define-public (exchange-tokens-for-eco-credits (token-amount uint))
  (let
    (
      (user-balance (ft-get-balance ocean-plastic-token tx-sender))
    )
    (asserts! (>= user-balance token-amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> token-amount u0) ERR_INVALID_AMOUNT)
    
    (try! (ft-burn? ocean-plastic-token token-amount tx-sender))
    (ok token-amount)
  )
)

(define-public (transfer-tokens (amount uint) (recipient principal))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (ft-transfer? ocean-plastic-token amount tx-sender recipient)
  )
)

(define-public (set-token-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> new-rate u0) ERR_INVALID_AMOUNT)
    (var-set token-reward-rate new-rate)
    (ok true)
  )
)

(define-public (set-verification-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set verification-threshold new-threshold)
    (ok true)
  )
)

(define-read-only (calculate-rewards (plastic-amount uint))
  (* plastic-amount (var-get token-reward-rate))
)

(define-read-only (is-valid-gps-location (latitude int) (longitude int))
  (and 
    (and (>= latitude -90000000) (<= latitude 90000000))
    (and (>= longitude -180000000) (<= longitude 180000000))
  )
)

(define-read-only (get-collection-stats (collection-id uint))
  (match (get-collection collection-id)
    collection-data (some {
      collector: (get collector collection-data),
      plastic-amount: (get plastic-amount collection-data),
      verified: (get verified collection-data),
      timestamp: (get timestamp collection-data)
    })
    none
  )
)

(define-read-only (get-recycler-stats (recycler principal))
  (match (get-recycler recycler)
    recycler-data (some {
      name: (get name recycler-data),
      verified: (get verified recycler-data),
      total-processed: (get total-processed recycler-data)
    })
    none
  )
)

(define-public (bulk-verify-collections (collection-ids (list 10 uint)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map verify-single-collection collection-ids))
  )
)

(define-private (verify-single-collection (collection-id uint))
  (match (verify-collection collection-id)
    success success
    error u0
  )
)

(ft-mint? ocean-plastic-token u1000000 CONTRACT_OWNER)
