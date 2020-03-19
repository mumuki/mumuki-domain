class Mumuki::Domain::Parsers::AccessRuleParser
rule
  target: action grant condition { result = {action: val[0], grant: val[1].to_mumukit_grant}.merge(val[2]) }

  # class, grant, *rest

  action: 'hide'  { result = :hide }
        | 'disable' { result = :disable }

  grant: STRING

  condition:  /* nothing */ { result = {class: AccessRule::Always } }
              | 'unless' role { result = {class: AccessRule::Unless, role: val[1].to_sym} }
              | 'while' 'unready' { result = {class: AccessRule::WhileUnready} }
              | 'until' STRING { result = {class: AccessRule::Until, date: DateTime.parse(val[1])} }
              | 'at' STRING { result = {class: AccessRule::At, date: DateTime.parse(val[1])} }

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
