;; Educational Program Contract
;; Schedules gardening workshops and classes

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-WORKSHOP-NOT-FOUND (err u501))
(define-constant ERR-WORKSHOP-FULL (err u502))
(define-constant ERR-ALREADY-REGISTERED (err u503))
(define-constant ERR-NOT-REGISTERED (err u504))
(define-constant ERR-WORKSHOP-PAST (err u505))
(define-constant ERR-INVALID-CAPACITY (err u506))

;; Data Variables
(define-data-var next-workshop-id uint u1)
(define-data-var next-instructor-id uint u1)

;; Data Maps
(define-map workshops
  { workshop-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    instructor-id: uint,
    scheduled-date: uint,
    duration-blocks: uint,
    max-participants: uint,
    current-participants: uint,
    skill-level: (string-ascii 20), ;; "beginner", "intermediate", "advanced"
    materials-provided: bool,
    location: (string-ascii 50),
    is-active: bool
  }
)

(define-map instructors
  { instructor-id: uint }
  {
    name: (string-ascii 50),
    address: principal,
    specialties: (list 5 (string-ascii 30)),
    experience-years: uint,
    rating: uint, ;; 1-5 scale
    total-workshops: uint,
    is-certified: bool
  }
)

(define-map workshop-registrations
  { workshop-id: uint, participant: principal }
  {
    registration-date: uint,
    attended: bool,
    completion-certificate: bool,
    feedback-rating: (optional uint),
    feedback-notes: (string-ascii 200)
  }
)

(define-map participant-history
  { participant: principal }
  {
    workshops-attended: (list 20 uint),
    total-workshops: uint,
    certificates-earned: uint,
    skill-level: (string-ascii 20),
    preferred-topics: (list 5 (string-ascii 30))
  }
)

(define-map workshop-materials
  { workshop-id: uint }
  {
    required-tools: (list 10 (string-ascii 30)),
    provided-materials: (list 10 (string-ascii 30)),
    take-home-items: (list 5 (string-ascii 30)),
    preparation-notes: (string-ascii 200)
  }
)

;; Private Functions
(define-private (is-workshop-instructor (workshop-id uint) (user principal))
  (match (map-get? workshops { workshop-id: workshop-id })
    workshop-data (match (map-get? instructors { instructor-id: (get instructor-id workshop-data) })
      instructor-data (is-eq (get address instructor-data) user)
      false
    )
    false
  )
)

(define-private (is-workshop-full (workshop-id uint))
  (match (map-get? workshops { workshop-id: workshop-id })
    workshop-data (>= (get current-participants workshop-data) (get max-participants workshop-data))
    true
  )
)

(define-private (is-already-registered (workshop-id uint) (participant principal))
  (is-some (map-get? workshop-registrations { workshop-id: workshop-id, participant: participant }))
)

;; Public Functions

;; Register an instructor
(define-public (register-instructor (name (string-ascii 50)) (instructor-address principal) (experience uint))
  (let ((instructor-id (var-get next-instructor-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set instructors
      { instructor-id: instructor-id }
      {
        name: name,
        address: instructor-address,
        specialties: (list),
        experience-years: experience,
        rating: u5, ;; Default high rating
        total-workshops: u0,
        is-certified: true
      }
    )

    (var-set next-instructor-id (+ instructor-id u1))
    (ok instructor-id)
  )
)

;; Create a workshop
(define-public (create-workshop
  (title (string-ascii 100))
  (description (string-ascii 300))
  (instructor-id uint)
  (scheduled-date uint)
  (duration uint)
  (max-participants uint)
  (skill-level (string-ascii 20)))
  (let ((workshop-id (var-get next-workshop-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> scheduled-date block-height) ERR-WORKSHOP-PAST)
    (asserts! (> max-participants u0) ERR-INVALID-CAPACITY)
    (asserts! (is-some (map-get? instructors { instructor-id: instructor-id })) ERR-NOT-AUTHORIZED)

    (map-set workshops
      { workshop-id: workshop-id }
      {
        title: title,
        description: description,
        instructor-id: instructor-id,
        scheduled-date: scheduled-date,
        duration-blocks: duration,
        max-participants: max-participants,
        current-participants: u0,
        skill-level: skill-level,
        materials-provided: true,
        location: "Community Garden",
        is-active: true
      }
    )

    (var-set next-workshop-id (+ workshop-id u1))
    (ok workshop-id)
  )
)

;; Register for a workshop
(define-public (register-workshop (workshop-id uint))
  (let (
    (workshop-data (unwrap! (map-get? workshops { workshop-id: workshop-id }) ERR-WORKSHOP-NOT-FOUND))
    (participant-data (default-to { workshops-attended: (list), total-workshops: u0, certificates-earned: u0, skill-level: "beginner", preferred-topics: (list) }
                                 (map-get? participant-history { participant: tx-sender })))
  )
    (asserts! (get is-active workshop-data) ERR-WORKSHOP-NOT-FOUND)
    (asserts! (> (get scheduled-date workshop-data) block-height) ERR-WORKSHOP-PAST)
    (asserts! (not (is-workshop-full workshop-id)) ERR-WORKSHOP-FULL)
    (asserts! (not (is-already-registered workshop-id tx-sender)) ERR-ALREADY-REGISTERED)

    ;; Register participant
    (map-set workshop-registrations
      { workshop-id: workshop-id, participant: tx-sender }
      {
        registration-date: block-height,
        attended: false,
        completion-certificate: false,
        feedback-rating: none,
        feedback-notes: ""
      }
    )

    ;; Update workshop participant count
    (map-set workshops
      { workshop-id: workshop-id }
      (merge workshop-data {
        current-participants: (+ (get current-participants workshop-data) u1)
      })
    )

    ;; Update participant history
    (map-set participant-history
      { participant: tx-sender }
      (merge participant-data {
        workshops-attended: (unwrap! (as-max-len? (append (get workshops-attended participant-data) workshop-id) u20) (err u507))
      })
    )

    (ok true)
  )
)

;; Mark attendance
(define-public (mark-attendance (workshop-id uint) (participant principal))
  (let ((registration-data (unwrap! (map-get? workshop-registrations { workshop-id: workshop-id, participant: participant }) ERR-NOT-REGISTERED)))
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-workshop-instructor workshop-id tx-sender)) ERR-NOT-AUTHORIZED)

    (map-set workshop-registrations
      { workshop-id: workshop-id, participant: participant }
      (merge registration-data { attended: true })
    )

    (ok true)
  )
)

