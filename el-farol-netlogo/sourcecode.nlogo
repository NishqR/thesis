extensions [table]

globals [


  attendance                                ;; current attendance at the bar

  ;; tables
  agent-scores                              ;; table of agent and their associated scores

  ;; lists
  all-scores                                ;; list of all the weekly scores of each agent

  ;; time slot related globals
  num-days                                  ;; list of different number of days agents can complete their quota in
  days-of-the-week                          ;; list of days of the week
  time-periods                              ;; list of time periods
  periods-of-the-day                        ;; list of time periods of the day
  current-time-period                       ;; current time period
  current-time-period-index

  ;; patch-related globals
  home-patches                              ;; agentset of green patches representing the residential area
  bar-patches                               ;; agentset of blue patches representing the bar area
  crowded-patch                             ;; patch where we show the "CROWDED" label
  crowded?

  ;; tbd if required
  history                                   ;; list of past values of attendance


  sum-epsilon                               ;; sum of all agent's epsilon values
  all-epsilons                              ;; list of all epsilon values

  exploitation-count                        ;; count of all agents that are exploiting

  mean-score                                ;; average score
  min-all-scores                            ;; minimum of all agent scores
  max-all-scores                            ;; maximum of all agent scores

  mean-attendance

  min-reward                                ;; minimum reward

  num-agents-one-roll                       ;; number of agents that roll once
  num-agents-two-roll                       ;; number of agents that roll twice

  setup-flag                                ;; setup flag that is used to check if the setup is complete
  continue-explore?                         ;; flag to check whether agents should continue exploring
]

turtles-own [

  chosen-num-days                           ;; chosen num-days for the week
  chosen-timeslots                          ;; chosen timeslots for the week
  shopping-quota                            ;; shopping quota for the week, in number of slots
  epsilon-greedy                            ;; epsilon parameter
  weekly-score                              ;; agent's score for the week
  at-shop?                                  ;; boolean indicating whether or not agent is at shop

  overcrowded-timeslots                     ;; list of timeslots during which the store was overcrowded
]

to setup
  clear-all

  ;; initializing variables

  set setup-flag true
  set continue-explore? true

  set mean-score 0
  set min-all-scores 0
  set max-all-scores 0
  set min-reward 1

  set mean-attendance 0

  set all-epsilons []

  set num-days [1 2 4]
  set days-of-the-week ["Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"]
  set time-periods (range 8 24)
  set periods-of-the-day []
  set current-time-period-index 0

  ;; first we combine the days of the week with the periods of the day
  let temp-periods-of-the-day append-words days-of-the-week time-periods

  foreach temp-periods-of-the-day[
    x -> set x x

    foreach x [
      y -> set y y

      set periods-of-the-day insert-item 0 periods-of-the-day y
    ]
  ]

  set periods-of-the-day reverse periods-of-the-day
  show periods-of-the-day


  ;; agent initialization
  set-default-shape turtles "person"
  set all-scores []

  ;; create the 'homes'
  set home-patches patches with [pycor < 0 or (pxcor <  0 and pycor >= 0)]
  ask home-patches [ set pcolor green ]

  ;; create the 'bar'
  set bar-patches patches with [pxcor > 0 and pycor > 0]
  ask bar-patches [ set pcolor blue ]


  ;; use one of the patch labels to visually indicate whether or not the
  ;; bar is "crowded"
  ask patch (0.75 * max-pxcor) (0.5 * max-pycor) [
    set crowded-patch self
    set plabel-color red
    ;;set pcolor red
  ]

  ;; create the table to store agents scores
  set agent-scores table:make

  ;; create the agents and give them random strategies
  create-turtles num-agents [
    set color white
    set at-shop? false

    set weekly-score 0

    move-to-empty-one-of home-patches

    set shopping-quota 4
    set epsilon-greedy 0

    table:put agent-scores who 0

    set chosen-num-days one-of num-days

    set overcrowded-timeslots []

  ]

  update-strategies-112slots
  set num-agents-one-roll 0
  set num-agents-two-roll 0
  ;; show agent-scores

  set setup-flag false
  reset-ticks

end



