extensions [table]

globals [


  attendance                                ;; current attendance at the shop

  ;; time slot related globals
  num-trips                                  ;; list of different number of days agents can complete their quota in
  days-of-the-week                          ;; list of days of the week
  time-periods                              ;; list of time periods
  periods-of-the-day                        ;; list of time periods of the day
  current-time-period                       ;; current time period
  current-time-period-index
  num-overcrowded-timeslots                 ;; number of overcrowded timeslots
  num-overcrowded-timeslots-temp

  ;; patch-related globals
  home-patches                              ;; agentset of green patches representing the residential area
  shop-patches                               ;; agentset of blue patches representing the bar area
  crowded-patch                             ;; patch where we show the "CROWDED" label
  crowded?

  ;; agent-related globals
  all-scores                                ;; list of all the weekly scores of each agent
  min-all-scores                            ;; minimum of all agent scores
  max-all-scores                            ;; maximum of all agent scores
  mean-score                                ;; average score
  unique-scores                             ;; Count of the number of unique scores

  all-epsilons                              ;; list of all epsilon values
  min-epsilon                               ;; minimum of all agents' epsilon values
  max-epsilon                               ;; maximum of all agents' epsilon values
  mean-epsilon                              ;; average of all agents' epsilon values
  unique-epsilons                           ;; Count of the number of unique epsilon values
  sum-epsilon                               ;; sum of all agents' epsilon values

  ;; derived globals
  exploitation-count                        ;; count of all agents that are exploiting
  mean-attendance

  num-agents-one-roll                       ;; number of agents that roll once
  num-agents-two-roll                       ;; number of agents that roll twice

  count-swapped-one-roll                    ;; total number of agents that roll once
  count-swapped-two-roll                    ;; total number of agents that roll twice

  overcrowded-agent                         ;; number of agents with at least one overcrowded timeslot


  ;; flags
  setup-flag                                ;; setup flag that is used to check if the setup is complete



]

turtles-own [

  chosen-num-trips                          ;; chosen num-trips for the week
  chosen-timeslots                          ;; chosen timeslots for the week
  shopping-quota                            ;; shopping quota for the week, in number of slots
  epsilon-greedy                            ;; epsilon parameter
  weekly-score                              ;; agent's score for the week
  at-shop?                                  ;; boolean indicating whether or not agent is at shop
  overcrowded-timeslots                     ;; list of timeslots during which the store was overcrowded
  home-patch                                ;; designated home patch for each agent
  changed-timeslots-one-roll                ;; boolean that is set to true if an agent has ever switched timeslots
  changed-timeslots-two-roll                ;; boolean that is set to true if an agent has even swtiched both timeslots and total trips

]

to setup
  clear-all

  ;; initializing variables
  set setup-flag true


  set mean-score 0
  set min-all-scores 0
  set max-all-scores 0
  set unique-scores 0
  set count-swapped-one-roll 0
  set count-swapped-two-roll 0

  set mean-attendance 0

  set all-epsilons []

  set num-trips [1 2 4]
  set days-of-the-week ["Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"]
  ;;set time-periods ["Morning" "Afternoon" "Evening" "Night"]
  set time-periods (range 8 24)
  set periods-of-the-day []
  set current-time-period-index 0

  set overcrowded-agent 0

  set num-overcrowded-timeslots 0
  set num-overcrowded-timeslots-temp 0

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
  set shop-patches patches with [pxcor > 0 and pycor > 0]
  ask shop-patches [ set pcolor blue ]


  ;; use one of the patch labels to visually indicate whether or not the
  ;; bar is "crowded"
  ask patch (0.75 * max-pxcor) (0.5 * max-pycor) [
    set crowded-patch self
    set plabel-color red
    ;;set pcolor red
  ]

  ;; create the table to store agents scores
  ;;set agent-scores table:make

  ;; create the agents and give them random strategies
  create-turtles num-agents [
    set color white
    set at-shop? false

    set weekly-score 0


    set home-patch one-of patches with [pycor < 0 or (pxcor <  0 and pycor >= 0)]
    move-to home-patch


    ;;move-to-empty-one-of home-patches

    set shopping-quota 4
    set epsilon-greedy 0

    ;;table:put agent-scores who 0

    set chosen-num-trips one-of num-trips

    set overcrowded-timeslots []



  ]


  update-strategies-112slots
  ;;update-strategies-28slots

  set num-agents-one-roll 0
  set num-agents-two-roll 0

  set setup-flag false

  ask turtles [
    set changed-timeslots-one-roll false
    set changed-timeslots-two-roll false
  ]
  reset-ticks

