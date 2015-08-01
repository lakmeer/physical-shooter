
{ id, log } = require \std


#
# A simple test runner
#


# Styled logging

color-log = (col) -> (text, ...rest) ->
  log \%c + text, "color: #col", ...rest

red-log   = color-log '#e42'
green-log = color-log '#1d3'


# Styled results mapping

gems = pass: "🔵", fail: "🔴"
mark = pass: "✅", fail: "❌"

to-emoji = ({ pass, fail }) -> (result) ->
  if result.pass then pass else fail


# Show results

report = (name, { passed, total }, results) ->
  group-name = "#name - #passed/#total"

  if passed is total
    console.group-collapsed group-name
  else
    console.group group-name

  for result in results
    if result.pass
      if passed is total
        green-log result.text
    else
      red-log result.text, \expected result.e, \got result.a

  console.group-end group-name


# Comparitor Library

comparitors =
  equal:    (is)
  equal-v2: ([u,v]:a, [x,y]:b) -> u is x and v is y

build-comparitors = (totals, results) ->
  create = (comparitor) -> (text) ->
    totals.total += 1
    expect: (a) ->
      to-be: (b) ->
        if comparitor a, b
          totals.passed += 1
          results.push { pass: that, text, a, e: b }
        else
          totals.failed += 1
          results.push { pass: that, text, a, e: b }

  { [ name, create comparitor ] for name, comparitor of comparitors }


# Public interface

export test = (name, λ) ->
  results = []
  totals  = total: 0, passed: 0, failed: 0
  λ.apply build-comparitors totals, results
  report name, totals, results

