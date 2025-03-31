FactoryBot.define do
  factory :cart do
    association :user
    association :book

    # Quantity: No strict validation, but assume positive integer for realism
    quantity { Faker::Number.between(from: 1, to: 10) } # e.g., 5

    is_deleted { false }

    # Traits for edge cases
    trait :deleted do
      is_deleted { true }
    end

    trait :zero_quantity do
      quantity { 0 }
    end

    trait :negative_quantity do
      quantity { -1 }
    end

    trait :nil_quantity do
      quantity { nil }
    end
  end
end