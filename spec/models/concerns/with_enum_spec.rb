require 'spec_helper'

module SomeOtherEnum
  ENUM = {type_a: 'foo', type_b: 'bar'}
end

module SomeOtherEnum::TypeA
  def self.some_another_method
    'a type behaviour'
  end
end

module SomeOtherEnum::TypeB
  def self.some_method
    'b'
  end
end

module SomeEnum
  ENUM = [:type_a, :type_b]

  def some_method

  end

  def some_another_method
    'generic behaviour'
  end
end

module SomeEnum::TypeA
  def self.some_another_method
    'a type behaviour'
  end
end

module SomeEnum::TypeB
  def self.some_method
    'b'
  end
end

class SomeClass < ApplicationRecord
  serialize_enum :field_1, class: SomeEnum
  serialize_enum :field_2, class: SomeOtherEnum
end

describe WithEnum do
  before :all do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.create_table :some_classes do |t|
      t.integer :field_1, default: 0
      t.string :field_2, default: 'foo'
    end
  end

  after :all do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.drop_table :some_classes
  end

  let(:some_class) { SomeClass.new }

  describe 'simple test' do
    it { expect(some_class.field_1).to eq SomeEnum::TypeA }
  end

  describe 'field_2' do
    describe 'with default value' do
      it { expect(some_class.field_2).to eq SomeOtherEnum::TypeA }
    end

    describe 'with default value' do
      before { some_class.field_2 = :type_b }

      it { expect(some_class.field_2).to eq SomeOtherEnum::TypeB }
    end
  end
end
