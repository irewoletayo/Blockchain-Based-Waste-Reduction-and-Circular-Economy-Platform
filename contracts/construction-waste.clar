;; Construction Waste Management Contract
;; Maximizes reuse and recycling of building materials

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-CONDITION (err u104))

;; Data Variables
(define-data-var next-material-id uint u1)
(define-data-var next-project-id uint u1)

;; Data Maps
(define-map construction-materials
  { material-id: (string-ascii 50) }
  {
    material-type: (string-ascii 50),
    category: (string-ascii 50),
    quantity: uint,
    unit: (string-ascii 20),
    condition: (string-ascii 20),
    quality-grade: (string-ascii 10),
    location: (string-ascii 200),
    source-project: (string-ascii 100),
    reuse-potential: uint,
    recycling-potential: uint,
    estimated-value: uint,
    environmental-impact: uint,
    owner: principal,
    created-at: uint,
    updated-at: uint
  }
)

(define-map construction-projects
  { project-id: uint }
  {
    name: (string-ascii 100),
    project-type: (string-ascii 50),
    location: (string-ascii 200),
    contractor: principal,
    start-date: uint,
    end-date: uint,
    waste-generated: uint,
    waste-diverted: uint,
    sustainability-score: uint,
    active: bool
  }
)

(define-map material-exchanges
  { exchange-id: (string-ascii 50) }
  {
    material-id: (string-ascii 50),
    from-project: uint,
    to-project: uint,
    quantity-transferred: uint,
    transfer-date: uint,
    cost-savings: uint,
    environmental-benefit: uint,
    status: (string-ascii 20)
  }
)

(define-map recycling-facilities
  { facility-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    location: (string-ascii 200),
    accepted-materials: (list 20 (string-ascii 50)),
    processing-capacity: uint,
    recovery-rate: uint,
    certifications: (list 5 (string-ascii 50)),
    operator: principal,
    active: bool
  }
)

(define-map demolition-plans
  { plan-id: (string-ascii 50) }
  {
    project-id: uint,
    building-type: (string-ascii 50),
    demolition-method: (string-ascii 50),
    salvageable-materials: (list 20 (string-ascii 50)),
    waste-minimization-strategy: (string-ascii 200),
    expected-recovery-rate: uint,
    planner: principal,
    approved: bool
  }
)

(define-map authorized-contractors
  { contractor: principal }
  { authorized: bool }
)

;; Authorization Functions
(define-private (is-authorized (party principal))
  (or
    (is-eq party CONTRACT-OWNER)
    (default-to false (get authorized (map-get? authorized-contractors { contractor: party })))
  )
)

(define-public (authorize-contractor (contractor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-contractors { contractor: contractor } { authorized: true }))
  )
)

;; Validation Functions
(define-private (is-valid-condition (condition (string-ascii 20)))
  (or
    (is-eq condition "excellent")
    (is-eq condition "good")
    (is-eq condition "fair")
    (is-eq condition "poor")
    (is-eq condition "damaged")
  )
)

(define-private (is-valid-grade (grade (string-ascii 10)))
  (or
    (is-eq grade "A")
    (is-eq grade "B")
    (is-eq grade "C")
    (is-eq grade "D")
  )
)

(define-private (is-valid-score (score uint))
  (and (>= score u0) (<= score u100))
)

