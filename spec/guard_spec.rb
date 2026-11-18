# frozen_string_literal: true

RSpec.describe LowAuth::Guard do
  let(:admin_id) { LowAuth.users.insert(username: 'admin', role: 'admin') }
  let(:member_id) { LowAuth.users.insert(username: 'member') }

  let(:node) { LowAuthSpec::AdminNode }

  def event_for(user_id, headers = {})
    cookies = user_id ? { 'session' => LowAuth::Sessions.create(user_id:) } : {}
    LowAuthSpec::Event.from(cookies:, headers:)
  end

  it 'lets a user with the role in' do
    expect(node.get(event: event_for(admin_id)).response.body.read).to eq('admin page')
  end

  it "doesn't let a user without the role in" do
    expect(node.get(event: event_for(member_id))).to be_nil
  end

  it "doesn't let anyone logged out in" do
    expect(node.get(event: event_for(nil))).to be_nil
  end

  it 'takes a form from this site' do
    event = event_for(admin_id, 'origin' => 'https://example.com')

    expect(node.post(event:).response.body.read).to eq('posted')
  end

  it "doesn't take a form from another site" do
    expect(node.post(event: event_for(admin_id, 'origin' => 'https://evil.example'))).to be_nil
  end

  it "doesn't take a form without an origin" do
    expect(node.post(event: event_for(admin_id))).to be_nil
  end

  it 'lets any logged in user in without a role' do
    any_user = LowAuthSpec::MembersNode

    expect(any_user.get(event: event_for(member_id)).response.body.read).to eq('members page')
    expect(any_user.get(event: event_for(nil))).to be_nil
  end
end
