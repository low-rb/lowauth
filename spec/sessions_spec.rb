# frozen_string_literal: true

RSpec.describe LowAuth::Sessions do
  let(:user_id) { LowAuth.users.insert(username: 'LeadDog', role: 'admin') }

  it "finds a session's user by its token" do
    token = described_class.create(user_id:)

    expect(described_class.user(token)[:username]).to eq('LeadDog')
  end

  it 'keeps only the SHA-256 of the token' do
    token = described_class.create(user_id:)

    expect(LowAuth.database[:sessions].get(:token_digest)).to eq(Digest::SHA256.hexdigest(token))
  end

  it 'has no user once the session has expired' do
    token = described_class.create(user_id:)
    LowAuth.database[:sessions].update(expires_at: Time.now - 1)

    expect(described_class.user(token)).to be_nil
  end

  it 'has no user once the session is destroyed' do
    token = described_class.create(user_id:)
    described_class.destroy(token)

    expect(described_class.user(token)).to be_nil
  end

  it "destroys all of a user's sessions" do
    tokens = Array.new(2) { described_class.create(user_id:) }
    described_class.destroy_all(user_id:)

    expect(tokens.map { |token| described_class.user(token) }).to eq([nil, nil])
  end
end
