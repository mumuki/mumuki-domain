require 'spec_helper'

describe MassiveJob do

  let(:organization) { create :organization }

  let(:creator) { create :user }

  let(:user1) { create :user }
  let(:user2) { create :user }
  let(:user3) { create :user }

  let(:massive_job) { MassiveJob.create! user: creator, total_count: uids.size, target: target }

  let(:id) { massive_job.id }

  context 'when target is a custom notification' do
    let(:target) { CustomNotification.create! title: 'Title', body_html: '<strong>Hello<Hello>', organization: organization }
    let(:uids) { [user1.uid, user2.uid, user3.uid] }

    context '#notify_creation!' do
      after { massive_job.notify_creation!(uids) }

      it { expect(Mumukit::Nuntius).to receive(:notify_job!).with('MassiveJobCreated', massive_job_id: id, uids: uids).once }
    end

    context '#notify_users_to_add' do
      after { massive_job.notify_users_to_add!(uids) }

      it { expect(Mumukit::Nuntius).to receive(:notify_job!).with('UserAddedMassiveJob', massive_job_id: id, uid: an_instance_of(String)).thrice }
    end

    context '#process!' do
      before { massive_job.process!(user1.uid) }

      context 'process uid works' do
        before { massive_job.process!(user2.uid) }

        it { expect(target.users).to contain_exactly user1, user2 }
        it { expect(target.notifications.count).to eq 2 }
        it { expect(massive_job.failed_items).to be_empty }
        it { expect(massive_job.processed_count).to eq 2 }
        it { expect(massive_job.failed_count).to eq 0 }
        it { expect(massive_job.total).to eq 2 }
        it { expect(massive_job.percentage).to eq 66 }
        it { expect(massive_job.description).to eq target.title }
      end

      context 'process uid failed' do
        before { massive_job.process!('an_uid@mumuki.org') }

        it { expect(target.users).to contain_exactly user1 }
        it { expect(target.notifications.count).to eq 1 }
        it { expect(massive_job.failed_items).not_to be_empty }
        it { expect(massive_job.failed_items.last.uid).to eq 'an_uid@mumuki.org' }
        it { expect(massive_job.failed_items.last.message).to eq "Couldn't find User with uid:  an_uid@mumuki.org" }
        it { expect(massive_job.failed_items.last.stacktrace).to be_an_instance_of String }
        it { expect(massive_job.processed_count).to eq 1 }
        it { expect(massive_job.failed_count).to eq 1 }
        it { expect(massive_job.total).to eq 2 }
        it { expect(massive_job.percentage).to eq 66 }
        it { expect(massive_job.description).to eq target.title }
      end
    end
  end
end
