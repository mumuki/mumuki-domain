require_relative '../spec_helper'

describe Mumuki::Domain::Access::ConfigParser do
  let(:parser) { Mumuki::Domain::Access::ConfigParser.new }

  it { expect(parser.parse 'disable "*" while unready;').to eq [{action: :disable, class: AccessRule::WhileUnready, grant: '*'.to_mumukit_grant}] }
  it { expect(parser.tokenize 'disable "*" while unready;').to eq [['disable', 'disable'], [:STRING, '*'], ['while', 'while'], ['unready', 'unready'], [';', ';']] }

  it { expect(parser.parse 'disable "*";').to eq [{action: :disable, class: AccessRule::Always, grant: '*'.to_mumukit_grant}] }
  it { expect(parser.tokenize 'disable "*";').to eq [['disable', 'disable'], [:STRING, '*'], [';', ';']] }

  it { expect(parser.parse 'hide "*";').to eq [{action: :hide, class: AccessRule::Always, grant: '*'.to_mumukit_grant}] }
  it { expect(parser.tokenize 'hide "*";').to eq [['hide', 'hide'], [:STRING, '*'], [';', ';']] }

  it { expect(parser.parse 'hide "foo/bar" unless teacher;').to eq [{action: :hide, class: AccessRule::Unless, role: :teacher, grant: 'foo/bar'.to_mumukit_grant}] }
  it { expect(parser.tokenize 'hide "foo/bar" unless teacher;').to eq [['hide', 'hide'], [:STRING, 'foo/bar'], ['unless', 'unless'], ['teacher', 'teacher'], [';', ';']] }

  it { expect(parser.parse 'hide "foo/bar" until "2020-10-20 10:00:00 -0300";').to eq [{action: :hide, class: AccessRule::Until, date: DateTime.parse('2020-10-20 10:00:00 -0300'), grant: 'foo/bar'.to_mumukit_grant}] }
  it { expect(parser.tokenize 'hide "foo/bar" until "2020-10-20 10:00:00 -0300";').to eq [['hide', 'hide'], [:STRING, 'foo/bar'], ['until', 'until'], [:STRING, '2020-10-20 10:00:00 -0300'], [';', ';']] }


  it { expect(parser.parse 'hide "foo/bar" at "2020-10-20";').to eq [{action: :hide, class: AccessRule::At, date: DateTime.parse('2020-10-20'), grant: 'foo/bar'.to_mumukit_grant}] }
  it { expect(parser.tokenize 'hide "foo/bar" at "2020-10-20";').to eq [['hide', 'hide'], [:STRING, 'foo/bar'], ['at', 'at'], [:STRING, '2020-10-20'], [';', ';']] }

  it { expect(parser.parse %q{
                              disable "*" while unready;

                              hide "foo/bar" until "2020-10-10";

                              hide "foo/baz" unless teacher;
                            }).to eq [
                              {action: :disable, class: AccessRule::WhileUnready, grant: '*'.to_mumukit_grant},
                              {action: :hide, class: AccessRule::Until, date: DateTime.new(2020, 10, 10), grant: 'foo/bar'.to_mumukit_grant},
                              {action: :hide, class: AccessRule::Unless, role: :teacher, grant: 'foo/baz'.to_mumukit_grant}] }
end
