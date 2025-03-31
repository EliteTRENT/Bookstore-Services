FactoryBot.define do
  factory :address do
    association :user

    # Street: 5-100 chars
    street { Faker::Address.street_address.slice(0, 100) } # e.g., "742 Evergreen Terrace"

    # City: 2-50 chars, letters/spaces/hyphens only
    city { Faker::Address.city.gsub(/[^a-zA-Z\s-]/, "").slice(0, 50) } # e.g., "Springfield"

    # State: 2-50 chars, letters/spaces only
    state { Faker::Address.state.gsub(/[^a-zA-Z\s]/, "").slice(0, 50) } # e.g., "Illinois"

    # Zip code: 3-10 chars, letters/numbers/spaces/hyphens
    zip_code { Faker::Address.zip_code.slice(0, 10) } # e.g., "62701"

    # Country: 2-50 chars, letters/spaces only
    country { Faker::Address.country.gsub(/[^a-zA-Z\s]/, "").slice(0, 50) } # e.g., "United States"

    # Type: Must be "home", "work", or "other"
    type { "home" }

    is_default { false }

    # Traits for invalid cases
    trait :missing_street do
      street { "" }
    end

    trait :short_street do
      street { "123" } # Less than 5 chars
    end

    trait :invalid_city do
      city { "City123" } # Contains numbers
    end

    trait :short_city do
      city { "A" } # Less than 2 chars
    end

    trait :invalid_state do
      state { "IL123" } # Contains numbers
    end

    trait :short_state do
      state { "I" } # Less than 2 chars
    end

    trait :invalid_zip_code do
      zip_code { "ab" } # Too short
    end

    trait :invalid_country do
      country { "USA123" } # Contains numbers
    end

    trait :short_country do
      country { "U" } # Less than 2 chars
    end

    trait :invalid_type do
      type { "school" }
    end
  end
end