;; Core Functions
(define-public (register-construction-material
  (material-id (string-ascii 50))
  (material-type (string-ascii 50))
  (category (string-ascii 50))
  (quantity uint)
  (unit (string-ascii 20))
  (condition (string-ascii 20))
  (location (string-ascii 200))
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (> (len material-id) u0) ERR-INVALID-INPUT)
      (asserts! (> (len material-type) u0) ERR-INVALID-INPUT)
      (asserts! (> (len category) u0) ERR-INVALID-INPUT)
      (asserts! (> quantity u0) ERR-INVALID-INPUT)
      (asserts! (> (len unit) u0) ERR-INVALID-INPUT)
      (asserts! (is-valid-condition condition) ERR-INVALID-CONDITION)
      (asserts! (> (len location) u0) ERR-INVALID-INPUT)
      (asserts! (is-none (map-get? construction-materials { material-id: material-id })) ERR-ALREADY-EXISTS)

      (map-set construction-materials
        { material-id: material-id }
        {
          material-type: material-type,
          category: category,
          quantity: quantity,
          unit: unit,
          condition: condition,
          quality-grade: "C",
          location: location,
          source-project: "",
          reuse-potential: u0,
          recycling-potential: u0,
          estimated-value: u0,
          environmental-impact: u0,
          owner: tx-sender,
          created-at: current-time,
          updated-at: current-time
        }
      )

      (ok material-id)
    )
  )
)

(define-public (create-construction-project
  (name (string-ascii 100))
  (project-type (string-ascii 50))
  (location (string-ascii 200))
  (start-date uint)
  (end-date uint)
)
  (let
    (
      (project-id (var-get next-project-id))
    )
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (> (len name) u0) ERR-INVALID-INPUT)
      (asserts! (> (len project-type) u0) ERR-INVALID-INPUT)
      (asserts! (> (len location) u0) ERR-INVALID-INPUT)
      (asserts! (< start-date end-date) ERR-INVALID-INPUT)

      (map-set construction-projects
        { project-id: project-id }
        {
          name: name,
          project-type: project-type,
          location: location,
          contractor: tx-sender,
          start-date: start-date,
          end-date: end-date,
          waste-generated: u0,
          waste-diverted: u0,
          sustainability-score: u0,
          active: true
        }
      )

      (var-set next-project-id (+ project-id u1))
      (ok project-id)
    )
  )
)

(define-public (update-material-assessment
  (material-id (string-ascii 50))
  (quality-grade (string-ascii 10))
  (reuse-potential uint)
  (recycling-potential uint)
  (estimated-value uint)
)
  (let
    (
      (material (unwrap! (map-get? construction-materials { material-id: material-id }) ERR-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (is-valid-grade quality-grade) ERR-INVALID-INPUT)
      (asserts! (is-valid-score reuse-potential) ERR-INVALID-INPUT)
      (asserts! (is-valid-score recycling-potential) ERR-INVALID-INPUT)

      (map-set construction-materials
        { material-id: material-id }
        (merge material {
          quality-grade: quality-grade,
          reuse-potential: reuse-potential,
          recycling-potential: recycling-potential,
          estimated-value: estimated-value,
          updated-at: current-time
        })
      )

      (ok true)
    )
  )
)

(define-public (create-material-exchange
  (exchange-id (string-ascii 50))
  (material-id (string-ascii 50))
  (from-project uint)
  (to-project uint)
  (quantity-transferred uint)
)
  (let
    (
      (material (unwrap! (map-get? construction-materials { material-id: material-id }) ERR-NOT-FOUND))
      (from-proj (unwrap! (map-get? construction-projects { project-id: from-project }) ERR-NOT-FOUND))
      (to-proj (unwrap! (map-get? construction-projects { project-id: to-project }) ERR-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (> (len exchange-id) u0) ERR-INVALID-INPUT)
      (asserts! (> quantity-transferred u0) ERR-INVALID-INPUT)
      (asserts! (<= quantity-transferred (get quantity material)) ERR-INVALID-INPUT)
      (asserts! (is-none (map-get? material-exchanges { exchange-id: exchange-id })) ERR-ALREADY-EXISTS)

      (map-set material-exchanges
        { exchange-id: exchange-id }
        {
          material-id: material-id,
          from-project: from-project,
          to-project: to-project,
          quantity-transferred: quantity-transferred,
          transfer-date: current-time,
          cost-savings: u0,
          environmental-benefit: u0,
          status: "pending"
        }
      )

      (ok exchange-id)
    )
  )
)

(define-public (register-recycling-facility
  (facility-id (string-ascii 50))
  (name (string-ascii 100))
  (location (string-ascii 200))
  (accepted-materials (list 20 (string-ascii 50)))
  (processing-capacity uint)
)
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len facility-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> processing-capacity u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? recycling-facilities { facility-id: facility-id })) ERR-ALREADY-EXISTS)

    (map-set recycling-facilities
      { facility-id: facility-id }
      {
        name: name,
        location: location,
        accepted-materials: accepted-materials,
        processing-capacity: processing-capacity,
        recovery-rate: u0,
        certifications: (list),
        operator: tx-sender,
        active: true
      }
    )

    (ok facility-id)
  )
)