to go

  ;; if the previous week has elapsed
  if ( current-time-period-index > 111 ) [

    show "a week has elapsed"

    ;; reset the time period index back to 0
    set current-time-period-index 0

    ;; create a table of all the agents' scores
    set agent-scores table:make
    ask turtles [

      table:put agent-scores who weekly-score

      set all-scores insert-item 0 all-scores weekly-score

    ]

    ;;show sort-by < all-scores

    ;;let min-score min all-scores
    ;;let max-score max all-scores

    ;; calculate the average, minimum and maximum score
    set mean-score mean all-scores
    set min-all-scores min all-scores
    set max-all-scores max all-scores

    ;; set the minimum and maximum scores for the epsilon parameter
    ;;let min-score 0
    ;;let max-score 10

    ;; re-initialize the list of all scores
    set all-scores []

    ;; set each agent's epsilon value
    ask turtles [
      set epsilon-greedy ( ( weekly-score - min-score ) / ( max-score - min-score ) )

      set all-epsilons insert-item 0 all-epsilons epsilon-greedy
      set weekly-score 0
    ]

    ;; count the number of agents that are exploiting
    set exploitation-count 0
    let epsilon-values []
    ask turtles [
      set epsilon-values insert-item 0 epsilon-values epsilon-greedy

      if epsilon-greedy >= 1 [
        set exploitation-count exploitation-count + 1
      ]
    ]

    ;; calculate the sum of all the epsilon values
    set sum-epsilon sum epsilon-values


    if sum-epsilon >= 100 [
      set continue-explore? false
    ]

    ;;if continue-explore? = true [
    ;;  update-strategies
    ;;]

    update-strategies-112slots

  ]

  ;; if we are running for the first time / beginning of the week
  if ( current-time-period-index = 0 ) [

    show "beginning of the week"

    ;; create a list of 0s for the attendance counts for each timeslot
    let attendance-counts n-values 112 [0]

    let turtle-count 0
    let slot-count 0

    ask turtles [
      
      set turtle-count turtle-count + 1

      let period-count 0
      ;; loop over all the periods of the day and add the attendance counts
      foreach periods-of-the-day [
        x -> set x x

        set period-count period-count + 1
        if member? x chosen-timeslots [

          set slot-count slot-count + 1
          let position-of-timeslot position x periods-of-the-day

          let new-item item position-of-timeslot attendance-counts + 1

          set attendance-counts replace-item position-of-timeslot attendance-counts new-item


        ]
      ]

      ;;show period-count
    ]

    set mean-attendance mean attendance-counts
    ;;ask turtles[
    ;;  show chosen-timeslots
    ;;]
    show periods-of-the-day
    show attendance-counts
    show turtle-count
    show slot-count
  ]

  ;; during the week
  if ( current-time-period-index <= 111 ) [

    ;; set the current time period
    set current-time-period item current-time-period-index periods-of-the-day

    ;; update the global variables
    ask crowded-patch [ set plabel "" ]

    ;; check if turtles are meant to go during this timeslot
    ask turtles[

      set at-shop? false

      ;; if so, send them to the shop and increase attendance by 1 for this slot
      ifelse member? current-time-period chosen-timeslots
      [
          move-to-empty-one-of bar-patches
          set attendance attendance + 1
          set at-shop? true
      ]

      ;; otherwise stay at home
      [
        move-to-empty-one-of home-patches

      ]

    ]


    set crowded? false

    ;; if the bar is crowded indicate that in the view
    set attendance count turtles-on bar-patches
    if attendance > overcrowding-threshold [
      ask crowded-patch [
        set plabel "CROWDED"
        set crowded? true
      ]
    ]

    ;; ask the agents if they're at the shop
    ask turtles[
      if at-shop? [
        ;; if its crowded, add this slot to their individual list of overcrowded timeslots
        ifelse crowded? [
          set overcrowded-timeslots insert-item 0 overcrowded-timeslots current-time-period

        ]

        ;; if it isnt crowded, update their weekly score as a function of the current attendance
        [
          let reward ( 1 / attendance ) * 100
          ;;let reward 1 +  ( ( ( attendance - overcrowding-threshold ) * ( 10 - 1 ) ) / ( min-reward - overcrowding-threshold ) )
          set weekly-score weekly-score + reward
        ]
      ]

    ]

    ;; update the time period index
    set current-time-period-index current-time-period-index + 1
  ]


  tick