;; Award certificate
(define-public (award-certificate (workshop-id uint) (participant principal))
  (let (
    (registration-data (unwrap! (map-get? workshop-registrations { workshop-id: workshop-id, participant: participant }) ERR-NOT-REGISTERED))
    (participant-data (unwrap! (map-get? participant-history { participant: participant }) ERR-NOT-REGISTERED))
  )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-workshop-instructor workshop-id tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (get attended registration-data) ERR-NOT-REGISTERED)

    ;; Award certificate
    (map-set workshop-registrations
      { workshop-id: workshop-id, participant: participant }
      (merge registration-data { completion-certificate: true })
    )

    ;; Update participant stats
    (map-set participant-history
      { participant: participant }
      (merge participant-data {
        total-workshops: (+ (get total-workshops participant-data) u1),
        certificates-earned: (+ (get certificates-earned participant-data) u1)
      })
    )

    (ok true)
  )
)

;; Submit feedback
(define-public (submit-feedback (workshop-id uint) (rating uint) (notes (string-ascii 200)))
  (let ((registration-data (unwrap! (map-get? workshop-registrations { workshop-id: workshop-id, participant: tx-sender }) ERR-NOT-REGISTERED)))
    (asserts! (get attended registration-data) ERR-NOT-REGISTERED)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-CAPACITY)

    (map-set workshop-registrations
      { workshop-id: workshop-id, participant: tx-sender }
      (merge registration-data {
        feedback-rating: (some rating),
        feedback-notes: notes
      })
    )

    (ok true)
  )
)

;; Cancel workshop
(define-public (cancel-workshop (workshop-id uint))
  (let ((workshop-data (unwrap! (map-get? workshops { workshop-id: workshop-id }) ERR-WORKSHOP-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set workshops
      { workshop-id: workshop-id }
      (merge workshop-data { is-active: false })
    )

    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-workshop (workshop-id uint))
  (map-get? workshops { workshop-id: workshop-id })
)

(define-read-only (get-instructor (instructor-id uint))
  (map-get? instructors { instructor-id: instructor-id })
)

(define-read-only (get-registration (workshop-id uint) (participant principal))
  (map-get? workshop-registrations { workshop-id: workshop-id, participant: participant })
)

(define-read-only (get-participant-history (participant principal))
  (map-get? participant-history { participant: participant })
)

(define-read-only (get-workshop-materials (workshop-id uint))
  (map-get? workshop-materials { workshop-id: workshop-id })
)

(define-read-only (is-workshop-available (workshop-id uint))
  (match (map-get? workshops { workshop-id: workshop-id })
    workshop-data (and
      (get is-active workshop-data)
      (> (get scheduled-date workshop-data) block-height)
      (< (get current-participants workshop-data) (get max-participants workshop-data))
    )
    false
  )
)

(define-read-only (get-upcoming-workshops)
  ;; This would need iteration in a real implementation
  ;; For now, return next workshop ID as placeholder
  (var-get next-workshop-id)
)
