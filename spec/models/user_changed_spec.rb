require 'spec_helper'

describe User do
  let(:user) { User.find_by(uid: 'foo@bar.com') }
  let(:user_json) { {
    uid: 'foo@bar.com',
    first_name: 'Foo',
    last_name: 'Bar',
    permissions: {student: 'test/example'},
    id: 1
  } }

  context 'when new user' do
    before { User.import_from_resource_h! user_json }
    it { expect(user.uid).to eq 'foo@bar.com' }
    it { expect(user.name).to eq 'Foo Bar' }

    context  'when user is created with no verified name' do
      it { expect(user.verified_first_name).to be_nil }
      it { expect(user.verified_full_name).to be_blank }
      it { expect(user.has_verified_full_name?).to be false }
    end
  end

  context 'when user is created with verified names' do
    let(:verified_user_json) { user_json.merge(verified_first_name: 'Dan', verified_last_name: 'Doe') }
    before { User.import_from_resource_h! verified_user_json }
    it { expect(user.verified_first_name).to eq 'Dan' }
    it { expect(user.verified_last_name).to eq 'Doe' }
    it { expect(user.verified_full_name).to eq 'Dan Doe' }
    it { expect(user.has_verified_full_name?).to be true }

  end

  context 'when user exists' do
    let(:new_json) { {
      uid: 'foo@bar.com',
      first_name: 'Foo',
      last_name: 'Baz',
      permissions: {student: 'test/example2'},
      id: 1
    } }
    before { User.import_from_resource_h! user_json }
    before { User.import_from_resource_h! new_json }
    it { expect(user.name).to eq 'Foo Baz' }
    it { expect(user.student? 'test/example2').to be true }
    it { expect(user.student? 'test/example').to be false }
  end
end