end

to update-strategies-28slots

  set num-agents-one-roll 0
  set num-agents-two-roll 0


  ask turtles[


    if (length overcrowded-timeslots <= 2) and (setup-flag = false)[
      let temp-all-slots periods-of-the-day

      foreach chosen-timeslots[
        x -> set x x
        set temp-all-slots remove x temp-all-slots
      ]

      let new-slots n-of (length overcrowded-timeslots) temp-all-slots

      ;;show "old-timeslots"
      ;;show chosen-timeslots

      ;;show "overcrowded-timeslots"
      ;;show overcrowded-timeslots


      foreach overcrowded-timeslots[
        x -> set x x
        set chosen-timeslots remove x chosen-timeslots
      ]

      foreach new-slots[
        x -> set x x
        set chosen-timeslots insert-item 0 chosen-timeslots x
      ]

      ;;show "new slots"
      ;;show chosen-timeslots


    ]

    if (length overcrowded-timeslots > 2) or (setup-flag = true) [
      let days-roll random-float 1
      let timeslots-roll random-float 1


      ;; choose new number of days and new slots
      if ( timeslots-roll > epsilon-greedy )[

        set num-agents-one-roll num-agents-one-roll + 1
        if ( days-roll > epsilon-greedy ) [

          set chosen-num-days one-of num-days
          set num-agents-two-roll num-agents-two-roll + 1

        ]


        if chosen-num-days = 1[

          let day-chosen []
          set day-chosen insert-item 0 day-chosen one-of days-of-the-week

          ;;show day-chosen

          set chosen-timeslots append-words day-chosen time-periods


          set chosen-timeslots first chosen-timeslots

          ;;show chosen-timeslots

        ]

        if chosen-num-days = 2[

          let days-chosen []

          set days-chosen first insert-item 0 days-chosen n-of 2 days-of-the-week

          ;;let first-day-chosen one-of days-of-the-week
          ;;set days-chosen insert-item 0 days-chosen first-day-chosen
          ;;let day-position position first-day-chosen days-of-the-week
          ;;let remaining-days remove-item day-position days-of-the-week
          ;;set days-chosen insert-item 0 days-chosen one-of remaining-days

          ;;show days-chosen

          let first-day-time-periods n-of 2 time-periods
          let second-day-time-periods n-of 2 time-periods


          let first-day-chosen []
          set first-day-chosen insert-item 0 first-day-chosen first days-chosen

          let second-day-chosen []
          set second-day-chosen insert-item 0 second-day-chosen item 1 days-chosen

          ;;show "-----------------"
          ;;show first-day-chosen
          ;;show second-day-chosen
          ;;show "-----------------"

          let first-day-time-slots append-words first-day-chosen first-day-time-periods
          let second-day-time-slots append-words second-day-chosen second-day-time-periods


          set first-day-time-slots first first-day-time-slots
          set second-day-time-slots first second-day-time-slots

          ;;show "----------------"
          ;;show first-day-time-slots
          ;;show second-day-time-slots


          set chosen-timeslots sentence first-day-time-slots second-day-time-slots

          ;;show chosen-timeslots

          ;;show "---------------"

        ]

        if chosen-num-days = 4 [

          let days-chosen []

          set days-chosen first insert-item 0 days-chosen n-of 4 days-of-the-week

          ;;show days-chosen

          let first-day-time-period []
          set first-day-time-period insert-item 0 first-day-time-period one-of time-periods
          let second-day-time-period []
          set second-day-time-period insert-item 0 second-day-time-period one-of time-periods
          let third-day-time-period []
          set third-day-time-period insert-item 0 third-day-time-period one-of time-periods
          let fourth-day-time-period []
          set fourth-day-time-period insert-item 0 fourth-day-time-period one-of time-periods


          ;;let first-day-time-period one-of time-periods
          ;;let second-day-time-period one-of time-periods
          ;;let third-day-time-period one-of time-periods
          ;;let fourth-day-time-period one-of time-periods

          ;; show "-----------------"
          ;;show first-day-time-period
          ;;show second-day-time-period
          ;;show third-day-time-period
          ;;show fourth-day-time-period
          ;;show "-----------------"

          let first-day-chosen []
          let second-day-chosen []
          let third-day-chosen []
          let fourth-day-chosen []

          set first-day-chosen insert-item 0 first-day-chosen first days-chosen
          set second-day-chosen insert-item 0 second-day-chosen item 1 days-chosen
          set third-day-chosen insert-item 0 third-day-chosen item 2 days-chosen
          set fourth-day-chosen insert-item 0 fourth-day-chosen item 3 days-chosen

          ;;show "-----------------"
          ;;show first-day-chosen
          ;;show second-day-chosen
          ;;show third-day-chosen
          ;;show fourth-day-chosen
          ;;show "-----------------"

          let first-day-time-slots append-words first-day-chosen first-day-time-period
          let second-day-time-slots append-words second-day-chosen second-day-time-period
          let third-day-time-slots append-words third-day-chosen third-day-time-period
          let fourth-day-time-slots append-words fourth-day-chosen fourth-day-time-period

          set first-day-time-slots first first-day-time-slots
          set second-day-time-slots first second-day-time-slots
          set third-day-time-slots first third-day-time-slots
          set fourth-day-time-slots first fourth-day-time-slots

          ;;show "----------------"
          ;;show first-day-time-slots
          ;;show second-day-time-slots
          ;;show third-day-time-slots
          ;;show fourth-day-time-slots

          let time-slots-1 sentence first-day-time-slots second-day-time-slots
          let time-slots-2 sentence third-day-time-slots fourth-day-time-slots
          set chosen-timeslots sentence time-slots-1 time-slots-2

          ;;show chosen-timeslots

          ;;show "---------------"
        ]




      ]

    ]

  ]

  ;;show " 1 switch "
  ;;show switcheronis1
  ;;show " 2 switch "
  ;;show switcheronis2
