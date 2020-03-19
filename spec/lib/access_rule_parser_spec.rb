require_relative '../spec_helper'

describe Mumuki::Domain::Parsers::AccessRuleParser do
  let(:parser) { Mumuki::Domain::Parsers::AccessRuleParser.new }


  it { expect(parser.parse 'disable "*" while unready').to eq action: :disable, condition: {kind: :while_unready}, content: '*'.to_mumukit_grant }
  it { expect(parser.tokenize 'disable "*" while unready').to eq [['disable', 'disable'], [:STRING, '*'], ['while', 'while'], ['unready', 'unready']] }

  it { expect(parser.parse 'disable "*"').to eq action: :disable, condition: {kind: :always}, content: '*'.to_mumukit_grant }
  it { expect(parser.tokenize 'disable "*"').to eq [['disable', 'disable'], [:STRING, '*']] }

  it { expect(parser.parse 'hide "*"').to eq action: :hide, condition: {kind: :always}, content: '*'.to_mumukit_grant }
  it { expect(parser.tokenize 'hide "*"').to eq [['hide', 'hide'], [:STRING, '*']] }

  it { expect(parser.parse 'hide "foo/bar" unless teacher').to eq action: :hide, condition: {kind: :unless_role, role: :teacher}, content: 'foo/bar'.to_mumukit_grant }
  it { expect(parser.tokenize 'hide "foo/bar" unless teacher').to eq [['hide', 'hide'], [:STRING, 'foo/bar'], ['unless', 'unless'], ['teacher', 'teacher']] }

  it { expect(parser.parse 'hide "foo/bar" until "2020-10-20 10:00:00 -0300"').to eq action: :hide, condition: {kind: :until_date, date: DateTime.parse('2020-10-20 10:00:00 -0300')}, content: 'foo/bar'.to_mumukit_grant }
  it { expect(parser.tokenize 'hide "foo/bar" until "2020-10-20 10:00:00 -0300"').to eq [['hide', 'hide'], [:STRING, 'foo/bar'], ['until', 'until'], [:STRING, '2020-10-20 10:00:00 -0300']] }


  it { expect(parser.parse 'hide "foo/bar" at "2020-10-20"').to eq action: :hide, condition: {kind: :at_date, date: DateTime.parse('2020-10-20')}, content: 'foo/bar'.to_mumukit_grant }
  it { expect(parser.tokenize 'hide "foo/bar" at "2020-10-20"').to eq [['hide', 'hide'], [:STRING, 'foo/bar'], ['at', 'at'], [:STRING, '2020-10-20']] }

end
