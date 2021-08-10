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
  all-epsilons
  exploitation-count

  mean-score
  min-all-scores
  max-all-scores

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


  set mean-score 0
  set min-all-scores 0
  set max-all-scores 0
  set all-epsilons []
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

    ;;show sort-by < all-scores


    ;;let min-score min all-scores
    ;;let max-score max all-scores
    set mean-score mean all-scores
    set min-all-scores min all-scores
    set max-all-scores max all-scores


    let min-score 0
    let max-score 4

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
      set all-epsilons insert-item 0 all-epsilons epsilon-greedy
      set weekly-score 0
    ]
    ;;show sort-by < all-epsilons
    set exploitation-count 0
    let epsilon-values []
    ask turtles [
      set epsilon-values insert-item 0 epsilon-values epsilon-greedy

      if epsilon-greedy >= 1 [
        set exploitation-count exploitation-count + 1
      ]
    ]
    ;;show exploitation-count

    set sum-epsilon sum epsilon-values
    ;;show sum-epsilon

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
          ;;let reward 1 / attendance
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

      ;;if ( days-roll > epsilon-greedy ) [

        ;;set chosen-num-days one-of num-days

      ;;]
      set chosen-num-days one-of num-days
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
@#$#@#$#@
GRAPHICS-WINDOW
320
15
734
430
-1
-1
12.303030303030303
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
42
72
105
105
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
41
121
104
154
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
38
237
158
282
NIL
current-time-period
17
1
11

BUTTON
120
72
183
105
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
39
179
220
212
overcrowding-threshold
overcrowding-threshold
0
100
15.0
1
1
NIL
HORIZONTAL

PLOT
766
15
1444
436
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
766
457
1064
678
sum-epsilon
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
"default" 1.0 0 -16777216 true "" "plot sum-epsilon"

PLOT
1082
457
1401
678
exploitation-count
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
"default" 1.0 0 -16777216 true "" "plot exploitation-count"

PLOT
321
457
747
679
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
220
458
308
503
NIL
min-all-scores
17
1
11

MONITOR
218
520
311
565
NIL
max-all-scores
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
0
@#$#@#$#@