end

to update-strategies-112slots

  set num-agents-one-roll 0
  set num-agents-two-roll 0

  ask turtles[

    if (length overcrowded-timeslots <= 0) and (setup-flag = false)[
      let temp-all-slots periods-of-the-day

      foreach chosen-timeslots[
        x -> set x x
        set temp-all-slots remove x temp-all-slots
      ]

      let new-slots n-of (length overcrowded-timeslots) temp-all-slots

      ;;show "old-timeslots"
      ;;show chosen-timeslots

      ;;show "overcrowded-timeslots"
      ;;show overcrowded-timeslots


      foreach overcrowded-timeslots[
        x -> set x x
        set chosen-timeslots remove x chosen-timeslots
      ]

      foreach new-slots[
        x -> set x x
        set chosen-timeslots insert-item 0 chosen-timeslots x
      ]

      ;;show "new slots"
      ;;show chosen-timeslots


    ]

    if (length overcrowded-timeslots > 0) or (setup-flag = true) [

      let days-roll random-float 1
      let timeslots-roll random-float 1


      ;; choose new number of days and new slots
      if ( timeslots-roll >= epsilon-greedy )[

        set num-agents-one-roll num-agents-one-roll + 1
        if ( days-roll >= epsilon-greedy ) [

          set chosen-num-days one-of num-days
          set num-agents-two-roll num-agents-two-roll + 1

        ]

        if chosen-num-days = 1 [

          let day-chosen []
          set day-chosen insert-item 0 day-chosen one-of days-of-the-week

          let time-periods-chosen []
          let first-time-period one-of (range 8 21)

          ;; do  this properly in a list, no hardcoded shit
          let second-time-period first-time-period + 1
          let third-time-period second-time-period + 1
          let fourth-time-period third-time-period + 1

          set time-periods-chosen insert-item 0 time-periods-chosen fourth-time-period
          set time-periods-chosen insert-item 0 time-periods-chosen third-time-period
          set time-periods-chosen insert-item 0 time-periods-chosen second-time-period
          set time-periods-chosen insert-item 0 time-periods-chosen first-time-period

          set chosen-timeslots append-words day-chosen time-periods-chosen

          ;;show chosen-timeslots
        ]

        if chosen-num-days = 2 [

          let days-chosen []
          set days-chosen first insert-item 0 days-chosen n-of 2 days-of-the-week

          let first-day-chosen []
          set first-day-chosen insert-item 0 first-day-chosen first days-chosen

          let second-day-chosen []
          set second-day-chosen insert-item 0 second-day-chosen item 1 days-chosen

          let first-time-period one-of (range 8 23)
          let second-time-period first-time-period + 1

          let first-day-time-periods-chosen []
          set first-day-time-periods-chosen insert-item 0 first-day-time-periods-chosen second-time-period
          set first-day-time-periods-chosen insert-item 0 first-day-time-periods-chosen first-time-period

          let third-time-period one-of (range 8 23)
          let fourth-time-period third-time-period + 1

          let second-day-time-periods-chosen []
          set second-day-time-periods-chosen insert-item 0 second-day-time-periods-chosen fourth-time-period
          set second-day-time-periods-chosen insert-item 0 second-day-time-periods-chosen third-time-period

          let first-day-time-slots append-words first-day-chosen first-day-time-periods-chosen
          let second-day-time-slots append-words second-day-chosen second-day-time-periods-chosen

          set first-day-time-slots first first-day-time-slots
          set second-day-time-slots first second-day-time-slots

          set chosen-timeslots sentence first-day-time-slots second-day-time-slots

          ;;show chosen-timeslots


        ]

        if chosen-num-days = 4 [

          let days-chosen []

          set days-chosen first insert-item 0 days-chosen n-of 4 days-of-the-week

          let first-day-chosen []
          set first-day-chosen insert-item 0 first-day-chosen first days-chosen

          let second-day-chosen []
          set second-day-chosen insert-item 0 second-day-chosen item 1 days-chosen

          let third-day-chosen []
          set third-day-chosen insert-item 0 third-day-chosen item 2 days-chosen

          let fourth-day-chosen []
          set fourth-day-chosen insert-item 0 fourth-day-chosen item 3 days-chosen

          let first-time-period one-of (range 8 24)
          let second-time-period one-of (range 8 24)
          let third-time-period one-of (range 8 24)
          let fourth-time-period one-of (range 8 24)

          let first-day-time-periods-chosen []
          set first-day-time-periods-chosen insert-item 0 first-day-time-periods-chosen first-time-period

          let second-day-time-periods-chosen []
          set second-day-time-periods-chosen insert-item 0 second-day-time-periods-chosen second-time-period

          let third-day-time-periods-chosen []
          set third-day-time-periods-chosen insert-item 0 third-day-time-periods-chosen third-time-period

          let fourth-day-time-periods-chosen []
          set fourth-day-time-periods-chosen insert-item 0 fourth-day-time-periods-chosen fourth-time-period

          let first-day-time-slots append-words first-day-chosen first-day-time-periods-chosen
          let second-day-time-slots append-words second-day-chosen second-day-time-periods-chosen
          let third-day-time-slots append-words third-day-chosen third-day-time-periods-chosen
          let fourth-day-time-slots append-words fourth-day-chosen fourth-day-time-periods-chosen

          set first-day-time-slots first first-day-time-slots
          set second-day-time-slots first second-day-time-slots
          set third-day-time-slots first third-day-time-slots
          set fourth-day-time-slots first fourth-day-time-slots

          let time-slots-1 sentence first-day-time-slots second-day-time-slots
          let time-slots-2 sentence third-day-time-slots fourth-day-time-slots
          set chosen-timeslots sentence time-slots-1 time-slots-2

          ;;show chosen-timeslots
        ]
      ]
    ]
  ]


end

to-report append-word [w xs]
  report map [[x] -> (word w " " x)] xs
end

to-report append-words [ws xs]
  report map [[w] -> append-word w xs] ws
end


;; In this model it doesn't really matter exactly which patch
;; a turtle is on, only whether the turtle is in the home area
;; or the bar area.  Nonetheless, to make a nice visualization
;; this procedure is used to ensure that we only have one
;; turtle per patch.
to move-to-empty-one-of [locations]  ;; turtle procedure
  move-to one-of locations
  while [any? other turtles-here] [
    move-to one-of locations
  ]
end