FactoryBot.define do
  factory :address do
    association :user
    street { Faker::Address.street_address }  # e.g., "742 Evergreen Terrace"
    city { Faker::Address.city }             # e.g., "Springfield"
    state { Faker::Address.state_abbr }      # e.g., "IL"
    zip_code { Faker::Address.zip_code }     # e.g., "62701"
    country { Faker::Address.country.gsub(/[^a-zA-Z\s]/, "").slice(0, 50) }  # e.g., "India" (max 50 chars, only letters/spaces)
    type { "home" }
    is_default { false }

    trait :invalid_type do
      type { "school" }
    end

    trait :missing_street do
      street { "" }
    end
  end
end
