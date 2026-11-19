# frozen_string_literal: true

RSpec.describe LowAuth::PasswordLinks do
  let!(:user_id) { LowAuth.users.insert(username: 'LeadDog', email: 'lead@example.com', old_hash: 'old:rye') }

  it "finds a link's user by its token, keeping only the token's SHA-256" do
    token = described_class.create(user_id:)

    expect([described_class.user(token)[:username], LowAuth.database[:password_links].get(:token_digest)])
      .to eq(['LeadDog', Digest::SHA256.hexdigest(token)])
  end

  it 'sets a new password, which logs in, and the old one no longer does' do
    token = described_class.create(user_id:)
    described_class.use(token, 'spelt starter')

    expect([LowAuth::Passwords.authenticate('LeadDog', 'spelt starter')&.fetch(:id), LowAuth::Passwords.authenticate('LeadDog', 'rye')])
      .to eq([user_id, nil])
  end

  it 'works once' do
    token = described_class.create(user_id:)
    described_class.use(token, 'spelt starter')

    expect(described_class.use(token, 'another password')).to be_nil
  end

  it 'logs the user out everywhere else' do
    LowAuth::Sessions.create(user_id:)
    described_class.use(described_class.create(user_id:), 'spelt starter')

    expect(LowAuth.database[:sessions].count).to eq(0)
  end

  it "doesn't take a password that's too short" do
    token = described_class.create(user_id:)

    expect([described_class.use(token, 'rye'), described_class.user(token)&.fetch(:id)]).to eq([nil, user_id])
  end

  it "doesn't work once it's expired" do
    token = described_class.create(user_id:)
    LowAuth.database[:password_links].update(expires_at: Time.now - 1)

    expect(described_class.user(token)).to be_nil
  end

  it 'lasts longer when asked to, like for an invite' do
    described_class.create(user_id:, hours: 7 * 24)

    expect(LowAuth.database[:password_links].get(:expires_at)).to be > Time.now + (6 * 24 * 3600)
  end

  it "replaces the user's earlier link" do
    first = described_class.create(user_id:)
    described_class.create(user_id:)

    expect(described_class.user(first)).to be_nil
  end

  it "doesn't work for a user who can't log in" do
    token = described_class.create(user_id:)
    LowAuth.users.where(id: user_id).update(blocked: true)

    expect(described_class.user(token)).to be_nil
  end

  describe '.request' do
    it 'gives the user and a token by their email, ignoring case' do
      user, token = described_class.request(' LEAD@example.com ')

      expect([user[:id], described_class.user(token)[:id]]).to eq([user_id, user_id])
    end

    it "gives nothing when there's no such user" do
      expect(described_class.request('nobody@example.com')).to be_nil
    end

    it 'gives no second link within five minutes' do
      described_class.request('LeadDog')

      expect(described_class.request('LeadDog')).to be_nil
    end
  end
end
