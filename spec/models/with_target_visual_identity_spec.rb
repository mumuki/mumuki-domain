require 'spec_helper'

describe WithTargetVisualIdentity do
  let(:kids_organization) { create(:organization, target_visual_identity: :kids) }
  let(:grown_ups_organization) { create(:organization, target_visual_identity: :grown_ups) }

  let(:kids_avatars) { create_list(:avatar, 3, target_visual_identity: :kids) }
  let(:grown_ups_avatars) { create_list(:avatar, 3, target_visual_identity: :grown_ups) }

  context '.with_current_visual_identity' do

    context 'sets scope correctly for kids' do
      before { kids_organization.switch! }

      it { expect(Avatar.with_current_visual_identity).to eq kids_avatars }
    end

    context 'sets scope correctly for kids' do
      before { grown_ups_organization.switch! }

      it { expect(Avatar.with_current_visual_identity).to eq grown_ups_avatars }
    end
  end
end
