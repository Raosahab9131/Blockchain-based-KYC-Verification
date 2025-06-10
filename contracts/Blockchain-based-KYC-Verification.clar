;; Blockchain-based KYC Verification
;; Users submit KYC data hashes; admin verifies or rejects them.

(define-constant err-already-submitted (err u100))
(define-constant err-not-submitted (err u101))
(define-constant err-not-admin (err u102))

;; Contract owner (admin)
(define-constant admin tx-sender)

;; KYC statuses
(define-constant STATUS_PENDING u0)
(define-constant STATUS_APPROVED u1)
(define-constant STATUS_REJECTED u2)

;; KYC record map
(define-map kyc-records principal
  {
    doc-hash: (buff 32),
    status: uint
  }
)

;; Submit KYC document hash (one-time submission)
(define-public (submit-kyc (doc-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? kyc-records tx-sender)) err-already-submitted)
    (map-set kyc-records tx-sender {doc-hash: doc-hash, status: STATUS_PENDING})
    (ok true)
  )
)

;; Admin verifies or rejects a users KYC
(define-public (update-kyc-status (user principal) (new-status uint))
  (begin
    (asserts! (is-eq tx-sender admin) err-not-admin)
    (let ((entry (map-get? kyc-records user)))
      (match entry
        data 
        (begin
          (map-set kyc-records user {
            doc-hash: (get doc-hash data),
            status: new-status
          })
          (ok true)
        )
        err-not-submitted
      )
    )
  )
)

;; Get KYC status for a user
(define-read-only (get-kyc-status (user principal))
  (match (map-get? kyc-records user)
    data (get status data)
    STATUS_PENDING
  )
)

;; Check if user is approved
(define-read-only (is-kyc-approved (user principal))
  (is-eq (get-kyc-status user) STATUS_APPROVED)
)

;; Get KYC record
(define-read-only (get-kyc-record (user principal))
  (map-get? kyc-records user)
)