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


  sum-epsilon

  continue-explore?
  
  min-reward
]

turtles-own [

  chosen-num-days                           ;; chosen num-days for the week
  chosen-timeslots                          ;; chosen timeslots for the week
  shopping-quota                            ;; shopping quota for the week, in number of slots
  epsilon-greedy                            ;; epsilon parameter
  weekly-score                              ;; agent's score for the week
  at-shop?                                  ;; boolean indicating whether or not agent is at shop

]

to setup
  clear-all
  
  
  
  
 
  set min-reward 1
  
  set continue-explore? true

  set num-days [1 2 4]
  set days-of-the-week ["Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"]
  set time-periods ["Morning" "Afternoon" "Evening" "Night"]
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
  ;;show periods-of-the-day


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
  create-turtles 100 [
    set color white
    set at-shop? false

    set weekly-score 0

    move-to-empty-one-of home-patches

    set shopping-quota 4
    set epsilon-greedy 0

    table:put agent-scores who 0

    set chosen-num-days one-of num-days


  ]

  update-strategies

  ;; show agent-scores


  reset-ticks

end



to go

  
  if ( current-time-period-index > 27 ) [

    set current-time-period-index 0 

    set agent-scores table:make
    
    ask turtles [

      table:put agent-scores who weekly-score

      set all-scores insert-item 0 all-scores weekly-score

    ]

    let min-score min all-scores
    let max-score max all-scores

    ;;let min-score 0
    ;;let max-score 5

    ;;show "min"
    ;;show min all-scores
    ;;show "max"
    ;;show max all-scores
    ;;show "all scores"
    ;;show agent-scores

    set all-scores []

    ask turtles [
      set epsilon-greedy ( ( weekly-score - min-score ) / ( max-score - min-score ) )
      ;;show "weekly score"
      ;;show weekly-score
      ;;show "epsilon-greedy"
      ;;show epsilon-greedy

      set weekly-score 0
    ]

    let epsilon-values []
    ask turtles [
      set epsilon-values insert-item 0 epsilon-values epsilon-greedy

    ]

    set sum-epsilon sum epsilon-values
    show sum-epsilon

    if sum-epsilon >= 100 [
      set continue-explore? false
    ]

    ;;if continue-explore? = true [
    ;;  update-strategies
    ;;]

    update-strategies

  ]

  if ( current-time-period-index = 0 ) [

    let attendance-counts n-values 28 [0]
    foreach periods-of-the-day [
      x -> set x x
      
      ask turtles [
        if member? x chosen-timeslots [
          
          let position-of-timeslot position x periods-of-the-day

          let new-item item position-of-timeslot attendance-counts + 1

          set attendance-counts replace-item position-of-timeslot attendance-counts new-item

          
        ]
      ]
    ]

    ;;show periods-of-the-day
    ;;show attendance-counts
    
    ;;set min-reward min attendance-counts
    ;;show min-reward
  ]

  if ( current-time-period-index <= 27 ) [
    set current-time-period item current-time-period-index periods-of-the-day

    ;; update the global variables
    ask crowded-patch [ set plabel "" ]

    ask turtles[

      set at-shop? false
      ifelse member? current-time-period chosen-timeslots
      [   move-to-empty-one-of bar-patches
          set attendance attendance + 1
          set at-shop? true
      ]
        [ move-to-empty-one-of home-patches

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

    ask turtles[
      if at-shop? [
        ifelse crowded? [
          
        ]
        [
          let reward 1 +  ( ( ( attendance - overcrowding-threshold ) * ( 10 - 1 ) ) / ( min-reward - overcrowding-threshold ) )
          set weekly-score weekly-score + reward
        ]
      ]

    ]

    set current-time-period-index current-time-period-index + 1
  ]


  tick

end

to update-strategies


  ask turtles[

    let days-roll random-float 1
    let timeslots-roll random-float 1



    ;; choose new number of days and new slots
    if ( timeslots-roll > epsilon-greedy )[

      if ( days-roll > epsilon-greedy ) [

        set chosen-num-days one-of num-days

      ]

      ;;show "old timeslots"
      ;;show chosen-timeslots

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

     ;;show "new time-slots"
     ;;show chosen-timeslots


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