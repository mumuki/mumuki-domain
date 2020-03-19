class Mumuki::Domain::Parsers::AccessRuleParser
rule
  target: action content condition { result = {action: val[0], content: val[1].to_mumukit_grant, condition: val[2]} }

  action: 'hide'  { result = :hide }
        | 'disable' { result = :disable }

  content: STRING

  condition:  /* nothing */ { result = {kind: :always} }
              | 'unless' role { result = {kind: :unless_role, role: val[1].to_sym} }
              | 'while' 'unready' { result = {kind: :while_unready} }
              | 'until' STRING { result = {kind: :until_date, date: DateTime.parse(val[1])} }
              | 'at' STRING { result = {kind: :at_date, date: DateTime.parse(val[1])} }

  role: 'student' | 'teacher' | 'headmaster' | 'writer' | 'editor' | 'janitor' | 'moderator' | 'admin' | 'owner'

---- header
#
---- inner

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