(define-public (create-demolition-plan
  (plan-id (string-ascii 50))
  (project-id uint)
  (building-type (string-ascii 50))
  (demolition-method (string-ascii 50))
  (salvageable-materials (list 20 (string-ascii 50)))
  (waste-minimization-strategy (string-ascii 200))
)
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len plan-id) u0) ERR-INVALID-INPUT)
    (asserts! (is-some (map-get? construction-projects { project-id: project-id })) ERR-NOT-FOUND)
    (asserts! (> (len building-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len demolition-method) u0) ERR-INVALID-INPUT)
    (asserts! (> (len waste-minimization-strategy) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? demolition-plans { plan-id: plan-id })) ERR-ALREADY-EXISTS)

    (map-set demolition-plans
      { plan-id: plan-id }
      {
        project-id: project-id,
        building-type: building-type,
        demolition-method: demolition-method,
        salvageable-materials: salvageable-materials,
        waste-minimization-strategy: waste-minimization-strategy,
        expected-recovery-rate: u0,
        planner: tx-sender,
        approved: false
      }
    )

    (ok plan-id)
  )
)

(define-public (update-project-waste-metrics
  (project-id uint)
  (waste-generated uint)
  (waste-diverted uint)
)
  (let
    (
      (project (unwrap! (map-get? construction-projects { project-id: project-id }) ERR-NOT-FOUND))
      (diversion-rate (if (> waste-generated u0) (/ (* waste-diverted u100) waste-generated) u0))
    )
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (>= waste-generated waste-diverted) ERR-INVALID-INPUT)

      (map-set construction-projects
        { project-id: project-id }
        (merge project {
          waste-generated: waste-generated,
          waste-diverted: waste-diverted,
          sustainability-score: diversion-rate
        })
      )

      (ok true)
    )
  )
)

;; Read-only Functions
(define-read-only (get-construction-material (material-id (string-ascii 50)))
  (map-get? construction-materials { material-id: material-id })
)

(define-read-only (get-construction-project (project-id uint))
  (map-get? construction-projects { project-id: project-id })
)

(define-read-only (get-material-exchange (exchange-id (string-ascii 50)))
  (map-get? material-exchanges { exchange-id: exchange-id })
)

(define-read-only (get-recycling-facility (facility-id (string-ascii 50)))
  (map-get? recycling-facilities { facility-id: facility-id })
)

(define-read-only (get-demolition-plan (plan-id (string-ascii 50)))
  (map-get? demolition-plans { plan-id: plan-id })
)

(define-read-only (calculate-reuse-score (material-id (string-ascii 50)))
  (match (map-get? construction-materials { material-id: material-id })
    material
    (let
      (
        (reuse-potential (get reuse-potential material))
        (recycling-potential (get recycling-potential material))
        (condition-bonus (if (is-eq (get condition material) "excellent") u20 u0))
      )
      (some (+ reuse-potential recycling-potential condition-bonus))
    )
    none
  )
)

(define-read-only (get-project-sustainability-score (project-id uint))
  (match (map-get? construction-projects { project-id: project-id })
    project (some (get sustainability-score project))
    none
  )
)

(define-read-only (is-contractor-authorized (contractor principal))
  (is-authorized contractor)
)
