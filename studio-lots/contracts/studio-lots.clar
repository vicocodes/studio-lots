;; Studio Lots - Virtual Film & Video Production Studio
;; A smart contract for managing customizable virtual sets and bookings

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_SET_NOT_AVAILABLE (err u104))
(define-constant ERR_INVALID_BOOKING_TIME (err u105))

;; Data Variables
(define-data-var next-set-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Data Maps
(define-map studio-sets 
  { set-id: uint }
  { 
    name: (string-ascii 50),
    description: (string-utf8 200),
    set-type: (string-ascii 30), ;; e.g., "indoor", "outdoor", "green-screen"
    price-per-hour: uint,
    owner: principal,
    is-active: bool,
    customization-options: (list 5 (string-ascii 50)),
    created-at: uint
  }
)

(define-map bookings
  { booking-id: uint }
  {
    set-id: uint,
    renter: principal,
    start-time: uint,
    duration-hours: uint,
    total-cost: uint,
    customizations: (list 5 (string-ascii 50)),
    status: (string-ascii 20), ;; "pending", "confirmed", "completed", "cancelled"
    created-at: uint
  }
)

(define-map user-profiles
  { user: principal }
  {
    username: (string-ascii 30),
    user-type: (string-ascii 20), ;; "studio-owner", "producer", "director"
    reputation-score: uint,
    total-bookings: uint
  }
)

;; Active bookings tracking - simpler approach
(define-map active-bookings
  { set-id: uint, booking-id: uint }
  { 
    start-time: uint,
    end-time: uint,
    is-active: bool
  }
)

;; Read-only functions

(define-read-only (get-studio-set (set-id uint))
  (map-get? studio-sets { set-id: set-id })
)

(define-read-only (get-booking (booking-id uint))
  (map-get? bookings { booking-id: booking-id })
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

(define-read-only (calculate-total-cost (price-per-hour uint) (duration uint))
  (let ((base-cost (* price-per-hour duration))
        (platform-fee (/ (* base-cost (var-get platform-fee-percentage)) u100)))
    (+ base-cost platform-fee))
)

(define-read-only (get-active-booking (set-id uint) (booking-id uint))
  (map-get? active-bookings { set-id: set-id, booking-id: booking-id })
)

;; Public functions

;; Create user profile
(define-public (create-user-profile (username (string-ascii 30)) (user-type (string-ascii 20)))
  (let ((user tx-sender))
    (if (is-some (map-get? user-profiles { user: user }))
      ERR_ALREADY_EXISTS
      (ok (map-set user-profiles
        { user: user }
        {
          username: username,
          user-type: user-type,
          reputation-score: u0,
          total-bookings: u0
        }))))
)

;; Create a new studio set
(define-public (create-studio-set 
  (name (string-ascii 50))
  (description (string-utf8 200))
  (set-type (string-ascii 30))
  (price-per-hour uint)
  (customization-options (list 5 (string-ascii 50))))
  (let ((set-id (var-get next-set-id))
        (owner tx-sender))
    (begin
      (map-set studio-sets
        { set-id: set-id }
        {
          name: name,
          description: description,
          set-type: set-type,
          price-per-hour: price-per-hour,
          owner: owner,
          is-active: true,
          customization-options: customization-options,
          created-at: stacks-block-height
        })
      (var-set next-set-id (+ set-id u1))
      (ok set-id)))
)

;; Book a studio set
(define-public (book-studio-set 
  (set-id uint)
  (start-time uint)
  (duration-hours uint)
  (customizations (list 5 (string-ascii 50))))
  (let ((set-info (unwrap! (map-get? studio-sets { set-id: set-id }) ERR_NOT_FOUND))
        (booking-id (var-get next-booking-id))
        (total-cost (calculate-total-cost (get price-per-hour set-info) duration-hours))
        (end-time (+ start-time duration-hours)))
    
    ;; Check if set is active
    (asserts! (get is-active set-info) ERR_SET_NOT_AVAILABLE)
    (asserts! (> duration-hours u0) ERR_INVALID_BOOKING_TIME)
    (asserts! (> start-time stacks-block-height) ERR_INVALID_BOOKING_TIME)
    
    ;; Simple availability check - in production you'd implement more sophisticated logic
    ;; For now, we just store the booking and let the UI handle conflicts
    
    ;; Create booking record
    (map-set bookings
      { booking-id: booking-id }
      {
        set-id: set-id,
        renter: tx-sender,
        start-time: start-time,
        duration-hours: duration-hours,
        total-cost: total-cost,
        customizations: customizations,
        status: "confirmed",
        created-at: stacks-block-height
      })
    
    ;; Track active booking
    (map-set active-bookings
      { set-id: set-id, booking-id: booking-id }
      {
        start-time: start-time,
        end-time: end-time,
        is-active: true
      })
    
    ;; Update user profile
    (match (map-get? user-profiles { user: tx-sender })
      user-profile (map-set user-profiles
        { user: tx-sender }
        (merge user-profile { total-bookings: (+ (get total-bookings user-profile) u1) }))
      true)
    
    (var-set next-booking-id (+ booking-id u1))
    (ok booking-id))
)

;; Update set status (active/inactive)
(define-public (toggle-set-status (set-id uint))
  (let ((set-info (unwrap! (map-get? studio-sets { set-id: set-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner set-info)) ERR_NOT_AUTHORIZED)
    (ok (map-set studio-sets
      { set-id: set-id }
      (merge set-info { is-active: (not (get is-active set-info)) }))))
)

;; Update set pricing
(define-public (update-set-price (set-id uint) (new-price uint))
  (let ((set-info (unwrap! (map-get? studio-sets { set-id: set-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner set-info)) ERR_NOT_AUTHORIZED)
    (ok (map-set studio-sets
      { set-id: set-id }
      (merge set-info { price-per-hour: new-price }))))
)

;; Cancel booking (only by renter or set owner)
(define-public (cancel-booking (booking-id uint))
  (let ((booking-info (unwrap! (map-get? bookings { booking-id: booking-id }) ERR_NOT_FOUND))
        (set-info (unwrap! (map-get? studio-sets { set-id: (get set-id booking-info) }) ERR_NOT_FOUND)))
    
    ;; Check authorization
    (asserts! (or (is-eq tx-sender (get renter booking-info))
                 (is-eq tx-sender (get owner set-info))) ERR_NOT_AUTHORIZED)
    
    ;; Update booking status
    (map-set bookings
      { booking-id: booking-id }
      (merge booking-info { status: "cancelled" }))
    
    ;; Mark active booking as inactive
    (match (map-get? active-bookings { set-id: (get set-id booking-info), booking-id: booking-id })
      active-booking (map-set active-bookings
        { set-id: (get set-id booking-info), booking-id: booking-id }
        (merge active-booking { is-active: false }))
      true)
    
    (ok true))
)

;; Update platform fee (only contract owner)
(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee u20) (err u106)) ;; Max 20% fee
    (ok (var-set platform-fee-percentage new-fee)))
)

;; Complete booking and update reputation
(define-public (complete-booking (booking-id uint) (rating uint))
  (let ((booking-info (unwrap! (map-get? bookings { booking-id: booking-id }) ERR_NOT_FOUND))
        (set-info (unwrap! (map-get? studio-sets { set-id: (get set-id booking-info) }) ERR_NOT_FOUND)))
    
    ;; Only set owner can mark as complete
    (asserts! (is-eq tx-sender (get owner set-info)) ERR_NOT_AUTHORIZED)
    (asserts! (<= rating u5) (err u107)) ;; Rating 1-5
    
    ;; Update booking status
    (map-set bookings
      { booking-id: booking-id }
      (merge booking-info { status: "completed" }))
    
    ;; Update renter's reputation score
    (match (map-get? user-profiles { user: (get renter booking-info) })
      user-profile 
      (let ((current-score (get reputation-score user-profile))
            (total-bookings (get total-bookings user-profile))
            (new-score (/ (+ (* current-score total-bookings) rating) (+ total-bookings u1))))
        (map-set user-profiles
          { user: (get renter booking-info) }
          (merge user-profile { reputation-score: new-score })))
      true)
    
    (ok true))
)