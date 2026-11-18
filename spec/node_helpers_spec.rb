# frozen_string_literal: true

RSpec.describe LowAuth::NodeHelpers do
  let(:node) { LowAuthSpec::SessionNode.new }
  let(:user_id) { LowAuth.users.insert(username: 'LeadDog') }

  it 'logs a user in with a session cookie' do
    node.login({ id: user_id }, event: LowAuthSpec::Event.from)
    token = node.response_headers['set-cookie'].first[/\Asession=([^;]+)/, 1]

    expect(LowAuth::Sessions.user(token)[:username]).to eq('LeadDog')
  end

  it 'logs a user out, ending their session and expiring the cookie' do
    token = LowAuth::Sessions.create(user_id:)
    node.logout(event: LowAuthSpec::Event.from(cookies: { 'session' => token }))

    expect(LowAuth::Sessions.user(token)).to be_nil
    expect(node.response_headers['set-cookie'].first).to include('Max-Age=0')
  end
end
