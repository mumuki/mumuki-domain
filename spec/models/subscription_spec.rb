require 'spec_helper'

describe WithDiscussionCreation::Subscription, organization_workspace: :test do
  let(:user) { create(:user) }
  let(:subscriber) { create(:user) }
  let(:problem) { create(:indexed_exercise) }

  describe 'discussion is created' do
    let!(:discussion) { problem.discuss! user, title: 'Need help' }
    let(:subscription) { Subscription.where(user: user).first }

    it { expect(Subscription.count).to eq 1 }
    it { expect(discussion.subscription_for(user)).to eq subscription }
    it { expect(subscription.discussion).to eq discussion }
    it { expect(subscription.read).to be true }
    it { expect(user.subscribed_to? discussion).to be true }
  end

  describe 'user subscribes to another user\'s discussion' do
    let!(:discussion) { problem.discuss! user, title: 'Need help' }
    let(:subscription) { Subscription.where(user: subscriber).first }

    before { subscriber.subscribe_to! discussion }

    it { expect(discussion.subscription_for(subscriber)).to eq subscription }
    it { expect(subscription.read).to be true }

    context 'when someone posts a message' do
      before { discussion.submit_message!({content: 'Same here'}, create(:user)) }

      it { expect(discussion.subscription_for(user).read).to be false }
      it { expect(discussion.subscription_for(subscriber).read).to be false }
    end

    context 'when user unsubscribes' do
      before { subscriber.unsubscribe_to! discussion }

      it {expect(discussion.subscription_for(subscriber)).to be nil }
    end
  end

  describe 'discussions in different organizations' do
    let(:test_organization) { Organization.locate!('test') }
    let(:another_organization) { create(:organization, book: test_organization.book) }

    before do
      problem.discuss! user, title: 'Need help'
      user.subscribe_to! (problem.discuss!(create(:user), title: 'Need help'))

      another_organization.switch!
      problem.discuss! user, title: 'Need help'
      problem.discuss! user, title: 'Need help'
      user.subscribe_to! (problem.discuss!(create(:user), title: 'Need help'))
    end

    context 'in test organization' do
      before { test_organization.switch! }

      it { expect(user.subscriptions_in_organization.count).to eq 2 }
    end

    context 'in another organization' do
      before { another_organization.switch! }

      it { expect(user.subscriptions_in_organization.count).to eq 3 }
    end
  end
end
