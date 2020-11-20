require 'spec_helper'

describe Term, organization_workspace: :test do
  describe 'general_terms_for' do
    describe 'without terms' do
      let(:user) { create(:user) }

      it { expect(Term.profile_terms_for(user)).to eq [] }
      it { expect(Term.role_specific_terms_for(user)).to eq [] }
      it { expect(Term.general_terms).to eq [] }
      it { expect(Term.forum_related_terms).to eq [] }
      it { expect(user.has_profile_terms_to_accept?).to eq false }
      it { expect(user.has_forum_terms_to_accept?).to eq false }

      describe 'without user' do
        it { expect(Term.profile_terms_for(user)).to eq [] }
        it { expect(Term.role_specific_terms_for(user)).to eq [] }
        it { expect(Term.general_terms).to eq [] }
        it { expect(Term.forum_related_terms).to eq [] }
      end
    end

    describe 'with all terms' do
      let(:all_terms_scopes) { Term::GENERAL + Term::FORUM_RELATED + Term::ROLE_SPECIFIC }
      let!(:terms) { all_terms_scopes.map { |it| create(:term, scope: it, locale: Organization.current.locale) } }

      describe 'for user without specific roles' do
        let(:user) { create(:user) }

        describe 'when user has not accepted anything' do
          it { expect(Term.profile_terms_for(user).map(&:scope)).to contain_exactly *Term::GENERAL }
          it { expect(Term.role_specific_terms_for(user)).to eq [] }
          it { expect(Term.general_terms.map(&:scope)).to eq Term::GENERAL }
          it { expect(Term.forum_related_terms.map(&:scope)).to eq Term::FORUM_RELATED }
          it { expect(user.has_profile_terms_to_accept?).to eq true }
          it { expect(user.has_forum_terms_to_accept?).to eq true }        end

        describe 'when user has accepted all profile terms' do
          before { user.accept_profile_terms!; user.reload }

          it { expect(Term.profile_terms_for(user).map(&:scope)).to contain_exactly *Term::GENERAL }
          it { expect(Term.role_specific_terms_for(user)).to eq [] }
          it { expect(Term.general_terms.map(&:scope)).to eq Term::GENERAL }
          it { expect(Term.forum_related_terms.map(&:scope)).to eq Term::FORUM_RELATED }
          it { expect(user.has_profile_terms_to_accept?).to eq false }
          it { expect(user.has_forum_terms_to_accept?).to eq true }
        end

        describe 'when user has accepted all forum terms' do
          before { user.accept_forum_terms!; user.reload }

          it { expect(Term.profile_terms_for(user).map(&:scope)).to contain_exactly *Term::GENERAL }
          it { expect(Term.role_specific_terms_for(user)).to eq [] }
          it { expect(Term.general_terms.map(&:scope)).to eq Term::GENERAL }
          it { expect(Term.forum_related_terms.map(&:scope)).to eq Term::FORUM_RELATED }
          it { expect(user.has_profile_terms_to_accept?).to eq true }
          it { expect(user.has_forum_terms_to_accept?).to eq false }
        end

        describe 'when user has accepted all terms' do
          before do
            user.accept_profile_terms!
            user.accept_forum_terms!
            user.reload
          end

          it { expect(Term.profile_terms_for(user).map(&:scope)).to contain_exactly *Term::GENERAL }
          it { expect(Term.role_specific_terms_for(user)).to eq [] }
          it { expect(Term.general_terms.map(&:scope)).to eq Term::GENERAL }
          it { expect(Term.forum_related_terms.map(&:scope)).to eq Term::FORUM_RELATED }
          it { expect(user.has_profile_terms_to_accept?).to eq false }
          it { expect(user.has_forum_terms_to_accept?).to eq false }
        end

        describe 'when user has accepted all profile terms but some change afterwards' do
          # This is to avoid instance variable cache
          before do
            User.locate!(user.uid).accept_profile_terms!
            terms.find { |it| it.scope == 'legal' }.update! content: 'other content'
            user.reload
          end

          it { expect(Term.profile_terms_for(user).map(&:scope)).to contain_exactly *%w(privacy student legal) }
          it { expect(Term.role_specific_terms_for(user)).to eq [] }
          it { expect(Term.general_terms.map(&:scope)).to contain_exactly *%w(privacy student legal) }
          it { expect(Term.forum_related_terms.map(&:scope)).to eq Term::FORUM_RELATED }
          it { expect(user.has_profile_terms_to_accept?).to eq true }
          it { expect(user.has_forum_terms_to_accept?).to eq true }
        end

        describe 'when user is given some permissions' do
          before do
            user.add_permission! :moderator, 'test/*'
            user.save!
            user.reload
          end

          it { expect(Term.profile_terms_for(user).map(&:scope)).to contain_exactly *(Term::GENERAL + ['moderator']) }
          it { expect(Term.role_specific_terms_for(user).map(&:scope)).to eq ['moderator'] }
          it { expect(Term.general_terms.map(&:scope)).to eq Term::GENERAL }
          it { expect(Term.forum_related_terms.map(&:scope)).to eq Term::FORUM_RELATED }
          it { expect(user.has_profile_terms_to_accept?).to eq true }
          it { expect(user.has_forum_terms_to_accept?).to eq true }
        end

        describe 'without user' do

          it { expect(Term.profile_terms_for(nil).map(&:scope)).to contain_exactly *Term::GENERAL }
          it { expect(Term.role_specific_terms_for(nil).map(&:scope)).to eq [] }
          it { expect(Term.general_terms.map(&:scope)).to eq Term::GENERAL }
          it { expect(Term.forum_related_terms.map(&:scope)).to eq Term::FORUM_RELATED }
        end
      end
    end

  end

end

