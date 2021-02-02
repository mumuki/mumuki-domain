require 'spec_helper'

describe WithTargetAudience do
  let!(:kindergarten_organization) { create(:organization, target_audience: :kindergarten) }
  let!(:grown_ups_organization) { create(:organization, target_audience: :grown_ups, name: 'for_grown_ups') }

  let!(:kindergarten_avatars) { create_list(:avatar, 3, target_audience: :kindergarten) }
  let!(:grown_ups_avatars) { create_list(:avatar, 3, target_audience: :grown_ups) }

  let(:user) { create(:user) }

  context '.with_current_audience_for' do
    context 'when there is not a current organization' do
      context 'and student has no granted organizations' do
        it { expect(Avatar.with_current_audience_for(user)).to be_empty }
      end

      context 'and student has a granted organization' do
        before { user.add_permission! :teacher, grown_ups_organization; user.save! }

        it { expect(Avatar.with_current_audience_for(user)).to eq grown_ups_avatars }
      end
    end

    context 'when there is a current organization' do
      before { kindergarten_organization.switch! }

      context 'and student has no granted organizations' do
        it { expect(Avatar.with_current_audience_for(user)).to eq kindergarten_avatars }
      end

      context 'and student has a granted organization' do
        before { user.add_permission! :teacher, grown_ups_organization; user.save! }

        it { expect(Avatar.with_current_audience_for(user)).to eq kindergarten_avatars }
      end
    end
  end
end
