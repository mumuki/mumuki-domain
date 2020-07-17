require 'spec_helper'

describe WithTargetVisualIdentity do
  let!(:kids_organization) { create(:organization, target_visual_identity: :kids) }
  let!(:grown_ups_organization) { create(:organization, target_visual_identity: :grown_ups, name: 'for_grown_ups') }

  let!(:kids_avatars) { create_list(:avatar, 3, target_visual_identity: :kids) }
  let!(:grown_ups_avatars) { create_list(:avatar, 3, target_visual_identity: :grown_ups) }

  let(:user) { create(:user) }

  context '.with_current_visual_identity' do
    context 'when there is not a current organization' do
      context 'and student has no granted organizations' do
        it { expect(Avatar.with_current_visual_identity_for(user)).to be_empty }
      end
      context 'and student has no granted organizations' do
        before { user.add_permission! :teacher, grown_ups_organization; user.save! }

        it { expect(Avatar.with_current_visual_identity_for(user)).to eq grown_ups_avatars }
      end
    end

    context 'when there is a current organization' do
      before { kids_organization.switch! }

      context 'and student has no granted organizations' do
        it { expect(Avatar.with_current_visual_identity_for(user)).to eq kids_avatars }
      end
      context 'and student has no granted organizations' do
        before { user.add_permission! :teacher, grown_ups_organization; user.save! }

        it { expect(Avatar.with_current_visual_identity_for(user)).to eq kids_avatars }
      end
    end
  end
end