end



to go

  ;; if the previous week has elapsed
  if ( current-time-period-index > 111 ) [

    ;; reset the time period index back to 0
    set current-time-period-index 0

    set num-overcrowded-timeslots num-overcrowded-timeslots-temp
    set num-overcrowded-timeslots-temp 0

    set overcrowded-agent 0

    ask turtles [

      if length overcrowded-timeslots > 0 [
        set overcrowded-agent overcrowded-agent + 1
      ]

    ]

    ;; re-initialize the list of all scores
    set all-scores []
    set all-epsilons []

    ask turtles [

      set all-scores insert-item 0 all-scores weekly-score

    ]


    ;; calculate the average, minimum and maximum score
    set mean-score mean all-scores
    set min-all-scores min all-scores
    set max-all-scores max all-scores
    set unique-scores length ( remove-duplicates all-scores )

    ;; set each agent's epsilon value
    ask turtles [
      ;;set weekly-score weekly-score - ( 3 * length overcrowded-timeslots )

      if adaptive? [

        if epsilon-function = "base" [
          set epsilon-greedy ( ( weekly-score - min-score ) / ( ideal-score - min-score ) )
          ;;set epsilon-greedy ( ( weekly-score - min-all-scores ) / ( max-all-scores - min-all-scores ) )
        ]

        if epsilon-function = "fractional exponent" [
          set epsilon-greedy ( ( weekly-score - min-score ) ^ c / ( ideal-score - min-score ) ^ c )
          ;;set epsilon-greedy ( ( weekly-score - min-all-scores ) ^ c / ( max-all-scores - min-all-scores ) ^ c)
        ]

        if epsilon-function = "exponent" [
          set epsilon-greedy ( ( weekly-score - min-score ) ^ c / ( ideal-score - min-score ) ^ c )
          ;;set epsilon-greedy ( ( weekly-score - min-all-scores ) ^ c / ( max-all-scores - min-all-scores ) ^ c )
        ]

        if epsilon-function = "log" [
          ifelse ( weekly-score - min-score ) <= 3 [
          ;;ifelse ( weekly-score - min-all-scores ) <= 1 [
            set epsilon-greedy 0
          ]
          [
            set epsilon-greedy ( ( log ( c * ( weekly-score - min-score ) ) 10 ) / ( log ( c * ( ideal-score - min-score ) ) 10 ) )
            ;;set epsilon-greedy ( ( log ( c * ( weekly-score - min-all-scores ) ) 10 ) / ( log ( c * ( max-all-scores - min-all-scores ) ) 10 ) )
          ]
        ]

        if epsilon-function = "sigmoid" [
          ;;set epsilon-greedy ( 1 / ( 1 + ( e ^ ( - c * ( weekly-score - ( ( ideal-score - min-score ) / 2 ) ) ) ) ) )
          set epsilon-greedy ( 1 / ( 1 + ( e ^ ( - c * ( weekly-score - ( ( max-all-scores - min-all-scores ) / 2 ) ) ) ) ) )
          ;;show "sigmoid"
        ]

        if epsilon-greedy > 1[
          set epsilon-greedy 1
        ]
        set all-epsilons insert-item 0 all-epsilons epsilon-greedy
        set weekly-score 0
      ]
      if adaptive? = false [
        set all-epsilons n-values 400 [0]
      ]
    ]

    set mean-epsilon mean all-epsilons
    set min-epsilon min all-epsilons
    set max-epsilon max all-epsilons
    set unique-epsilons length ( remove-duplicates all-epsilons)
    ;;show all-epsilons

    ask turtles [
      set color scale-color red (max-epsilon - epsilon-greedy) (min-epsilon - 1.9) max-epsilon
    ]

    ;; count the number of agents that are exploiting
    set exploitation-count 0
    ask turtles [
      ;;set epsilon-values insert-item 0 epsilon-values epsilon-greedy

      if epsilon-greedy >= 1 [
        set exploitation-count exploitation-count + 1
      ]
    ]

    ;; calculate the sum of all the epsilon values
    set sum-epsilon sum all-epsilons


    update-strategies-112slots
    ;;update-strategies-28slots

    set count-swapped-one-roll count turtles with [changed-timeslots-one-roll = true]
    set count-swapped-two-roll count turtles with [changed-timeslots-two-roll = true]
  ]

  ;; if we are running for the first time / beginning of the week
  if ( current-time-period-index = 0 ) [

    ;; create a list of 0s for the attendance counts for each timeslot
    let attendance-counts n-values 112 [0]

    ask turtles [

      ;; loop over all the periods of the day and add the attendance counts
      foreach periods-of-the-day [
        x -> set x x

        if member? x chosen-timeslots [

          let position-of-timeslot position x periods-of-the-day

          let new-item item position-of-timeslot attendance-counts + 1

          set attendance-counts replace-item position-of-timeslot attendance-counts new-item

        ]
      ]
      set overcrowded-timeslots []
    ]


    set mean-attendance mean attendance-counts

  ]

  ;; during the week
  if ( current-time-period-index <= 111 ) [

    set attendance 0

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
          move-to-empty-one-of shop-patches
          set attendance attendance + 1
          set at-shop? true
      ]

      ;; otherwise stay at home
      [
        ;;move-to-empty-one-of home-patches
        move-to home-patch

      ]

    ]


    set crowded? false

    ;; if the bar is crowded indicate that in the view
    set attendance count turtles-on shop-patches

    if attendance > overcrowding-threshold [

      set num-overcrowded-timeslots-temp num-overcrowded-timeslots-temp + 1
      ask crowded-patch [
        set plabel "CROWDED"
        set crowded? true
      ]
    ]

    ;; ask the agents if they're at the shop
    ask turtles[
      ;; let agent-chosen-flag false

      if at-shop? [
        ;; if its crowded, add this slot to their individual list of overcrowded timeslots
        ifelse crowded? [
          set overcrowded-timeslots insert-item 0 overcrowded-timeslots current-time-period
        ]

        ;; Update the weekly score as a function of the current attendance
        [
          let reward ( 1 / attendance ) * 100
          ;;let reward 1 +  ( ( ( attendance - overcrowding-threshold ) * ( 10 - 1 ) ) / ( min-reward - overcrowding-threshold ) )
          set weekly-score weekly-score + reward ;;+ random 5 ;; - ( ( length overcrowded-timeslots ) * 1 )
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

          set chosen-num-trips one-of num-trips
          set num-agents-two-roll num-agents-two-roll + 1

        ]


        if chosen-num-trips = 1[

          let day-chosen []
          set day-chosen insert-item 0 day-chosen one-of days-of-the-week

          ;;show day-chosen

          set chosen-timeslots append-words day-chosen time-periods


          set chosen-timeslots first chosen-timeslots

          ;;show chosen-timeslots

        ]

        if chosen-num-trips = 2[

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

        if chosen-num-trips = 4 [

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

    ;;if (length overcrowded-timeslots <= 0) and (setup-flag = false)[

      ;;let temp-all-slots periods-of-the-day

      ;;foreach chosen-timeslots[
        ;;x -> set x x
        ;;set temp-all-slots remove x temp-all-slots
      ;;]

      ;;let new-slots n-of (length overcrowded-timeslots) temp-all-slots

      ;;show "old-timeslots"
      ;;show chosen-timeslots

      ;;show "overcrowded-timeslots"
      ;;show overcrowded-timeslots


      ;;foreach overcrowded-timeslots[
        ;;x -> set x x
        ;;set chosen-timeslots remove x chosen-timeslots
      ;;]

      ;;foreach new-slots[
        ;;x -> set x x
        ;;set chosen-timeslots insert-item 0 chosen-timeslots x
      ;;]

      ;;show "new slots"
      ;;show chosen-timeslots


    ;;]

    if (length overcrowded-timeslots > 0) or (setup-flag = true) [

      let days-roll random-float 1
      let timeslots-roll random-float 1


      ;; choose new number of days and new slots
      if ( timeslots-roll >= epsilon-greedy )[

        set num-agents-one-roll num-agents-one-roll + 1

        set changed-timeslots-one-roll true
        ;; if the agent chooses a new number of days
        if ( days-roll >= epsilon-greedy ) [

          set changed-timeslots-two-roll true
          set chosen-num-trips one-of num-trips
          set num-agents-two-roll num-agents-two-roll + 1

        ]

        if chosen-num-trips = 1 [

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
          set chosen-timeslots first chosen-timeslots
          ;;show chosen-timeslots
        ]

        if chosen-num-trips = 2 [

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

        if chosen-num-trips = 4 [

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
@#$#@#$#@
GRAPHICS-WINDOW
210
15
799
605
-1
-1
17.61
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
25
20
88
53
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
24
64
87
97
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
20
475
195
520
NIL
current-time-period
17
1
11

BUTTON
98
20
161
53
go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
110
195
143
overcrowding-threshold
overcrowding-threshold
0
100
17.0
1
1
NIL
HORIZONTAL

PLOT
815
490
1490
795
Shop Attendance
Time
Attendance
0.0
10.0
0.0
50.0
true
false
"" ""
PENS
"attendance" 1.0 0 -16777216 true "" "plot attendance"
"threshold" 1.0 0 -2674135 true "" ";; plot a threshold line -- an attendance level above this line makes the bar\n;; is unappealing, but below this line is appealing\nplot-pen-reset\nplotxy 0 overcrowding-threshold\nplotxy plot-x-max overcrowding-threshold"

PLOT
815
250
1155
470
mean-score
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean-score"

MONITOR
1620
305
1700
350
NIL
min-all-scores
2
1
11

MONITOR
1620
360
1700
405
NIL
max-all-scores
2
1
11

PLOT
210
645
800
915
number-of-agents-swtiching
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"switched slots" 1.0 0 -13791810 true "" "plot num-agents-one-roll"
"switched slots and trip configurations" 1.0 0 -955883 true "" "plot num-agents-two-roll"

MONITOR
1620
250
1700
295
mean-score
mean-score
2
1
11

MONITOR
1503
490
1600
535
NIL
mean-attendance
2
1
11

SLIDER
24
155
194
188
num-agents
num-agents
0
1000
400.0
10
1
NIL
HORIZONTAL

INPUTBOX
98
330
193
390
min-score
0.0
1
0
Number

INPUTBOX
98
400
193
460
ideal-score
23.0
1
0
Number

SWITCH
97
64
192
97
adaptive?
adaptive?
0
1
-1000

MONITOR
1620
15
1702
60
NIL
mean-epsilon
4
1
11

PLOT
815
15
1155
235
mean-epsilon
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean-epsilon\n"

CHOOSER
24
200
194
245
epsilon-function
epsilon-function
"base" "fractional exponent" "exponent" "log" "sigmoid"
3

MONITOR
1620
70
1700
115
NIL
min-epsilon
4
1
11

MONITOR
1620
125
1690
170
NIL
max-epsilon
4
1
11

MONITOR
1710
15
1815
60
exploitation-ratio
( num-agents - num-agents-one-roll ) / num-agents
17
1
11

MONITOR
1710
70
1815
115
exploration-ratio
num-agents-one-roll / num-agents
17
1
11

PLOT
1170
250
1610
470
Weekly Score Distribution
NIL
NIL
0.0
60.0
0.0
10.0
true
false
"" ""
PENS
"default" 2.0 1 -16777216 true "" " if ( current-time-period-index > 111 ) [ histogram [ weekly-score ] of turtles ] "

PLOT
1170
15
1610
235
Epsilon-Greedy Distribution
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" " if ( current-time-period-index = 1 ) [ histogram [ epsilon-greedy ] of turtles ] "

MONITOR
21
535
196
580
NIL
current-time-period-index
17
1
11

MONITOR
1620
415
1752
460
Unique Weekly Scores
unique-scores
17
1
11

MONITOR
1620
180
1797
225
Unique Epsilon-Greedy values
unique-epsilons
17
1
11

INPUTBOX
97
260
192
320
c
0.25
1
0
Number

PLOT
1620
490
1975
680
Overcrowded Agents over time
Time
num-agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot overcrowded-agent"

MONITOR
1990
490
2112
535
NIL
overcrowded-agent
17
1
11

MONITOR
1505
550
1582
595
NIL
attendance
17
1
11

MONITOR
815
815
957
860
NIL
count-swapped-one-roll
1
1
11

MONITOR
815
870
957
915
NIL
count-swapped-two-roll
17
1
11

MONITOR
1990
700
2140
745
NIL
num-overcrowded-timeslots
17
1
11

PLOT
1620
700
1975
890
Overcrowded time slots over time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-overcrowded-timeslots"

MONITOR
1920
125
2032
170
NIL
exploitation-count
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>count turtles</metric>
    <metric>attendance</metric>
    <metric>exploitation-count</metric>
    <metric>exploitation-count / num-agents</metric>
    <metric>num-agents-one-roll</metric>
    <metric>num-agents-two-roll</metric>
    <metric>overcrowded-agent</metric>
    <metric>all-scores</metric>
    <metric>mean-score</metric>
    <metric>min-all-scores</metric>
    <metric>max-all-scores</metric>
    <metric>unique-scores</metric>
    <metric>all-epsilons</metric>
    <metric>avg-epsilon</metric>
    <metric>min-epsilon</metric>
    <metric>max-epsilon</metric>
    <metric>num-agents-one-roll / num-agents</metric>
    <metric>unique-epsilons</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-score">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-score">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overcrowding-threshold">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="epsilon-function">
      <value value="&quot;exponent&quot;"/>
      <value value="&quot;log&quot;"/>
      <value value="&quot;sigmoid&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="factor">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="factor">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="epsilon-function">
      <value value="&quot;sigmoid&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-score">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-score">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overcrowding-threshold">
      <value value="17"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="factor">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="epsilon-function">
      <value value="&quot;sigmoid&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-score">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-score">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overcrowding-threshold">
      <value value="17"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final_experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>attendance</metric>
    <metric>exploitation-count</metric>
    <metric>mean-score</metric>
    <metric>min-all-scores</metric>
    <metric>max-all-scores</metric>
    <metric>unique-scores</metric>
    <metric>mean-epsilon</metric>
    <metric>min-epsilon</metric>
    <metric>max-epsilon</metric>
    <metric>unique-epsilons</metric>
    <metric>num-overcrowded-timeslots</metric>
    <metric>overcrowded-agent</metric>
    <metric>num-agents-one-roll</metric>
    <metric>num-agents-two-roll</metric>
    <metric>count-swapped-one-roll</metric>
    <metric>count-swapped-two-roll</metric>
    <enumeratedValueSet variable="epsilon-function">
      <value value="&quot;log&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="factor">
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="distrib_experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>all-epsilons</metric>
    <enumeratedValueSet variable="epsilon-function">
      <value value="&quot;sigmoid&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="factor">
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
