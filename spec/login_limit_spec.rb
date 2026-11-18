# frozen_string_literal: true

RSpec.describe LowAuth::LoginLimit do
  before { described_class.clear('LeadDog') }

  it 'allows logins until there have been 10 failures' do
    9.times { described_class.failed('LeadDog') }
    expect(described_class.allowed?('LeadDog')).to be(true)

    described_class.failed('LeadDog')
    expect(described_class.allowed?('LeadDog')).to be(false)
  end

  it 'forgets failures after 15 minutes' do
    10.times { described_class.failed('LeadDog') }
    later = Time.now + (16 * 60)
    allow(Time).to receive(:now).and_return(later)

    expect(described_class.allowed?('LeadDog')).to be(true)
  end
end
