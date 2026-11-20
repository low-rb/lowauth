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

  describe 'allows' do
    let(:editors) { LowAuthSpec::EditorsNode }
    let(:editor_id) { LowAuth.users.insert(username: 'edna') }

    it 'lets in the users its block is true for' do
      expect(editors.get(event: event_for(editor_id)).response.body.read).to eq('editors page')
      expect(editors.get(event: event_for(member_id))).to be_nil
    end

    it 'gives the node allowed?, for a menu to ask' do
      expect(editors.allowed?(LowAuth.users.where(id: editor_id).first)).to be(true)
      expect(editors.allowed?(nil)).to be(false)
    end
  end

  describe 'allows with a role' do
    it 'is short for allows with a block that checks the role' do
      expect(node.allowed?(LowAuth.users.where(id: admin_id).first)).to be(true)
      expect(node.allowed?(LowAuth.users.where(id: member_id).first)).to be(false)
    end
  end

  describe 'with a login path' do
    around do |example|
      LowAuth.login_path = '/login'
      example.run
    ensure
      LowAuth.login_path = nil
    end

    it 'sends a logged out visitor to log in, and back after' do
      response = node.get(event: event_for(nil)).response

      expect(response.status).to eq(303)
      expect(response.headers['location']).to eq('/login?origin=%2Fadmin')
    end

    it "still doesn't let a logged in user without the role in" do
      expect(node.get(event: event_for(member_id))).to be_nil
    end

    it "doesn't send a form from a logged out visitor to log in" do
      expect(node.post(event: event_for(nil, 'origin' => 'https://example.com'))).to be_nil
    end
  end

  it 'lets any logged in user in without a role' do
    any_user = LowAuthSpec::MembersNode

    expect(any_user.get(event: event_for(member_id)).response.body.read).to eq('members page')
    expect(any_user.get(event: event_for(nil))).to be_nil
  end
end
