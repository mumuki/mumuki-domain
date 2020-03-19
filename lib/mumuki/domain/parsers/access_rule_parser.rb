#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.4.16
# from Racc grammar file "".
#

require 'racc/parser.rb'

#
module Mumuki
  module Domain
    module Parsers
      class AccessRuleParser < Racc::Parser

module_eval(<<'...end access_rule_parser.y/module_eval...', 'access_rule_parser.y', 21)

  def parse(string)
    @q = tokenize(string)
    @q.push [false, '$end']
    do_parse
  end

  def tokenize(string)
    string
      .scan(/"([^"]*)"|(\w+)/)
      .map do |str, token|
        str ? [:STRING, str] : [token, token]
      end
  end

  def next_token
    @q.shift
  end
...end access_rule_parser.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
    15,    16,    17,    18,    19,    20,    21,    22,    23,    10,
    11,     5,    12,    13,     3,     4,     7,     8,    24,    25,
    26 ]

racc_action_check = [
    10,    10,    10,    10,    10,    10,    10,    10,    10,     6,
     6,     1,     6,     6,     0,     0,     2,     5,    11,    12,
    13 ]

racc_action_pointer = [
    12,    11,    12,   nil,   nil,    17,     4,   nil,   nil,   nil,
   -10,    11,    15,    16,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil ]

racc_action_default = [
   -19,   -19,   -19,    -2,    -3,   -19,    -5,    -4,    27,    -1,
   -19,   -19,   -19,   -19,    -6,   -10,   -11,   -12,   -13,   -14,
   -15,   -16,   -17,   -18,    -7,    -8,    -9 ]

racc_goto_table = [
     1,     2,     6,     9,    14 ]

racc_goto_check = [
     1,     2,     3,     4,     5 ]

racc_goto_pointer = [
   nil,     0,     1,     0,    -3,    -6 ]

racc_goto_default = [
   nil,   nil,   nil,   nil,   nil,   nil ]

racc_reduce_table = [
  0, 0, :racc_error,
  3, 20, :_reduce_1,
  1, 21, :_reduce_2,
  1, 21, :_reduce_3,
  1, 22, :_reduce_none,
  0, 23, :_reduce_5,
  2, 23, :_reduce_6,
  2, 23, :_reduce_7,
  2, 23, :_reduce_8,
  2, 23, :_reduce_9,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none,
  1, 24, :_reduce_none ]

racc_reduce_n = 19

racc_shift_n = 27

racc_token_table = {
  false => 0,
  :error => 1,
  "hide" => 2,
  "disable" => 3,
  :STRING => 4,
  "unless" => 5,
  "while" => 6,
  "unready" => 7,
  "until" => 8,
  "at" => 9,
  "student" => 10,
  "teacher" => 11,
  "headmaster" => 12,
  "writer" => 13,
  "editor" => 14,
  "janitor" => 15,
  "moderator" => 16,
  "admin" => 17,
  "owner" => 18 }

racc_nt_base = 19

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "\"hide\"",
  "\"disable\"",
  "STRING",
  "\"unless\"",
  "\"while\"",
  "\"unready\"",
  "\"until\"",
  "\"at\"",
  "\"student\"",
  "\"teacher\"",
  "\"headmaster\"",
  "\"writer\"",
  "\"editor\"",
  "\"janitor\"",
  "\"moderator\"",
  "\"admin\"",
  "\"owner\"",
  "$start",
  "target",
  "action",
  "content",
  "condition",
  "role" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'access_rule_parser.y', 2)
  def _reduce_1(val, _values, result)
     result = {action: val[0], content: val[1].to_mumukit_grant, condition: val[2]}
    result
  end
.,.,

module_eval(<<'.,.,', 'access_rule_parser.y', 4)
  def _reduce_2(val, _values, result)
     result = :hide
    result
  end
.,.,

module_eval(<<'.,.,', 'access_rule_parser.y', 5)
  def _reduce_3(val, _values, result)
     result = :disable
    result
  end
.,.,

# reduce 4 omitted

module_eval(<<'.,.,', 'access_rule_parser.y', 9)
  def _reduce_5(val, _values, result)
     result = {kind: :always}
    result
  end
.,.,

module_eval(<<'.,.,', 'access_rule_parser.y', 10)
  def _reduce_6(val, _values, result)
     result = {kind: :unless_role, role: val[1].to_sym}
    result
  end
.,.,

module_eval(<<'.,.,', 'access_rule_parser.y', 11)
  def _reduce_7(val, _values, result)
     result = {kind: :while_unready}
    result
  end
.,.,

module_eval(<<'.,.,', 'access_rule_parser.y', 12)
  def _reduce_8(val, _values, result)
     result = {kind: :until_date, date: DateTime.parse(val[1])}
    result
  end
.,.,

module_eval(<<'.,.,', 'access_rule_parser.y', 13)
  def _reduce_9(val, _values, result)
     result = {kind: :at_date, date: DateTime.parse(val[1])}
    result
  end
.,.,

# reduce 10 omitted

# reduce 11 omitted

# reduce 12 omitted

# reduce 13 omitted

# reduce 14 omitted

# reduce 15 omitted

# reduce 16 omitted

# reduce 17 omitted

# reduce 18 omitted

def _reduce_none(val, _values, result)
  val[0]
end

      end   # class AccessRuleParser
    end   # module Parsers
  end   # module Domain
end   # module Mumuki
